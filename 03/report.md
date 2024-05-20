# 数据库概论第三次实习作业

> 原梓轩 2200010825
> 陈润璘 2200010848
> 任子博 2200010626

本次实习的目标是处理非关系数据

## 递归查询

## 窗口查询

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

```sql
create temporary table basicInfo ...;
create temporary table productInfo ...;
```

现在，每个用户实际上是一个 `json_object` ，其 `addr` 键的值，又是一个 `json_object`。而 `product` 键的值，则是一个 `json_array`，我们可以通过 `json_arrayagg` 函数将其转化为 JSON 格式。

### 问题二：JSON的解析

首先建表使得其中一列是 `customerId`，另一列是与之对应的 JSON，创建过程中，实际上可以从 JSON 自动解析 `customerId`，从而不必手动输入。

```sql
create temporary table customerInfo
(
    customer   json,
    customerId int generated always as (customer -> "$.customerId"),
    index idx (customerId)
);
```

查询一个 country 下的所有客户，这是一个简单的路径查询，使用 `$` 符号即可。

```sql
where customer -> "$.addr.country" = @country;
```

计算每种product的总金额，这个需要我们对数组进行展开，然后再进行聚合。我们这里选择建立 `json_table`，把 JSON 文件展开成表格，随后读取 `product` 键下的相关信息。

```sql
json_table(customer -> "$.products", '$[*]'
                         columns (
                             ProductName varchar(255) path '$.ProductName',
                             totalAmount decimal(10, 2) path '$.totalAmount'
                             )) as products # 从 JSON 展开成平面表
```

## 向量数据库