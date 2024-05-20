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
选择了Alpha101中的四个公式进行计算：
- Alpha#5: (rank((open - (sum(vwap, 10) / 10))) * (-1 * abs(rank((close - vwap)))))
- Alpha#33: rank((-1 * ((1 - (open / close))^1)))
- Alpha#57: (0 - (1 * ((close - vwap) / decay_linear(rank(ts_argmax(close, 30)), 2))))
- Alpha#83: ((rank(delay(((high - low) / (sum(close, 5) / 5)), 2)) * rank(rank(volume))) / (((high -
low) / (sum(close, 5) / 5)) / (vwap - close)))

建立股票信息表`stock`，使用`read.py`将数据导入数据库中。

以Alpha#5解释具体计算过程：

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