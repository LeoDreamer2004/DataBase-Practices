# intermediate 1
set foreign_key_checks = 0;
insert into emp(ename, birthday, level, position, salary, dno)
values ('张三', '1990-01-01', 2, '教务', 10000, 1);
insert into dept(dname, budget, manager)
values ('数学学院', 100000, 1);
set foreign_key_checks = 1;


# intermediate 2
alter table emp
    add constraint check_salary check ((level = 1 and salary between 0 and 5000) or
                                       (level = 2 and salary between 5001 and 10000) or
                                       (level = 3 and salary between 10001 and 15000) or
                                       (level = 4 and salary between 15001 and 20000) or
                                       (level = 5 and salary > 20000));


# intermediate 3
drop function if exists get_smart_code;
create function get_smart_code(eno int) returns char(20)
    reads sql data
begin
    declare smart_code char(20);
    declare eno_s int(4) zerofill;
    declare dno_s int(4) zerofill;
    declare birthday_s date;
    declare level_s int(2);
    declare position_s enum ('教师', '教务', '会计', '秘书');
    declare manager_s int(4) zerofill;
    declare position_code char(2);
    select emp.eno, dno, birthday, level, position
    into eno_s,dno_s,birthday_s,level_s,position_s
    from emp
    where emp.eno = eno;
    select manager into manager_s from dept where dept.dno = dno_s;
    if position_s = '教师' then
        set position_code = '01';
    elseif position_s = '教务' then
        set position_code = '02';
    elseif position_s = '会计' then
        set position_code = '03';
    else
        set position_code = '04';
    end if;
    set smart_code = concat(eno_s, dno_s, year(birthday_s), level_s, position_code, manager_s);
    return smart_code;
end;

# test the function
select get_smart_code(0001);