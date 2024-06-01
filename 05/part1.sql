drop table if exists testIndex;
create table testIndex(
    id int primary key auto_increment,
    A int,
    B int,
    C varchar(255)
);

drop procedure if exists insert_random_data;
create procedure insert_random_data(in num_rows int)
begin
    declare i int default 0;
    while i < num_rows
        do
        insert into testIndex(A, B, C) values (floor(rand() * 1000), floor(rand() * 1000), md5(rand()));
        set i = i + 1;
    end while;
end;

call insert_random_data(100000);

# 观察在A列上建立索引前后的性能差异
# 369ms
select A, count(*)
from testIndex
group by A
order by A;

create index idx_A on testIndex(A);

# 274ms
select A, count(*)
from testIndex
group by A
order by A;

# 针对 select B where A 类型的查询，观察基于(A, B)的组合索引相对于A上的单列索引的性能提升
# 474ms
select B
from testIndex
where A = 100;

create index idx_AB on testIndex(A, B);

#79ms
select B
from testIndex
where A = 100;

# 观察C列上函数索引的作用
#323ms
select * from testIndex where substring(C, 2, 3) = 'ABC';
#284ms
select * from testIndex where substring(C, 2, 2) = 'AB';

#目前版本的MySQL不支持函数索引，因此我们需要手动维护一个列来存储substring(C, 2, 3)的值
#create index func_idx_C on testIndex(substring(C, 2, 3));
alter table testIndex
add column C_substr varchar(255) generated always as (substring(C, 2, 3)) stored;

create index idx_C_substr on testIndex(C_substr);

# 82ms
select * from testIndex where C_substr = 'ABC';
# 290ms
select * from testIndex where substring(C_substr, 1, 2) ='AB';