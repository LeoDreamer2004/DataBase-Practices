### Problem 1
drop table if exists customerPerson;
create temporary table customerPerson as
    (select *
     from customer
     where customer.PersonID is not null
     limit 30);

# 先读取 Customer 名称和地址信息
drop table if exists basicInfo;
create temporary table basicInfo as
    (select c.CustomerID,
            concat(p.FirstName, ' ', p.LastName) as customerName,
            a.City,
            cr.Name                              as country
     from customerPerson as c
              join person as p on c.PersonID = p.BusinessEntityID
              join businessentityaddress as bea on c.PersonID = bea.BusinessEntityID
              join address as a using (AddressID)
              join stateprovince as sp using (StateProvinceID)
              join countryregion as cr using (CountryRegionCode)
     order by c.CustomerID
     LIMIT 10);

# 读取 Customer 购买的 Product 信息，每个用户至多展示 5 个 Product
drop table if exists productInfo;
create temporary table productInfo as
    (select CustomerID,
            Name,
            totalAmount
     from (select c.CustomerID,
                  pr.Name,
                  sum(sod.LineTotal)                                                             as totalAmount,
                  row_number() over (partition by c.CustomerID order by sum(sod.LineTotal) desc) as rn
           from customerPerson as c
                    join salesorderheader as soh using (CustomerID)
                    join salesorderdetail as sod using (SalesOrderID)
                    join product as pr using (ProductID)
           group by c.CustomerID, pr.Name
           order by totalAmount desc) as RankedProducts
     where rn <= 5
     order by CustomerID, totalAmount desc);

# 存储 JSON
select json_object('customerId', CustomerID,
                   'customerName', customerName,
                   'addr', json_object('country', country, 'city', City),
                   'products',
                   json_arrayagg(json_object('ProductName', Name, 'totalAmount', totalAmount))) as customer
from basicInfo
         join productInfo using (CustomerID)
group by CustomerID, customerName, country, City;


### Problem 2

# JSON 表
drop table if exists customerInfo;
create temporary table customerInfo
(
    customer   json,
    customerID int generated always as (customer -> "$.customerId"),
    index idx (customerID)
);

# 插入数据
insert into customerInfo(customer)
select json_object('customerId', CustomerID,
                   'customerName', customerName,
                   'addr', json_object('country', country, 'city', City),
                   'products',
                   json_arrayagg(json_object('ProductName', Name, 'totalAmount', totalAmount))) as customer
from basicInfo
         join productInfo using (CustomerID)
group by CustomerID, customerName, country, City;

# 指定一个country，返回位于该country的customer
set @country = 'Australia';
select *
from customerInfo
where customer -> "$.addr.country" = @country;

# 计算每种product的总金额
select ProductName, totalAmount
from customerInfo
         join json_table(customer -> "$.products", '$[*]'
                         columns (
                             ProductName varchar(255) path '$.ProductName',
                             totalAmount decimal(10, 2) path '$.totalAmount'
                             )) as products # 从 JSON 展开成平面表
group by ProductName, totalAmount
order by totalAmount desc;
