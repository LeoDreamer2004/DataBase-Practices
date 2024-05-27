# 创建entropy函数，计算熵
drop function if exists entropy;
create function entropy()
returns double deterministic
begin
    declare H float default 0;
    declare p float;
    declare total_count int;
    # 用于计算熵的游标
    declare cur cursor for
    select count(*)/cast(total_count as float)
    from temp_intervals
    group by class;
    declare continue handler for not found set p = null;

    select count(*) into total_count from temp_intervals;

    # 使用游标进行循环计算
    open cur;
    read_loop:
    loop
        fetch cur into p;
        if p is null then
            leave read_loop;
        end if;
        if p>0 then
        set H = H - p * log2(p);
        end if;
    end loop;
    close cur;
    return H;
end;

# 创建mutual_information函数，计算互信息
drop function if exists mutual_information;
create function mutual_information()
returns double deterministic
begin
    declare I float default 0;
    declare p_xy float;
    declare p_x float;
    declare p_y float;
    declare total_count int;
    # 用于计算互信息的游标
    declare cur cursor for
    select count_xy/cast(total_count as float), count_x/cast(total_count as float), count_y/cast(total_count as float)
    from (
        select count(*) as count_xy,
        (select count(*) from temp_intervals_x where class = x.class) as count_x,
        (select count(*) from temp_intervals_y where class = y.class) as count_y
        from temp_intervals_x x
        join temp_intervals_y y on x.id = y.id
        group by x.class,y.class) as joint;
    declare continue handler for not found set p_xy = null;

    select count(*) into total_count from temp_intervals_x;

    # 使用游标进行循环计算
    open cur;
    read_loop: loop
        fetch cur into p_xy,p_x,p_y;
                if p_xy is null then
            leave read_loop;
        end if;

        if p_x*p_y>0 then
            set I = I + (p_xy * log2(p_xy / (p_x * p_y)));
        end if;
    end loop;
    close cur;
    return I;

end;

# 创建临时表temp_intervals，将happiness_score列的值分为40个区间
drop table if exists temp_intervals;
create temporary table temp_intervals(
    value float,
    class int
);

insert into temp_intervals (value, class)
select happiness_score as value,
       ceiling((happiness_score - min_val) / interval_width) as class
from happiness,
     (select min(happiness_score) as min_val,max(happiness_score) as max_val from happiness) as min_max,
    (select (max(happiness_score) - min(happiness_score)) / 40 as interval_width from happiness) as interval_width;

# 计算happiness_score列的熵
select entropy() as entropy_happiness_score;

# 创建临时表temp_intervals，将economy列的值分为40个区间
drop table if exists temp_intervals;
create temporary table temp_intervals(
    value float,
    class int
);

insert into temp_intervals (value, class)
select economy as value,
       ceiling((economy - min_val) / interval_width) as class
from happiness,
     (select min(economy) as min_val,max(economy) as max_val from happiness) as min_max,
    (select (max(economy) - min(economy)) / 40 as interval_width from happiness) as interval_width;

# 计算economy列的熵
select entropy() as entropy_economy;

# 创建临时表temp_intervals，将health列的值分为40个区间
drop table if exists temp_intervals;
create temporary table temp_intervals(
    value float,
    class int
);

insert into temp_intervals (value, class)
select health as value,
       ceiling((health - min_val) / interval_width) as class
from happiness,
     (select min(health) as min_val,max(health) as max_val from happiness) as min_max,
    (select (max(health) - min(health)) / 40 as interval_width from happiness) as interval_width;

# 计算health列的熵
select entropy() as entropy_health;

# 创建表temp_intervals_x，将happiness_score列的值分为40个区间
drop table if exists temp_intervals_x;
create table temp_intervals_x(
    id int,
    value float,
    class int
);

insert into temp_intervals_x (id, value, class)
select happiness_rank as id,
    economy as value,
    ceiling((happiness_score - min_val) / interval_width) as class
from happiness,
     (select min(happiness_score) as min_val,max(happiness_score) as max_val from happiness) as min_max,
    (select (max(happiness_score) - min(happiness_score)) / 40 as interval_width from happiness) as interval_width;

# 创建表temp_intervals_y，将economy列的值分为40个区间
drop table if exists temp_intervals_y;
create table temp_intervals_y(
    id int,
    value float,
    class int
);

insert into temp_intervals_y (id, value, class)
select happiness_rank as id,
    economy as value,
    ceiling((economy - min_val) / interval_width) as class
from happiness,
     (select min(economy) as min_val,max(economy) as max_val from happiness) as min_max,
    (select (max(economy) - min(economy)) / 40 as interval_width from happiness) as interval_width;


# 计算economy列和happiness_score列的互信息
select mutual_information() as mutual_information_economy_happiness;

# 创建表temp_intervals_y，将health列的值分为40个区间
drop table if exists temp_intervals_y;
create table temp_intervals_y(
    id int,
    value float,
    class int
);

insert into temp_intervals_y (id, value, class)
select happiness_rank as id,
    health as value,
    ceiling((health - min_val) / interval_width) as class
from happiness,
     (select min(health) as min_val,max(health) as max_val from happiness) as min_max,
    (select (max(health) - min(health)) / 40 as interval_width from happiness) as interval_width;


# 计算health列和happiness_score列的互信息
select mutual_information() as mutual_information_health_happiness;

# 删除临时创建的表
drop table if exists temp_intervals_x;
drop table if exists temp_intervals_y;