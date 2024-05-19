----------------------------------------
-------------- problem 1 ---------------
----------------------------------------
drop table if exists yttlj;
create table yttlj
(
    phaseId   int,
    phaseText text
);

----------------------------------------
-------------- problem 2 ---------------
----------------------------------------
drop table if exists person;
create table person
(
    personId   int,
    personName text
);

----------------------------------------
-------------- problem 3 ---------------
----------------------------------------

-- insert data
copy yttlj from '/var/lib/postgresql/yttlj.csv' delimiter ',' csv header;
copy person from '/var/lib/postgresql/Person.csv' delimiter ',' csv header;

-- create table for coCurrent
drop table if exists coCurrent;
create table coCurrent
(
    personId1 int,
    personId2 int,
    counts    int
);

-- get bit string for each person
create or replace function getBitString(pName text) returns bit(45) as
$$
declare
    bitString bit(45) := repeat('0', 45)::bit(45);
    idx       int     := 0;
begin
    for idx in 0..44
        loop
            if exists (select 1 from yttlj where phaseId = idx and phaseText like '%' || pName || '%') then
                bitString := bitString | (1::bit(45) << idx);
            end if;
        end loop;
    return bitString;
end;
$$ language plpgsql;

alter table person
    add column phaseContains bit(45);
-- update person
update person
set phaseContains = getBitString(personName)
where true;

-- create function to count bits
create or replace function bitCount(bitString bit(45)) returns int as
$$
declare
    count int := 0;
    idx   int;
begin
    for idx in 0..44
        loop
            if (bitString & (1::bit(45) << idx)) <> 0::bit(45) then
                count := count + 1;
            end if;
        end loop;
    return count;
end;
$$ language plpgsql;

-- update coCurrent
insert into coCurrent
select p1.personId, p2.personId, bitCount(p1.phaseContains & p2.phaseContains)
from person p1
         join person p2 on p1.personId < p2.personId;


----------------------------------------
-------------- problem 4 ---------------
----------------------------------------
