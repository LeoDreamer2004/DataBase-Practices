# advanced 1-1
drop trigger if exists set_level_before_insert;
create trigger set_level_before_insert
    before insert
    on emp
    for each row
begin
    if new.salary between 0 and 5000 then
        set new.level = '1';
    elseif new.salary between 5001 and 10000 then
        set new.level = '2';
    elseif new.salary between 10001 and 15000 then
        set new.level = '3';
    elseif new.salary between 15001 and 20000 then
        set new.level = '4';
    else
        set new.level = '5';
    end if;
end;

drop trigger if exists set_level_before_update;
create trigger set_level_before_update
    before update
    on emp
    for each row
begin
    if new.salary between 0 and 5000 then
        set new.level = '1';
    elseif new.salary between 5001 and 10000 then
        set new.level = '2';
    elseif new.salary between 10001 and 15000 then
        set new.level = '3';
    elseif new.salary between 15001 and 20000 then
        set new.level = '4';
    else
        set new.level = '5';
    end if;
end;


# advanced 1-2
drop trigger if exists check_manager_salary_before_insert_dept;
create trigger check_manager_salary_before_insert_dept
    before insert
    on dept
    for each row
begin
    declare manager_salary int;
    select salary into manager_salary from emp where eno = new.manager limit 1;
    if exists (select * from emp where dno = new.dno and eno <> new.manager and salary > manager_salary) then
        signal sqlstate '45000' set message_text = '员工薪水不能高于经理';
    end if;
end;

drop trigger if exists check_manager_salary_before_update_dept;
create trigger check_manager_salary_before_update_dept
    before update
    on dept
    for each row
begin
    declare manager_salary int;
    select salary into manager_salary from emp where eno = new.manager limit 1;
    if exists (select * from emp where dno = new.dno and eno <> new.manager and salary > manager_salary) then
        signal sqlstate '45000' set message_text = '员工薪水不能高于经理';
    end if;
end;

drop trigger if exists check_manager_salary_before_insert_emp;
create trigger check_manager_salary_before_insert_emp
    before insert
    on emp
    for each row
begin
    declare manager_salary int;
    declare manager_eno int;
    select salary, eno
    into manager_salary, manager_eno
    from emp
             join dept on emp.dno = dept.dno
    where dept.dno = new.dno
      and dept.manager = emp.eno;
    if manager_eno <> new.eno and new.salary > manager_salary then
        signal sqlstate '45000' set message_text = '员工薪水不能高于经理';
    end if;
end;

drop trigger if exists check_manager_salary_before_update_emp;
create trigger check_manager_salary_before_update_emp
    before update
    on emp
    for each row
begin
    declare manager_salary int;
    declare manager_eno int;
    select salary, eno
    into manager_salary, manager_eno
    from emp
             join dept on emp.dno = dept.dno
    where dept.dno = new.dno
      and dept.manager = emp.eno;
    if manager_eno <> new.eno and new.salary > manager_salary then
        signal sqlstate '45000' set message_text = '员工薪水不能高于经理';
    end if;
end;

# test trigger
# NOTE: this should not be executed and will cause an error
insert into emp(ename, birthday, level, position, salary, dno)
values ('test', '1999-01-01', 5, '教务', 100000, 1);


# advanced 1-3
drop trigger if exists set_budget_before_insert_emp;
create trigger set_budget_before_insert_emp
    before insert
    on emp
    for each row
begin
    update dept
    set budget = budget + new.salary
    where dno = new.dno;
end;

drop trigger if exists set_budget_before_update_emp;
create trigger set_budget_before_update_emp
    before update
    on emp
    for each row
begin
    update dept
    set budget = budget - old.salary
    where dno = old.dno;
    update dept
    set budget = budget + new.salary
    where dno = new.dno;
end;

drop trigger if exists set_budget_before_delete_emp;
create trigger if not exists set_budget_before_delete_emp
    before delete
    on emp
    for each row
begin
    update dept
    set budget = budget - old.salary
    where dno = old.dno;
end;

# test trigger
insert into emp(ename, birthday, level, position, salary, dno)
values ('test', '1999-01-01', 5, '教务', 10000, 1);
update emp
set salary = 20000
where eno = 1;