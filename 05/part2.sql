# 创建表和索引
drop table if exists sessions;
create table sessions (
    keycol int not null auto_increment,
    app varchar(10) not null,
    usr varchar(10) not null,
    host varchar(10) not null,
    starttime datetime not null,
    endtime datetime not null,
    primary key (keycol),
    check (endtime > starttime)
);

create index idx_app_starttime on sessions(app, starttime);
create index idx_app_endtime on sessions(app, endtime);

# 生成随机数据
drop procedure if exists insert_random_sessions;
create procedure insert_random_sessions(in num_rows int)
begin
    declare i int default 0;
    declare app varchar(10);
    declare usr varchar(10);
    declare host varchar(10);
    declare starttime datetime;
    declare endtime datetime;
    while i < num_rows
        do
        set app = floor(rand() * 1000);
        set usr = floor(rand() * 1000);
        set host = floor(rand() * 1000);
        set starttime = now() - interval floor(rand() * 10000) second;
        set endtime = starttime + interval (1+floor(rand() * 10000)) second;
        insert into sessions(app, usr, host, starttime, endtime) values (app, usr, host, starttime, endtime);
        set i = i + 1;
    end while;
end;

call insert_random_sessions(100000);

# 基于集合的查询
with time_points as (
    select app, starttime as ts from Sessions
    union
    select app, endtime from Sessions
),
# 某一时刻的并发数
counts as (
    select app, ts,
        (select count(*)
         from Sessions as S
         where P.app = S.app
           and P.ts >= S.starttime
           and P.ts < S.endtime) AS concurrent
    FROM time_points AS P
)
select app, max(concurrent) as mx
from counts
group by app
order by mx desc;

# 基于游标的查询
drop procedure if exists max_concurrent_sessions;
create procedure max_concurrent_sessions()
begin
    declare done int default 0;
    declare app1 varchar(10);
    declare ts datetime;
    declare type int;
    declare concurrent int default 0;
    declare mx int default 0;
    declare prev_app varchar(10);

    # 使用游标逐行搜索
    declare cur cursor for
        select app , starttime as ts, 1 as type from Sessions
        union all
        select app, endtime, -1 from Sessions
        order by app, ts, type;

    declare continue handler for not found set done = 1;

    drop temporary table if exists AppsMx;
    create temporary table AppsMx (app varchar(10), mx int not null);

    open cur;
    read_loop:loop
        fetch cur into app1, ts, type;
        if done then
            leave read_loop;
        end if;
        if prev_app is null or prev_app <> app1 then
            if prev_app is not null then
                insert into AppsMx(app, mx) values (prev_app, mx);
            end if;
            set concurrent = 0;
            set mx = 0;
            set prev_app = app1;
        end if;
        set concurrent = concurrent + type;
        if concurrent > mx then
            set mx = concurrent;
        end if;
    end loop;
    close cur;

    if prev_app is not null then
        insert into AppsMx(app, mx) values (prev_app, mx);
    end if;

    select * from AppsMx
    order by mx desc;
end;

call max_concurrent_sessions();

# 基于窗口的查询
with C1 as (
  select app, starttime as ts, +1 as type
  from Sessions

  union all

  select app, endtime, -1
  from Sessions
),
C2 as
(
  select *,
    sum(type) over(partition by app order by ts, type
                   rows between unbounded preceding and current row) as cnt
  from C1
)
select app, max(cnt) as mx
from C2
group by app
order by mx desc;

