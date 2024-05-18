drop table if exists family;
create table family( father char(10), son char(10) );
insert into family values
('司马防','司马懿'),
('司马防','司马孚'),
('司马防','司马馗'),
('司马懿','司马师'),
('司马懿','司马昭'),
('司马懿','司马亮'),
('司马懿','司马伦'),
('司马孚','司马瑰'),
('司马馗','司马泰'),
('司马师','司马攸'),
('司马昭','司马炎'),
('司马泰','司马越'),
('司马攸','司马囧'),
('司马炎','司马衷'),
('司马炎','司马玮'),
('司马炎','司马乂'),
('司马炎','司马颖'),
('司马炎','司马炽'),
('司马瑰','司马颙');

# 1.找出所有的兄弟关系
select a.son as brother1, b.son as brother2
from family a
join family b on a.father = b.father
where a.son < b.son;

# 2.使用递归查询找出所有祖先关系
with recursive Ancestors as (
    # 基础查询：找出直接祖先关系
    select father as ancestor, son as descendant
    from family
    union all
    # 递归查询：找出间接祖先关系
    select a.ancestor, f.son
    from Ancestors a
    join family f on a.descendant = f.father
)
select ancestor, descendant
from Ancestors;

# 3.查询所有的堂兄弟关系
with grandparent as(
    select a.father as grandfather, a.son as father, b.son as son
    from family a
    join family b on a.son = b.father
)
select g1.son as cousin1, g2.son as cousin2
from grandparent g1
join grandparent g2 on g1.grandfather = g2.grandfather
where g1.father <> g2.father and g1.son < g2.son;
