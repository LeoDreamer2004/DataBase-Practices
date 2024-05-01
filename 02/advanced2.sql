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
                insert into tmpSTC values (sno, tno, cno);
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