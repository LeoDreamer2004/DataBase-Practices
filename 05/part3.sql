# prepare data
drop table if exists t1;
create table t1
(
    a int,
    b int
);

drop procedure if exists insert_t1_random;
create procedure insert_t1_random(max_num int)
begin
    declare i int default 0;
    declare r_a int;
    declare r_b int;
    while i < max_num
        do
            set r_a = floor(rand() * 1000);
            set r_b = floor(rand() * 1000);
            insert into t1 values (r_a, r_b);
            set i = i + 1;
        end while;
end;


call insert_t1_random(10000);

create index idx_t1_a on t1 (a);
create index idx_t1_b on t1 (b);

drop table if exists t2;
create table t2
(
    a int,
    b int
);

drop procedure if exists insert_t2_random;
create procedure insert_t2_random(max_num int)
begin
    declare i int default 0;
    declare r_a int;
    declare r_b int;
    while i < max_num
        do
            set r_a = floor(rand() * 1000);
            set r_b = floor(rand() * 1000);
            insert into t2 values (r_a, r_b);
            set i = i + 1;
        end while;
end;

call insert_t2_random(50000);

create index idx_t2_a on t2 (a);
create index idx_t2_b on t2 (b);

##############################
#### Test for INDEX_MERGE ####
##############################

# without hint (64 ms)
select *
from t1
where a > 500
  and b > 500;

explain
select *
from t1
where a > 500
  and b > 500;

# with hint (46 ms)
select /*+ INDEX_MERGE(t1 idx_t1_a, idx_t1_b)*/ *
from t1
where a > 500
  and b > 500;

explain
select /*+ INDEX_MERGE(t1 idx_t1_a, idx_t1_b)*/ *
from t1
where a > 500
  and b > 500;


##############################
#### Test for JOIN_ORDER #####
##############################

truncate t1;

call insert_t1_random(20000);

# without hint (1 s 931 ms)
select *
from t1
         join t2 on t1.a = t2.a
    and t1.b = t2.b;


explain
select *
from t1
         join t2 on t1.a = t2.a
    and t1.b = t2.b;

# with hint (1 s 107 ms)
select /*+ JOIN_ORDER(t1, t2) */ *
from t1
         join t2 on t1.a = t2.a
    and t1.b = t2.b;

explain
select /*+ JOIN_ORDER(t1, t2) */ *
from t1
         join t2 on t1.a = t2.a
    and t1.b = t2.b;


##############################
#### Test for HASH_JOIN ######
##############################
drop table if exists t3;
drop table if exists t4;

create table t3
(
    a int
);

create table t4
(
    a int
);

drop procedure if exists insert_t3_random;
create procedure insert_t3_random(max_num int)
begin
    declare i int default 0;
    declare r_a int;
    while i < max_num
        do
            set r_a = floor(rand() * 5000);
            insert into t3 values (r_a);
            set i = i + 1;
        end while;
end;

call insert_t3_random(100);

drop procedure if exists insert_t4_random;
create procedure insert_t4_random(max_num int)
begin
    declare i int default 0;
    declare r_a int;
    while i < max_num
        do
            set r_a = floor(rand() * 5000);
            insert into t4 values (r_a);
            set i = i + 1;
        end while;
end;

call insert_t4_random(1000);


# without hint (97 ms)
select *
from t3
         join t4 on t3.a = t4.a;

explain
select *
from t3
         join t4 on t3.a = t4.a;

# with hint (58 ms)
select /*+ HASH_JOIN(t3, t4) */ *
from t3
         join t4 on t3.a = t4.a;

explain
select /*+ HASH_JOIN(t3, t4) */ *
from t3
         join t4 on t3.a = t4.a;
