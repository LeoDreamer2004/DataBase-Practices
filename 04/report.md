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

本部分要求对 MovieLens 数据集进行分析查询。MovieLens 数据集包含了用户对电影的评分、用户的信息、电影的信息等。数据集中包含了 100,000 条评分。数据集中的用户信息包括用户的 ID、性别、年龄、职业等；电影信息包括电影的 ID、名称、类型等。

在数据预处理阶段，我们使用 pandas 把类型按照 "|" 分隔，然后读入数据库，这样为了避免数据冗余，多拆分一个 genres 表用来存储电影 ID 和电影类型的一对多关系。

```mysql
create table genres
(
    movieId int          not null,
    genre   varchar(255) not null
);
```

首先是查询每种类型评分最高的电影，首先计算每个电影的平均分。为了避免重复计算，将每种类型的最高分做成一个临时表，再与电影表连接得到电影名。

```mysql
with max_rating as ();
```

接着是评分两极化的电影（前10%评价分减后10%评价分）最大的电影。这里我们用滑动窗口来选取电影的前 10% 和后 10% 的评分（具体来说，分成 10 部分，选取第 1 部分和第 10 部分的电影），然后计算两者的差值，最后选取差值最大的电影。

```mysql
select movieId,
        rating,
        ntile(10) over (partition by movieId order by rating desc ) as rating_percentile
from ratings
```

然后来做用户的兴趣分析，计算每个用户综合评价最高的电影类型，观影次数最多的电影类型。这里仍采用与前面相同的方案，建立临时表避免临时查询。

利用用户的喜好来为用户生成关联图。两个用户观看了同一部电影并且评价相差不超过1，则他们之间的亲密度加1。我们只需筛选出两用户都观看的电影并比较分数，随后用 `count(*)` 聚类即可得到亲密度。

最后，我们根据用户之间的关系推荐电影。如果如果a观看了某部电影m，而b没有观看m，并且m属于b的观影兴趣范围，则向b推荐电影m。

```mysql
...
where a.movieId not in (select movieId
                        from user_movie_rating
                        where userId = user2)
  and genre in (select genre from user_interest_by_rating where userId = user2);
```
