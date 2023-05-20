# 索引结构
-- B+Tree       最常见，大部分引擎都支持                            innodb myisam memory
-- Hash         精确匹配很快，但不能范围查询                         memory
-- R-tree       空间索引，MyISAM的一种特殊索引，主要用于地理空间数据     myisam
-- Full-text    通过倒排索引快速匹配                               innodb myisam

# 二叉树子节点少，层数比较深
# B-Tree 多路平衡查找树（五阶（最多最大度数为5，五个子节点） 每个节点有4个key和5个指针，超过则分裂，中间元素成为两边的父节点
# B+Tree 中间元素向上分裂的同时叶子节点仍然保有这份数据，而且左右节点用链表连起来，非叶子节点只是起到索引的作用
# MySQL 改进的 B+Tree 增加成双向链表
# 好处，B树支持随机检索，B+树支持随机检索和顺序检索
# B+树内部节点只有key没有指向具体信息的指针，只用作索引，同样大小的盘块容纳的key更多，一次性读入内存查找的key变多，即io读写次数减少，磁盘读写代价低
# B+树查询效率稳定，B看具体位置
# B+比B好的： 1. 空间利用率高，io次数少  2. 增删效率高，有序  3.查询效率稳定


# 主键索引 只有一个，针对主键默认创建
# 唯一索引 可以有多个，避免值重复
# 常规索引 可以有多个，快速定位特定数据
# 全文索引 可以有多个，查找文本中的关键词而不是比较索引中的值

# 在innodb里面分为两种
# 聚集索引 将数据与索引放到一块，叶节点保存了行数据，必须有且只有一个
# （如果有主键，主键索引就是聚集索引，否则将使用第一个unique索引，还没有就生成一个隐藏的rowid作为索引）
# 二级索引（也称辅助索引、非聚集索引）将数据与索引分开存储，叶子节点关联的是主键，可以存在多个

create table tb_user
(
    id         int primary key auto_increment,
    name       varchar(10),
    phoneno    char(11) comment 'phone number',
    email      varchar(50) comment 'email adress',
    profession varchar(10) comment 'major',
    gender     int comment '0-4',
    status     int comment '0-6',
    createtime time comment 'create time'
) comment 'user list for index learning';

alter table tb_user
    add age int;
alter table tb_user
    modify createtime datetime;
alter table tb_user
    modify phoneno char(11) unique comment 'phone number';
truncate table tb_user;


-- Author note: plz build your own tb_user here
-- I have delte my bcz it contains my info

show index from tb_user;

create index idx_user_name on tb_user (name); -- 常规索引
create unique index idx_user_phone on tb_user (phoneno); -- 唯一索引
create index idx_user_pro_age_sta on tb_user (profession, age, status); -- 联合索引  -- 字段的顺序有讲究，频繁使用的放左边，最左前缀原则，后面会讲
create index idx_user_email on tb_user (email);

show index from tb_user;

drop index idx_user_email on tb_user;

show global status like 'Com_______'; -- 可以看出 select 占了大多数
select database();

show variables like '%slow%'; -- 慢查询日志
select sleep(5);

select @@have_profiling;
select @@profiling;
set profiling = 1;
show profiles;

select *
from tb_user
where id = 1; -- 0.0001855
select *
from tb_user
where name = '白起'; -- 0.00035875
select sleep(10); -- 10.01510325

show profiles;
show profile all for query 0;

# explain select * from emp, dept where emp.dept_id = dept.id;
select *
from student s,
     course c,
     student_course sc
where s.id = sc.studentid
  and c.id = sc.courseid;
explain
select *
from student s,
     course c,
     student_course sc
where s.id = sc.studentid
  and c.id = sc.courseid;

explain
select name
from student
where id in (select studentid from student_course where courseid = (select id from course where name = 'MySQL'));

explain
select *
from tb_user
where phoneno = '15602161937';
-- id 越大的越先执行
# select_type  simple 简单查询  primary 外层查询  subquery 内层查询

# type 性能 null - system - const - eq_ref - ref - range - index - all
# const 根据主键或唯一索引查询  ref 一般索引
# all 没有索引，全局搜索  index 用了索引，全局搜索

# key_len 关键字长度（越短越好）
-- 构建索引比遍历查询一次还要慢，因为要建树
-- 但是构建完后利用索引查询会快很多（好几个数量级）

-- 联合索引必须按照顺序，不能跳过，否则无法利用此索引
explain
select *
from tb_user
where profession = '英语'
  and age = 28
  and status = 0; -- ref keylen = 53
explain
select *
from tb_user
where profession = '英语'
  and age = 28; -- 48  # 说明status的索引长度为5
explain
select *
from tb_user
where profession = '英语'; -- 43  # 说明age的索引长度为5
explain
select *
from tb_user
where age = 28
  and status = 0; -- all （最左前缀匹配
