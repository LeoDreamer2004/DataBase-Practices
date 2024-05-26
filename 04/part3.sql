create table movies
(
    movieId int primary key not null,
    title   varchar(255)    not null
);

create table ratings
(
    userId    int   not null,
    movieId   int   not null,
    rating    float not null,
    timestamp int   not null
);

# 在预处理阶段将类型拆分成多行，并存入 genres 表中
create table genres
(
    movieId int          not null,
    genre   varchar(255) not null
);

# ... 从CSV添加数据，略

#########################
# P1: 平均得分最高的电影
########################
select movieId
from ratings
group by movieId
order by avg(rating) desc
limit 1;

#########################
# P2：每个类型中平均得分最高的电影
########################

with movie_avg_rating as (select genre, movieId, avg(rating) as avg_rating
                          from ratings
                                   join genres using (movieId)
                          group by genre, movieId
                          order by genre, avg_rating desc),

     max_rating as (select genre, max(avg_rating) as avg_rating
                    from movie_avg_rating
                    group by genre)

# 查询结果，之所以会出现多个是因为有并列的
select genre, movieId, avg_rating
from movie_avg_rating
         join max_rating
              using (genre, avg_rating);


#########################
# P3：评分两极化的电影（前10%评价分减后10%评价分）最大的电影
#########################

# 滑动窗口
with avg_top_10_percent as (select movieId, avg(rating) as avg_top
                            from (select movieId,
                                         rating,
                                         ntile(10) over (partition by movieId order by rating desc ) as rating_percentile
                                  from ratings) as t
                            where rating_percentile = 1
                            group by movieId),

     avg_bottom_10_percent as (select movieId
                                    , avg(rating) as avg_bottom
                               from (select movieId
                                          , rating
                                          , ntile(10) over (partition by movieId order by rating desc ) as rating_percentile
                                     from ratings) as t
                               where rating_percentile = 10
                               group by movieId)
# 计算分差，四列分别表示：电影ID、分差、前10%评分、后10%评分
select movieId, avg_top - avg_bottom as diff, avg_top, avg_bottom
from avg_top_10_percent
         join avg_bottom_10_percent using (movieId)
order by diff desc;


#########################
# P4：用户兴趣分析：每个用户综合评价最高的电影类型，观影次数最多的电影类型
#########################

# 用户综合评价最高的电影类型
create temporary table user_interest_by_rating as
    (with user_avg_rating as (select userId, genre, avg(rating) as avg_rating
                              from ratings
                                       join genres using (movieId)
                              group by userId, genre
                              order by userId, avg_rating desc),

          max_rating as (select userId, max(avg_rating) as avg_rating
                         from user_avg_rating
                         group by userId)
     select userId, genre, avg_rating
     from user_avg_rating
              join max_rating
                   using (userId, avg_rating));
select *
from user_interest_by_rating;

# 观影次数最多的电影类型
create temporary table user_interest_by_count as
    (with user_movie_count as (select userId, genre, count(*) as movie_count
                               from ratings
                                        join genres using (movieId)
                               group by userId, genre
                               order by userId, movie_count desc),

          max_count as (select userId, max(movie_count) as movie_count
                        from user_movie_count
                        group by userId)

     select userId, genre, movie_count
     from user_movie_count
              join max_count
                   using (userId, movie_count));
select *
from user_interest_by_count;

#########################
# P5：用户兴趣关联图：两个用户观看了同一部电影并且评价相差不超过1，则他们之间的亲密度加1
#########################

# 两个用户观看了同一部电影并且评价相差不超过1
drop temporary table if exists user_movie_rating;
create temporary table user_movie_rating as
    (select userId, movieId, rating
     from ratings
     order by userId, movieId);

# 用户关系视图
drop table if exists user_user_relation;
create temporary table user_user_relation as
    (select a.userId as user1, b.userId as user2, count(*) as relation
     from user_movie_rating a
              join user_movie_rating b using (movieId)
     where a.userId < b.userId
       and abs(a.rating - b.rating) <= 1
     group by a.userId, b.userId);

select *
from user_user_relation;

#########################
# P6：结合4,5，找出亲密度最高的前10个用户对(a,b)，如果如果a观看了某部电影m，而b没有观看m，并且m属于b的观影兴趣范围，则向b推荐电影m
#########################

# 亲密度最高的前10个用户对
with most_related_users as (select user1, user2, relation
                            from user_user_relation
                            order by relation desc
                            limit 10)

# a观看了某部电影m，而b没有观看m，并且m属于b的观影兴趣范围（这里选取类型评分最高）
# 这里user1指用户a，user2指用户b，movieId指推荐的电影
select user1, user2, a.movieId
from most_related_users
         join user_movie_rating a on user1 = a.userId
         join genres on a.movieId = genres.movieId
where a.movieId not in (select movieId
                        from user_movie_rating
                        where userId = user2)
  and genre in (select genre from user_interest_by_rating where userId = user2);