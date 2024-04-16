-- active: 1712568895901@@127.0.0.1@3306@practice2
drop table if exists emp;

drop table if exists dept;

create table
    emp (
        -- TODO: Basic-1 Constraint for eno in 4 digits, like 0001, 0002, ...
        eno int primary key auto_increment,
        ename varchar(20),
        birthday date,
        level int between 1 and 5 default 3,
        -- Basic-5
        position varchar(20) enum("教师","教务","会计","秘书"),
        salary int between 2000 and 200000,
        dno int,
        -- Basic-2
        foreign key (dno) references dept (dno) 
    );

create table
    dept (
        dno int primary key,
        -- Basic-4
        dname varchar(20) enum ("数学学院", "计算机学院", "智能学院", "电子学院", "元培学院"),
        budget int,
        manager int
    );