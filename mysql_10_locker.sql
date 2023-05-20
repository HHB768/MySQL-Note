-- 全局锁：对整个数据库实例加锁，后续的DML写语句、DDL语句、事务提交语句都会被阻塞
-- 使用场景：全库的逻辑备份（对所有表进行锁定获得一致性视图，保证数据完整性）
-- 如果使用表级锁，多表操作时可能会不一致，比如说库存表保存了交易前的，订单表保存了交易后的

flush tables with read lock;
-- 命令行指令：
# mysqldump -h127.0.0.1 -uroot -p hello_world > D:/save.sql
unlock tables;

-- 缺点，备份期间无法更新
--      主从延迟（运维）

# innodb 可以在备份时 --single-transaction 不加锁就可以完成一致性备份
# mysqldump --single-transaction -h127.0.0.1 -uroot -p hello_world > D:/save.sql

-- 表级锁：表锁、元数据锁、意向锁
# 表锁：读共享锁和独占写锁
show triggers ;
drop trigger if exists tb_user_insert_trigger;
drop trigger if exists tb_user_delete_trigger;
drop trigger if exists tb_user_update_trigger;

lock tables tb_user read;
select * from tb_user;
update tb_user set phoneno = '12398725864' where id = 4;  -- 报错,读锁不能写,如果别的客户端使用会阻塞
unlock tables;

lock tables tb_user write;
select * from tb_user;
update tb_user set phoneno = '14796365482' where id = 4;  -- 成功,别的客户端不能读也不能写
unlock tables;

-- 元数据锁避免 DML 和 DDL 冲突,保证读写的正确性
-- 是系统自动添加的,用来维护表的机制
-- 用户操作                         自动添加的元数据锁
-- lock                            SHARED_READ_ONLY / SHARED_NO_READ_WRITE
-- select                          SHARED_READ
-- insert update delete            SHARED_WRITE
-- alter table                     EXCLUSIVE  -- 它和其他互斥

-- 即 DML 操作数据时,该事务会自动加 MDL, 另一个客户端 DDL 修改表结构则会被阻塞

select OBJECT_TYPE, OBJECT_SCHEMA, OBJECT_NAME, LOCK_TYPE, LOCK_DURATION
from performance_schema.metadata_locks;

lock tables tb_user write;

select OBJECT_TYPE, OBJECT_SCHEMA, OBJECT_NAME, LOCK_TYPE, LOCK_DURATION
from performance_schema.metadata_locks;

unlock tables;

-- 在试图加表锁时,会逐行检查是否有冲突的行锁
-- 意向锁相当于行锁在表这个层次的标记,可以避免表锁的逐行检查
-- 意向共享锁 IS: select ... lock in share mode
-- 意向排他锁 IX: insert update delete

begin;
select * from tb_user where id = 1 lock in share mode;
-- record 是行锁
select OBJECT_SCHEMA, OBJECT_NAME, INDEX_NAME, LOCK_TYPE, LOCK_MODE, LOCK_DATA
from performance_schema.data_locks;

lock tables tb_user read;  -- 成功,因为兼容
lock tables tb_user write;  -- 在另一个客户端阻塞,不兼容
unlock tables;
commit;

-- 行级锁：粒度最小，并发度最高
-- innodb支持行级锁，myisam不支持
-- innodb 的数据是基于索引组织的，行锁是通过索引上的索引项来实现的，有三类：
-- RECORD LOCK: 锁定单个记录防止其他事务的update和delete 在 RC / RR 中支持
--              分为：共享锁 (S)、排他锁 (X)
--              insert update delete 自动加排他锁 select 不加锁 select lock in share mode 共享锁 select for update 排他锁
-- GAP LOCK: 锁住索引记录（不含）的间隙，防止其他事务在中间insert导致幻读，在 RR 支持
-- NEXT-KEY LOCK: 将行和间隙一起锁住，在 RR 中支持
--                默认情况下 innodb 在 repeatable read 隔离级别中运行，使用 next-key 进行索引扫描防止幻读
--                针对唯一索引，会优化为行锁，否则为所有记录加锁，相当于表锁
show variables like "%isola%";

begin;
select * from tb_user where id = 1;
select OBJECT_SCHEMA, OBJECT_NAME, INDEX_NAME, LOCK_TYPE, LOCK_MODE, LOCK_DATA
from performance_schema.data_locks;
select * from tb_user where id = 1 lock in share mode;
select OBJECT_SCHEMA, OBJECT_NAME, INDEX_NAME, LOCK_TYPE, LOCK_MODE, LOCK_DATA
from performance_schema.data_locks;  -- S 共享锁
select * from tb_user where id = 1 lock in share mode;  -- 兼容，若在另一个客户端执行将看到两个锁
-- update ... where id = 1 则不兼容，阻塞等待

-- 有索引的等值查询优化为间隙锁
select * from tb_user;
show index from tb_user;
begin;
update tb_user set age = 10 where phoneno = '18129581937';
select OBJECT_SCHEMA, OBJECT_NAME, INDEX_NAME, LOCK_TYPE, LOCK_MODE, LOCK_DATA
from performance_schema.data_locks;  -- RECORD_NOT_GAP 欸不对啊怎么不是间隙锁
rollback;

-- 非唯一索引等职查询，找到第一个大于此值的的退化为间隙锁
# drop index idx_user_age on tb_user;
create index idx_user_age on tb_user(age);
begin;
select * from tb_user where age = 24 lock in share mode;
select OBJECT_SCHEMA, OBJECT_NAME, INDEX_NAME, LOCK_TYPE, LOCK_MODE, LOCK_DATA
from performance_schema.data_locks;  -- 行锁 RECORD_NOT_GAP 锁 3  临键锁 S 锁 24， 3 间隙锁 25, 4 锁 24-25 间隙
rollback;

-- 范围查询，加临键锁直到不满足条件的第一个值
begin;
select * from tb_user where age < 24 lock in share mode;
select OBJECT_SCHEMA, OBJECT_NAME, INDEX_NAME, LOCK_TYPE, LOCK_MODE, LOCK_DATA
from performance_schema.data_locks;  -- 行锁 RECORD_NOT_GAP 锁 id = 1, 5, 11 临键锁 S 锁 age = 5, 10, 18, 24
rollback;

begin;
select * from tb_user where age > 24 lock in share mode;
select OBJECT_SCHEMA, OBJECT_NAME, INDEX_NAME, LOCK_TYPE, LOCK_MODE, LOCK_DATA
from performance_schema.data_locks;  -- supremum pseudo-record 表示锁一个假想的正无穷 即 (24, +∞)
rollback;

-- 锁：并发访问时解决数据有效性的机制
-- 全局、表级、行级锁
-- 全局锁：锁整个数据库，不能再写入，用来逻辑备份
-- 表级锁：表锁（读/写）、元数据锁（避免ddldml冲突）、意向锁（自动添加以避免逐行检查）
-- 行级锁：行锁（共享/排他锁）、间隙锁（所间隙）、临键锁（记录+间隙，简单理解就是前两者组合，目的是为了避免幻读）




