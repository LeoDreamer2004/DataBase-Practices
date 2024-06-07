# 建表和插入数据
drop table if exists bank_user;
drop table if exists bank_trans;
create table bank_user
(
    id         int,
    name       char(2),
    amt_sold   int,
    amt_bought int
);
create table bank_trans
(
    trans_id  int auto_increment primary key,
    seller_id int,
    buyer_id  int,
    amount    int,
    processed int default 0 # 用于方案三
);

create procedure clear_data()
begin
    truncate table bank_user;
    truncate table bank_trans;
    insert into bank_user
    values (1, 'A', 1000000, 1000000),
           (2, 'B', 1000000, 1000000),
           (3, 'C', 1000000, 1000000),
           (4, 'D', 1000000, 1000000),
           (5, 'E', 1000000, 1000000),
           (6, 'F', 1000000, 1000000),
           (7, 'G', 1000000, 1000000),
           (8, 'H', 1000000, 1000000),
           (9, 'I', 1000000, 1000000),
           (10, 'J', 1000000, 1000000);
end;

set transaction isolation level read committed;
set autocommit = 0; # 防止自动提交

call clear_data();

delimiter //

############################################################
# 方案一：对 bank_trans 和 bank_user 表的修改放在同一个事务中
############################################################

drop procedure if exists transaction_1;
create procedure transaction_1(in benchmark int)
begin
    declare i int default 0;
    declare seller_id int;
    declare buyer_id int;
    declare amount int;

    while i < benchmark
        do
            set seller_id = floor(rand() * 10) + 1;
            set buyer_id = floor(rand() * 10) + 1;
            set amount = floor(rand() * 1000);
            start transaction;
            insert into bank_trans (seller_id, buyer_id, amount)
            values (seller_id, buyer_id, amount);
            update bank_user
            set amt_sold = amt_sold + amount
            where id = seller_id;
            update bank_user
            set amt_bought = amt_bought + amount
            where id = buyer_id;
            commit;
            set i = i + 1;
        end while;
end //

call transaction_1(10000);
select *
from bank_user;
call clear_data();

############################################################
# 方案二：对 bank_trans 和 bank_user 表的修改放在两个事务中。
############################################################

drop procedure if exists transaction_2;
create procedure transaction_2(in benchmark int)
begin
    declare i int default 0;
    declare seller_id int;
    declare buyer_id int;
    declare amount int;

    while i < benchmark
        do
            set seller_id = floor(rand() * 10) + 1;
            set buyer_id = floor(rand() * 10) + 1;
            set amount = floor(rand() * 1000);

            start transaction;
            insert into bank_trans (seller_id, buyer_id, amount)
            values (seller_id, buyer_id, amount);
            commit;

            start transaction;
            update bank_user
            set amt_sold = amt_sold + amount
            where id = seller_id;
            update bank_user
            set amt_bought = amt_bought + amount
            where id = buyer_id;
            commit;
            set i = i + 1;
        end while;
end //

call transaction_2(10000);
select *
from bank_user;
call clear_data();

############################################################
# 方案三：对 bank_user 表的修改封装为消息。
# 把事务内容批量更新到 bank_user 表中。为此，可以为 bank_trans 表附加一个 processed列。
# 初始事务插入这个表时，processed 列设为 0，一个事务条目一旦被定期更新过了，就把 processed 列设为 1
# 这样下次定期更新的时候就只更新 processed 为 0 的记录
############################################################
drop procedure if exists transaction_3;
create procedure transaction_3(in benchmark int)
begin
    declare i int default 0;
    declare seller_id int;
    declare buyer_id int;
    declare amount int;
    while i < benchmark
        do
            set seller_id = floor(rand() * 10) + 1;
            set buyer_id = floor(rand() * 10) + 1;
            set amount = floor(rand() * 1000);
            start transaction;
            insert into bank_trans (seller_id, buyer_id, amount)
            values (seller_id, buyer_id, amount);
            commit;
            set i = i + 1;
            # 定期更新
            if i % 100 = 0
            then
                start transaction;
                update bank_user
                set amt_sold = amt_sold + (select coalesce(sum(amount), 0)
                                           from bank_trans
                                           where seller_id = id
                                             and processed = 0);
                update bank_user
                set amt_bought = amt_bought + (select coalesce(sum(amount), 0)
                                               from bank_trans
                                               where buyer_id = id
                                                 and processed = 0);
                update bank_trans
                set processed = 1
                where processed = 0;
                commit;
            end if;
        end while;
end //

call transaction_3(10000);
select *
from bank_user;
call clear_data();