explain
select *
from tb_user
where profession = '英语'
  and status = 0; -- 43 只有profession匹配，status失效嘞
explain
select *
from tb_user
where age = 28
  and status = 0
  and profession = '英语'; -- 存在即可，与and的顺序无关


explain
select *
from tb_user
where profession is null
  and age > 30
  and status = 0; -- 48 (<, >) 范围查找（不含）后面的就失效了
explain
select *
from tb_user
where profession is null
  and age >= 30
  and status = 0; -- 53 (<=, >=) 不失效

show index from tb_user;

# 字段被计算也无法索引
explain
select *
from tb_user
where phoneno = '18129581937'; -- const
explain
select *
from tb_user
where phoneno like '%37'; -- all  （前置%导致失效
explain
select *
from tb_user
where phoneno like '18%'; -- all  （隐式的整形转字符串，不行？？？）

explain
select *
from tb_user
where tb_user.profession like '软件%'; -- range  (后缀的%可以利用索引  43

explain
select *
from tb_user
where tb_user.profession like '%工程'; -- all, 前缀失效

explain
select *
from tb_user
where substr(phoneno, 10, 2) = '37'; -- all
explain
select *
from tb_user
where phoneno = 18129581937;
-- all  (隐式类型转换也导致失效  possible_keys 但是用不上

-- or 连接的应当两边都有索引，否则无效
explain
select *
from tb_user
where id = 1
   or age = 20;
create index idx_user_age on tb_user (age);
explain
select *
from tb_user
where id = 1
   or age = 20; -- index_merge
drop index idx_user_age on tb_user;

-- 数据分布影响，MySQL评估索引比全表扫描慢
explain
select *
from tb_user
where phoneno >= '1810000000'; -- all  (绝大部分数据都满足筛选要求，直接全表扫描
explain
select *
from tb_user
where phoneno >= '18200000000'; -- range

explain
select *
from tb_user
where profession is null; -- ref
explain
select *
from tb_user
where profession is not null;
-- all

-- 单列和联合索引都有的情况
create index idx_user_pro on tb_user (profession);
explain
select *
from tb_user
where profession = '软件工程'; -- 用了联合索引

explain
select *
from tb_user use index (idx_user_pro)
where profession = '软件工程'; -- 建议
explain
select *
from tb_user ignore index (idx_user_pro)
where profession = '软件工程'; -- 建议
explain
select *
from tb_user force index (idx_user_pro)
where profession = '软件工程';
-- 建议

-- 覆盖索引  与返回字段的关系
explain
select *
from tb_user
where profession = '软件工程'
  and age = 5
  and status = 2; -- extra = null
explain
select id, profession, age
from tb_user
where profession = '软件工程'
  and age = 5
  and status = 2; -- extra = using index  不需要回表
explain
select id, profession, age, status
from tb_user
where profession = '软件工程'
  and age = 5
  and status = 2; -- extra = using index
explain
select id, profession, age, status, name
from tb_user
where profession = '软件工程'
  and age = 5
  and status = 2;
-- extra = null   需要回表

-- 前缀索引
-- 字段为 varchar 等时，要索引很长的字符串，可以只将一部分前缀建立索引
-- 可以根据索引的选择性来确定，选择性指不同的数量与总数的比值，唯一索引选择性为1，性能最好
select count(distinct email) / count(*)
from tb_user;
select count(distinct substr(email, 1, 10)) / count(*)
from tb_user;

create index idx_email on tb_user (email);
create index idx_email_10 on tb_user (email(10));
# drop index idx_email_10 on tb_user;
show index from tb_user;

explain
select *
from tb_user use index (idx_email_10)
where email = '2723643836@qq.com'; -- 43
explain
select *
from tb_user use index (idx_email)
where email = '2723643836@qq.com'; -- 203

create unique index idx_user_phone_name on tb_user (phoneno, name); -- phone 已经是唯一的了，这个索引也写成唯一
explain
select id, phoneno, name
from tb_user
where phoneno = '18129581937'
  and name = '吕布';
-- keylen = 45 extra = null （只选择phone和name中效率比较高的index进行查询）
explain
select id, phoneno, name
from tb_user use index (idx_user_phone_name)
where phoneno = '18129581937'
  and name = '吕布';
-- keylen = 88 extra = using index

# 实际场景中，如果有多个查询条件，应尽量建立联合索引，因为即使全部条件都有单列索引，也只会评估并生效一个
# 原则
-- 数据量大要考虑建立索引 100w以上
-- 索引加速 where order group 不查的别搞索引
-- 选择区分度高的来建立索引，提高索引的效率
-- 字符串太长，可以建立前缀索引
-- 尽量使用联合索引，减少单列索引，节省空间和时间
-- 控制索引数量，不然影响增删改的维护效率
-- 如果不允许 null，建表时就该 not null，优化器会在查询时利用这个信息进行优化
