# intermediate 1
set foreign_key_checks = 0;
insert into emp(ename, birthday, level, position, salary, dno)
values ('张三', '1990-01-01', 1, '教务', 10000, 1);
insert into dept(dname, budget, manager)
values ('数学学院', 100000, 1);
set foreign_key_checks = 1;

