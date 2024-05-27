# 数据库概论第三次实习作业

> 原梓轩 2200010825
> 陈润璘 2200010848
> 任子博 2200010626

本次实习的目标是基于SQL去实践完成数据科学项目中的两个重要步骤：数据预处理和数据挖掘算法，以及基于此进行分析型的综合查询

## 练习一：基于SQL的数据预处理

## 练习二：基于SQL的数据挖掘算法
选择题目一和题目二完成
### 题目一：熵和互信息的sql实现
#### 熵的计算
随机变量X的熵的计算公式为
$$
H(X) = -\sum_{i=1}^{n}p(x_i)log_2p(x_i)
$$

创建函数以计算熵，由于mysql不能接受表作为函数参数，故对固定名称的表进行操作

```mysql
create function entropy()
returns double deterministic
begin
    ...
    # 用于计算熵的游标
    declare cur cursor for
    select count(*)/cast(total_count as float)
    from temp_intervals
    group by class;
    ...
    # 使用游标进行循环计算
    open cur;
    read_loop:
    loop
        fetch cur into p;
        ...
        set H = H - p * log2(p);
        ...
    end loop;
    close cur;
    return H;
end;
```

而后使用此函数分别计算happiness_score、economy、health列的熵。由于这些列的值均为离散值互不相同，故首先创建临时表将值从最大到最小分成40个等距区间，再进行计算（以happiness_score为例）

```mysql
# 创建临时表temp_intervals，将happiness_score列的值分为40个区间
create temporary table temp_intervals(
    value float,
    class int
);

insert into temp_intervals (value, class)
# 将值从最大到最小分成40个等距区间
...
# 计算happiness_score列的熵
select entropy() as entropy_happiness_score;
```

#### 互信息的计算

随机变量X，Y的互信息的计算公式为
$$
I(X;Y) = \sum_{i=1}^{n}\sum_{j=1}^{m}p(x_i,y_j)log_2\frac{p(x_i,y_j)}{p(x_i)p(y_j)}
$$

创建函数以计算互信息，由于mysql不能接受表作为函数参数，故对固定名称的表进行操作

```mysql
create function mutual_information()
returns double deterministic
begin
    ...
    # 用于计算互信息的游标
    declare cur cursor for
    select count_xy/cast(total_count as float), count_x/cast(total_count as float), count_y/cast(total_count as float)
    from ...
	...
    # 使用游标进行循环计算
    open cur;
    read_loop: loop
        fetch cur into p_xy,p_x,p_y;
        ...
            set I = I + (p_xy * log2(p_xy / (p_x * p_y)));
        ...
    end loop;
    close cur;
    return I;
end;
```

而后使用此函数分别计算happiness_score分别和economy、health列的互信息。同上将值从最大到最小分成40个等距区间，并保留happiness_rank列作为码用于计算联合分布。由于mysql的临时表不能在同一查询中被多次调用，故采用创建表在使用后删除的方法。

#### 结果分析

happiness_score、economy、health列的熵分别为4.997836589813232、4.952922821044922、4.923501968383789，happiness_score与economy、health列的互信息分别为2.9577317237854004、2.96954083442688。可以看出经济和健康均对幸福指数有较强相关性，二者对幸福指数的影响大致相同，且均不完全相关。



### 题目二：贝叶斯分类

首先创建临时表，计算先验概率和每个指标下的条件概率

```mysql
# 创建临时表，存储先验概率p(yes)和p(no)
create temporary table prior_probability
# 创建临时表，计算条件概率p(x|yes)和p(x|no)
create temporary table age_group_probability
...
```

此后创建函数，输入需要预测的对象，给出预测值

```mysql
create function predict(p_age_group char(10), p_income char(10), p_student char(5), p_credit_rating char(15))
returns char(5) deterministic
begin
    # 声明局部变量并按照上一步计算出的结果初始化
    ...
    # 计算条件概率 P(X|yes)
    select prob into prob_age_yes from age_group_probability where buys_computer = 'yes' and age_group = p_age_group;
    ...
	# 计算条件概率 P(X|no)
    ...
    # 计算后验概率 P(yes|X) 和 P(no|X)
    set p_yes = p_yes * prob_age_yes * prob_income_yes * prob_student_yes * prob_credit_yes;
    ...
    # 预测结果
	if p_yes > p_no then
        set result = 'yes';
    ...
end;
```

最后对两个数据库中不存在的对象进行预测。


## 练习三：分析查询