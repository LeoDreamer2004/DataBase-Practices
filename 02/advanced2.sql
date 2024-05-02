drop table if exists STC;
create table STC
(
    sno int,
    tno int,
    cno int
);

drop table if exists SC;
create table SC
(
    sno int,
    cno int
);

drop table if exists TC;
create table TC
(
    tno int,
    cno int
);

# advanced 2-1
drop table if exists tmpSTC;
create temporary table tmpSTC
(
    sno int,
    tno int,
    cno int,
    unique (sno, tno, cno)
);

drop procedure if exists insert_random_data;
create procedure insert_random_data()
begin
    declare insert_count int default 0;
    declare r_sno int;
    declare r_tno int;
    declare r_cno int;
    while insert_count < 100000
        do
            select floor(rand() * 10000), floor(rand() * 1000), floor(rand() * 100) into r_sno, r_tno, r_cno;
            if not exists (select * from tmpSTC where sno = r_sno and tno = r_tno and cno = r_cno) then
                insert into tmpSTC values (r_sno, r_tno, r_cno);
                set insert_count = insert_count + 1;
            end if;
        end while;
end;

call insert_random_data();
# check the number of records
select count(*)
from tmpSTC;


# advanced 2-2
drop trigger if exists constraint_check_1_insert;
create trigger constraint_check_1_insert
    before insert
    on STC
    for each row
begin
    if exists(select *
              from STC
                       join STC STC1 on STC.tno = STC1.tno and STC.cno <> STC1.cno)
    then
        signal sqlstate '45000'
            set message_text = 'Error: The same course cannot be taken by the same teacher.';
    end if;
end;

drop trigger if exists constraint_check_1_update;
create trigger constraint_check_1_update
    before update
    on STC
    for each row
begin
    if exists(select *
              from STC
                       join STC STC1 on STC.tno = STC1.tno and STC.cno <> STC1.cno)
    then
        signal sqlstate '45000'
            set message_text = 'Error: The same course cannot be taken by the same teacher.';
    end if;
end;

drop trigger if exists constraint_check_2_insert;
create trigger constraint_check_2_insert
    before insert
    on STC
    for each row
begin
    if exists(select *
              from STC
                       join STC STC1 on STC.sno = STC1.sno and STC.cno = STC1.cno and STC.tno <> STC1.tno)
    then
        signal sqlstate '45000'
            set message_text = 'Error: The same student cannot take the same course with different teachers.';
    end if;
end;

drop trigger if exists constraint_check_2_update;
create trigger constraint_check_2_update
    before update
    on STC
    for each row
begin
    if exists(select *
              from STC
                       join STC STC1 on STC.sno = STC1.sno and STC.cno = STC1.cno and STC.tno <> STC1.tno)
    then
        signal sqlstate '45000'
            set message_text = 'Error: The same student cannot take the same course with different teachers.';
    end if;
end;

drop trigger if exists constraint_check_3_insert;
create trigger constraint_check_3_insert
    before insert
    on TC
    for each row
begin
    if exists(select *
              from TC
                       join TC TC1 on TC.tno = TC1.tno and TC.cno <> TC1.cno)
    then
        signal sqlstate '45000'
            set message_text = 'Error: The same teacher cannot teach the same course.';
    end if;
end;

drop trigger if exists constraint_check_3_update;
create trigger constraint_check_3_update
    before update
    on TC
    for each row
begin
    if exists(select *
              from TC
                       join TC TC1 on TC.tno = TC1.tno and TC.cno <> TC1.cno)
    then
        signal sqlstate '45000'
            set message_text = 'Error: The same teacher cannot teach the same course.';
    end if;
end;

# advanced 2-3
# 把tmpSTC中数据导入到表STC以及SC和TC中，注意处理与触发器的冲突
drop procedure if exists import_data_stc;
drop procedure if exists import_data_tc;
drop procedure if exists import_data_sc;

delimiter $$
create procedure import_data_stc()
begin
    declare done int default 0;
    declare r_sno int;
    declare r_tno int;
    declare r_cno int;
    declare cur cursor for select * from tmpSTC;
    declare continue handler for not found set done = 1;

    open cur;
    read_loop: loop
        fetch cur into r_sno, r_tno, r_cno;
        if done = 1 then
            leave read_loop;
        end if;
        if not exists(select *
              from STC
                       where STC.tno = r_tno and STC.cno <> r_cno)
            and not exists(select *
              from STC
                       where STC.sno = r_sno and STC.cno = r_cno and STC.tno <> r_tno)
            and not exists(select *
              from STC
                       where STC.sno = r_sno and STC.tno = r_tno and STC.cno = r_cno)
            then
            insert into STC(sno, tno, cno) values(r_sno, r_tno, r_cno);
            insert into SC(sno, cno) values(r_sno, r_cno);
        end if;
    end loop;
    close cur;
end$$

create procedure import_data_tc()
    begin
    declare done int default 0;
    declare r_sno int;
    declare r_tno int;
    declare r_cno int;
    declare cur cursor for select * from tmpSTC;
    declare continue handler for not found set done = 1;

    open cur;
    read_loop: loop
        fetch cur into r_sno, r_tno, r_cno;
        if done = 1 then
            leave read_loop;
        end if;
        if not exists(select *
              from TC
                       where TC.tno = r_tno and TC.cno <> r_cno)
            and not exists(select *
              from TC
                       where TC.tno = r_tno and TC.cno = r_cno)
            then
            insert into TC(tno, cno) values(r_tno, r_cno);
        end if;
    end loop;
    close cur;
end$$


create procedure import_data_sc()
    begin
    declare done int default 0;
    declare r_sno int;
    declare r_tno int;
    declare r_cno int;
    declare cur cursor for select * from tmpSTC;
    declare continue handler for not found set done = 1;

    open cur;
    read_loop: loop
        fetch cur into r_sno, r_tno, r_cno;
        if done = 1 then
            leave read_loop;
        end if;
        if not exists(select *
              from SC
                       where SC.sno = r_sno and SC.cno = r_cno)
            then
            insert into SC(sno, cno) values(r_sno, r_cno);
        end if;
    end loop;
    close cur;
end$$
delimiter ;
call import_data_stc();
call import_data_tc();
call import_data_sc();

# advanced 2-4
# 查看各表所包含的行数，统计(tno, cno)的冗余，作为3NF为维护函数依赖所付出的代价
-- 查看 STC 表所包含的行数
select count(*) from STC;

-- 查看 TC 表所包含的行数
select count(*) from TC;

-- 查看 SC 表所包含的行数
select count(*) from SC;

-- 统计 (tno, cno) 的冗余
select count(*) - count(distinct tno, cno) from STC;