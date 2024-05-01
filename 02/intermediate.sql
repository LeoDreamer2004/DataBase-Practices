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
