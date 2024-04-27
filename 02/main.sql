-- active: 1712568895901@@127.0.0.1@3306@practice2
drop table if exists emp;

drop table if exists dept;

create table
    dept (
        dno int (4) zerofill not null auto_increment primary key,
        -- basic-4
        dname enum ("数学学院", "计算机学院", "智能学院", "电子学院", "元培学院"),
        budget int,
        manager int (4) zerofill
    );

create table
    emp (
        -- basic-1
        eno int (4) zerofill not null auto_increment primary key,
        ename varchar(20),
        birthday date,
        -- basic-6
        level int default 3 check (
            level >= 1
            and level <= 5
        ),
        -- basic-5
        position enum ('教师', '教务', '会计', '秘书'),
        salary int check (
            salary >= 2000
            and salary <= 200000
        ),
        dno int (4) zerofill
    );

-- basic-2~3
alter table emp add foreign key (dno) references dept (dno),
alter table dept add foreign key (manager) references emp (eno);