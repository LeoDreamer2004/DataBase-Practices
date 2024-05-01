# advanced-1
delimiter //
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
//
delimiter ;

# advanced-1
delimiter //
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
//
delimiter ;

