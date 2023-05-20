# 事务 （一系列不可分割的连续事件）
create table account (
    id int auto_increment primary key comment '主键id',
    name varchar(10) comment '姓名',
    money int comment '余额'
) comment '账户表';
insert into account(id, name, money) values (null, '张三', 2000), (null, '李四', 2000);

-- 恢复数据
update account set money = 2000 where name = '张三' or name = '李四';

-- 查询
select * from account where name = '张三';

-- 转账
update account set money = money - 1000 where name = '张三';

# if except not do this:
update account set money = money + 1000 where name = '李四';


-- 关闭自动提交
select @@autocommit;
set @@autocommit = 0;

-- 开始事务
begin;
-- ==
start transaction;

-- commit 手动提交事务执行结果
commit;

-- 回滚事务
rollback;


set @@autocommit = 1;
update account set money = 2000 where name = '张三' or name = '李四';
start transaction;
update account set money = money - 1000 where name = '张三';
# update account set money = money + 1000 where name = '李四';  # error
commit;
rollback;

# 事务的四大特性 ACID  ATOMICITY CONSISTENCY ISOLATION DURABILITY

# 并发事务问题：脏读、不可重复读、幻读
# 脏读：事务读取到没有提交的数据
# 不可重复读：先后读取数据但是读出来的数据不一致
# 幻读：查询时没有对应的数据，但是在插入时又已经存在了

# mysql的默认隔离级别   是否有    脏读   不可重复读    幻读
-- read uncommitted           1         1        1     # 效率最高，安全性最低
-- read committed             0         1        1
-- repeatable read            0         0        1     # mysql 默认
-- serilizable                0         0        0     # 效率最低，但绝对安全

select @@transaction_isolation;
-- set [session | global] transaction isolation level ...;
set session transaction isolation level read uncommitted;
set session transaction isolation level read committed;
set session transaction isolation level repeatable read;
set session transaction isolation level serializable;


