# 数据库概论第三次实习作业

> 原梓轩 2200010825
> 陈润璘 2200010848
> 任子博 2200010626

本次实习的目标是处理非关系数据

## 递归查询
### 问题一：找出所有的兄弟关系
使用select语句找出表中有相同父亲的两个人即可，在限制条件中使用“<”来避免重复。
### 问题二：找出所有的祖先关系
使用`with recursive`关键字进行递归查询，该查询由基础查询和递归查询组成，基础查询返回递归查询的初始行，递归查询引用自身，直到返回空集。
```mysql
with recursive Ancestors as (
    # 基础查询
    union all
    # 递归查询
)
```
在基础查询部分，查询出所有直接的父子关系，然后递归查询所有间接祖先关系，并将二者合并。
### 问题三：找出所有的堂兄弟关系
使用CTE，首先找出所有爷孙关系
```mysql
with grandparent as(
    # 找出所有爷孙关系
)
```
然后使用这个通用表，找出所有爷爷相同但父亲不同的两个人
## 窗口查询
选择 了Alpha101 中的四个公式进行计算：
- Alpha#5: (rank((open - (sum(vwap, 10) / 10))) * (-1 * abs(rank((close - vwap)))))
- Alpha#33: rank((-1 * ((1 - (open / close))^1)))
- Alpha#57: (0 - (1 * ((close - vwap) / decay_linear(rank(ts_argmax(close, 30)), 2))))
- Alpha#83: ((rank(delay(((high - low) / (sum(close, 5) / 5)), 2)) * rank(rank(volume))) / (((high -
low) / (sum(close, 5) / 5)) / (vwap - close)))

建立股票信息表`stock`，使用`read.py`将数据导入数据库中。

以 Alpha#5 解释具体计算过程：

使用CTE语句逐步进行计算(以下为代码中关键语句)

```mysql
with vwap_calc as (
    # 计算vwap
),
avg_vwap as (
    # 使用窗口函数，计算10日内vwap均值即sum(vwap, 10) / 10
    avg(vwap) over (partition by ts_code order by trade_date rows between 9 preceding and current row) as avg_vwap_10
),
ranked_open as (
    # 使用窗口函数，计算rank((open - (sum(vwap, 10) / 10)))
    rank() over (partition by a.trade_date order by s.open - avg_vwap_10) as rank_open
),
ranked_close as (
    # 使用窗口函数，计算rank((close - vwap))
    rank() over (partition by a.trade_date order by s.close - s.vwap) as rank_close
)
final_calc as (
    # 使用上述结果，完成alpha005的计算
    cast(o.rank_open as signed) * -1 * cast(abs(c.rank_close) as signed) as alpha5
)
```

计算完毕后，按照alpha005的值降序查询出结果。

## JSON文件

### 问题一：JSON的创建

对于每个单个的用户，题目要求的 JSON 文件形如这样的格式：
```json
{
  "customerId": 20,
  "customerName": "Kane John",
  "addr": {
    "country": "Australia",
    "city": "Graz"
  },
  "products": [
    {
      "productName": "Product 1",
      "totalAmount": 3000
    },
    {
      "productName": "Product 2",
      "totalAmount": 5000
    }
  ]
}
```

首先，我们先从数据库读取这两部分数据。由于 product 的表较大，所有表格全部 join 起来开销太高，我们选择先读取 customer 的基本信息，然后再读取 product 的采购数据。

```mysql
create temporary table basicInfo ...;
create temporary table productInfo ...;
```

现在，每个用户实际上是一个 `json_object` ，其 `addr` 键的值，又是一个 `json_object`。而 `product` 键的值，则是一个 `json_array`，我们可以通过 `json_arrayagg` 函数将其转化为 JSON 格式。

### 问题二：JSON的解析

首先建表使得其中一列是 `customerId`，另一列是与之对应的 JSON，创建过程中，实际上可以从 JSON 自动解析 `customerId`，从而不必手动输入。

```mysql
create temporary table customerInfo
(
    customer   json,
    customerId int generated always as (customer -> "$.customerId"),
    index idx (customerId)
);
```

查询一个 country 下的所有客户，这是一个简单的路径查询，使用 `$` 符号即可。

```mysql
where customer -> "$.addr.country" = @country;
```

计算每种product的总金额，这个需要我们对数组进行展开，然后再进行聚合。我们这里选择建立 `json_table`，把 JSON 文件展开成表格，随后读取 `product` 键下的相关信息。

```mysql
json_table(customer -> "$.products", '$[*]'
                         columns (
                             ProductName varchar(255) path '$.ProductName',
                             totalAmount decimal(10, 2) path '$.totalAmount'
                             )) as products # 从 JSON 展开成平面表
```

## 向量数据库

向量数据库的部分使用本地的 PostgreSQL 数据库完成。运行前请设置好数据库的用户名和密码。 同时，请修改所有带有 `WARNING` 的注释。

### 问题一：向量数据库的创建

首先，我们创建两个表来存储倚天屠龙记的内容和人物信息，并将数据导入数据库。然后，我们使用出现向量的方式来计算共现表。

首先计算出现向量：

```postgresql
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

alter table person add column phaseContains bit(45);
-- update person
update person
set phaseContains = getBitString(personName)
where person.personid < 1000; -- make sql happy
```

然后，根据共现向量计算共现表：

```postgresql
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
         join person p2 on p1.personId <= p2.personId;
```

### 问题二：使用向量数据库查询人物的相似度

首先，我们根据共现矩阵计算每个任务对应的向量，这部分通过提供的 Python 脚本完成。计算完成后，将数据存入数据库。

最后，使用余弦相似度计算两个人物之间的相似度：

```postgresql
select p1.personName, p2.personName, p1.word_vector <=> p2.word_vector as similarity
from person p1, person p2
where p1.personId < p2.personId
order by similarity 
limit 20;
```

其中，`<=>` 是 PostgreSQL 的向量扩展中的余弦相似度函数。