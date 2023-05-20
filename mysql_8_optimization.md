# SQL 优化
-- INSERT、PRIMARY KEY、ORDER BY、GROUP BY、LIMIT、COUNT、UPDAET

-- INSERT 批量插入（单条插入需要反复建立连接、超过1000条数据分批插入）
--        手动事务提交  start transaction; insert ... ; commit;
--        建议主键顺序插入 （见主键优化）

-- 极大量的插入，使用load指令加载csv文件
-- 1. mysql --local-infile -u root -p
-- 2. set global local_infile = 1;
-- 3. load data local infile '/root/sql.log' into table 'tb_user' fields terminated by ',' lines terminated by '\n';

show variables like '%local%infile%';
select @@local_infile;

set global local_infile = 1;

create table tb_user1
(
    id         int primary key auto_increment,
    name       varchar(10),
    phoneno    char(11) comment 'phone number',
    email      varchar(50) comment 'email adress',
    profession varchar(10) comment 'major',
    gender     int comment '0-4',
    status     int comment '0-6',
    createtime datetime comment 'create time'
) comment 'user list for loading';

# 这一段在这里跑不了好像qwq，在cmd中加上--local-infile参数登录，选定数据库然后使用下面代码导入，检查比较松散，可选项比较少 (10s)
# 在datagrip中右键表然后import即可，还有参数可以选，不用这样导入，检查比较严格，有自动的错误文件，时间比较长 (1m30s)
truncate table tb_user1;
load data local infile 'C:/Users/27236/Desktop/mysql/TEST.csv'
    into table tb_user1
    fields terminated by ','
    lines terminated by '\n';

# 主键优化
-- innodb中规定页可以为空，或填充一半，或填充满，每个页包含2-N行数据，根据主键排列
-- 行太大会行溢出，页与页之间用双向链表连接
-- 主键乱序插入会用页分裂解决，删除的时候可能会发生页合并
-- 主键的建立和修改会影响索引的大小和维护时间

# 优化建议
-- 减少主键长度
-- 主键顺序插入或 auto——increment
-- 不要使用 uuid 等，容易乱序
-- 不要修改主键

# order by 优化
-- using filesort 读取后排序
-- using index 有序读出

show index from tb_user;
drop index idx_user_age_phone on tb_user;
explain select id, age, phoneno from tb_user order by age;  -- all    using filesort
create index idx_user_age_phone on tb_user(age, phoneno);
explain select id, age, phoneno from tb_user order by age;  -- index  using index
explain select id, age, phoneno from tb_user order by age desc;  -- index  Backward index scan; Using index
explain select id, age, phoneno from tb_user order by phoneno desc;  -- index  Using index; Using filesort 因为索引先对age排序了
explain select id, age, phoneno from tb_user order by age, phoneno desc;  -- index  Using index; Using filesort 因为phone是desc
explain select * from tb_user order by age, phoneno;  -- all using filesort 不是覆盖索引，mysql觉得干脆全表扫描算了

create index idx_user_age_phone_ad on tb_user(age, phoneno desc);  # show index 中的 collation 列显示了升序A还是降序D
explain select id, age, phoneno from tb_user order by age, phoneno desc;  -- index  Using index;

-- 总结，如果对联合索引的左边部分排序或对全部排序，而且全部升序或全部降序，则走索引
-- 使用右边或者有部分降序排序，则至少部分不走索引
-- 可以在创建索引时按照顺序来组织，适当安排可以减少全表搜索
-- mysql会选择适当的索引，当然你也可以指定
-- 尽量使用覆盖索引
-- 不可避免地出现 filesort，大量排序时，可以适当增大 sort_buffer_size (默认256k)

# group by 优化
drop index idx_user_pro_age_sta on tb_user;
create index idx_user_pro_age_sta on tb_user(profession, age, status);

drop index idx_user_age_phone on tb_user;
create index idx_user_age_phone on tb_user(age, phoneno);

drop index idx_user_age_phone_ad on tb_user;
create index idx_user_age_phone_ad on tb_user(age, phoneno desc);

show index from tb_user;

drop index idx_user_pro on tb_user;
create index idx_user_pro on tb_user(profession);

explain select profession, count(*) from tb_user group by profession;  -- all    using temporary
create index idx_user_pro_age_sta on tb_user(profession, age, status);
explain select profession, count(*) from tb_user group by profession;  -- index  using index
explain select age, count(*) from tb_user group by age;  -- index  Using index; Using temporary
explain select profession, age, count(*) from tb_user group by profession, age;  -- index  using index
-- 注意这样也算满足最左前缀，即where找出的字段本就是age排序的，所以不用temporary
explain select age, count(*) from tb_user where profession is null group by age;  -- ref   Using where; Using index

# limit 优化
select count(*) from tb_user1;
select * from tb_user1 order by id limit 0, 10;  -- 快
select * from tb_user1 order by id limit 999990, 10;  -- 慢
select id from tb_user1 order by id limit 999990, 10;  -- 中，覆盖索引
# select * from tb_user1 where id in (select id from tb_user1 order by id limit 999990, 10);  -- 错误，不能在子查询中用 limit
select * from tb_user1 s, (select id from tb_user1 order by id limit 999990, 10) a where s.id = a.id;  -- 中

# limit 后半段慢的原因：你要对很多字段做选择/排序等操作，才在最后选择那一点点数据，太浪费
# 改进思路：用覆盖索引+子查询，见上

# count 查询
-- MyISAM 将总行数存在了磁盘上，查总行数直接返回效率很高
-- InnoDB 要把数据一行一行读出来累积计数，很麻烦

# 思路：自己计数，不要用 count
-- count(*) or count(primary key) 统计全部
-- count(字段)  统计非 null
-- count(null) count(1) 返回0，返回总数，即每个都不算/每个都算

# count(主键） 拿到主键，直接累加（因为不可能是null）
# count(字段)  not null 字段 也是将其取出直接累加，没有限制的判断后累加
# count(1)    不会取值，遍历到每行时放一个1进去
# count(*)    理论上取全部字段，但innodb做了优化，实际上不取值直接累加

-- 效率  count(字段) < count(主键) < count(1) <~ count(*)

# update 优化
begin;
show index from course;
update course set name = 'JavaEE' where id = 1;  # 行锁
update course set name = 'PHP2' where name = 'PHP';  # 表锁  -- name 没有索引，全表扫描将所有数据加锁，相当于表锁
-- 这样别的事务就没法同时操作这个表了
commit;

create index idx_course_name on course(name);  # 这样就是行锁了

-- 总结：update要用有索引的条件，而且不能失效，否则损失并发性能


-- insert: 批量、事务、主键顺序   大量数据用load
-- 主键: 用短的、顺序的
-- order by: using index 而不要 using filesort
-- group by: 利用索引，注意最左前缀
-- limit: 覆盖索引+子查询
-- count: count(*) 有优化，最快
-- update: 使用索引避免全表扫描和锁定

-- 省流：注意索引

