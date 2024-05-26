drop table if exists buycomputer;
create table buycomputer(age int, income char(10), student char(5), credit_rating char(15), buys_computer char(5));
insert into buycomputer values
    (30,'high','no','fair','no'),(30,'high','no','excellent','no'),(40,'high','no','fair','yes'),
    (50,'medium','no','fair','yes'),(50,'low','yes','fair','yes'),(50,'low','yes','excellent','no'),
    (40,'low','yes','excellent','yes'),(30,'medium','no','fair','no'),(30,'low','yes','fair','yes'),
    (50,'medium','yes','fair','yes'),(30,'medium','yes','excellent','yes'),(40,'medium','no','excellent','yes'),
    (40,'high','yes','fair','yes'),(50,'medium','no','excellent','no');

# 计算先验概率
drop table if exists prior_probability;
create temporary table prior_probability as
select buys_computer, count(*)/cast((select count(*) from buycomputer) as float) as prior
from buycomputer
group by buys_computer;

# 计算age_group的条件概率
drop table if exists age_group_probability;
create temporary table age_group_probability as
select buys_computer,
       case
           when age <= 30 then '<=30'
           when age > 30 and age <= 40 then '31-40'
           else '>40'
       end as age_group,
       count(*) / (select count(*) from buycomputer where buys_computer = bc.buys_computer) as prob
from buycomputer bc
group by buys_computer, age_group;

# 计算income的条件概率
drop table if exists income_probability;
create temporary table income_probability as
select buys_computer,
       income,
       count(*) / (select count(*) from buycomputer where buys_computer = bc.buys_computer) as prob
from buycomputer bc
group by buys_computer, income;

# 计算student的条件概率
drop table if exists student_probability;
create temporary table student_probability as
select buys_computer,
       student,
       count(*) / (select count(*) from buycomputer where buys_computer = bc.buys_computer) as prob
from buycomputer bc
group by buys_computer, student;

# 计算credit_rating的条件概率
drop table if exists credit_rating_probability;
create temporary table credit_rating_probability as
select buys_computer,
       credit_rating,
       count(*) / (select count(*) from buycomputer where buys_computer = bc.buys_computer) as prob
from buycomputer bc
group by buys_computer, credit_rating;

# 创建贝叶斯预测函数
drop function if exists predict;
create function predict(p_age_group char(10), p_income char(10), p_student char(5), p_credit_rating char(15))
returns char(5) deterministic
begin
    declare p_yes float;
    declare p_no float;
    declare result char(5);

    declare prob_age_yes float;
    declare prob_income_yes float;
    declare prob_student_yes float;
    declare prob_credit_yes float;

    declare prob_age_no float;
    declare prob_income_no float;
    declare prob_student_no float;
    declare prob_credit_no float;

    # 获取先验概率
    select prior into p_yes from prior_probability where buys_computer = 'yes';
    select prior into p_no from prior_probability where buys_computer = 'no';

    # 计算条件概率 P(X|yes)
    select prob into prob_age_yes from age_group_probability where buys_computer = 'yes' and age_group = p_age_group;
    select prob into prob_income_yes from income_probability where buys_computer = 'yes' and income = p_income;
    select prob into prob_student_yes from student_probability where buys_computer = 'yes' and student = p_student;
    select prob into prob_credit_yes from credit_rating_probability where buys_computer = 'yes' and credit_rating = p_credit_rating;

    # 计算条件概率 P(X|no)
    select prob into prob_age_no from age_group_probability where buys_computer = 'no' and age_group = p_age_group;
    select prob into prob_income_no from income_probability where buys_computer = 'no' and income = p_income;
    select prob into prob_student_no from student_probability where buys_computer = 'no' and student = p_student;
    select prob into prob_credit_no from credit_rating_probability where buys_computer = 'no' and credit_rating = p_credit_rating;

    # 计算后验概率 P(yes|X) 和 P(no|X)
    set p_yes = p_yes * prob_age_yes * prob_income_yes * prob_student_yes * prob_credit_yes;
    set p_no = p_no * prob_age_no * prob_income_no * prob_student_no * prob_credit_no;

    if p_yes > p_no then
        set result = 'yes';
    else
        set result = 'no';
    end if;

    return result;
end;

# 测试贝叶斯预测函数
select predict('<=30','medium','yes','fair') as prediction1;
select predict('>40','low','no','excellent') as prediction2;