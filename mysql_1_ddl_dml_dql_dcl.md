# ddl 数据库操作

show databases;

create database if not exists hello_world;

use hello_world;

select database();

drop database if exists niganma_aiyo ;

# ddl 表操作

show tables;

create table employee (
    id int comment 'id',
    name varchar(50) comment 'name',
    age int comment 'age',
    gender varchar(1) comment 'gender'
) comment 'employee';

desc employee;

show create table employee;

alter table employee add workno int comment 'worker id no';

alter table employee modify workno char(18);

alter table employee change workno workeridno char(18) comment 'worker id no';

alter table employee rename to employee;

alter table employee drop workeridno;

drop table if exists not_exists_table;

truncate table employee;  # 删除数据，重新创建表项

# dml 修改表数据

insert into employee (id, name, age, gender)
values
    (1, 'myname', 10, 'M'),
    (2, 'othername', 12, 'F');

insert into employee (id) values (3);

insert into employee values (4, 'thirdname', 10, 'X');  # 不写字段就是全部字段

select * from employee;

update employee set age = 100, gender = 'F' where id = 1;

delete from employee where gender is null;

# dql 查询语句

# select ... from ... where ... group by ...
# having ... order by ... limit ...

create table if not exists emp (
    id              int                 comment '编号',
    workno          varchar(10)         comment '工号',
    name            varchar(10)         comment '姓名',
    gender          char(1)             comment '性别',
    age             tinyint unsigned    comment '年龄',
    idcardno        char(18)            comment '身份证号',
    address         varchar(50)         comment '工作地址',
    entrydate       date                comment '入职时间'
) comment '员工表';

alter table emp convert to character set utf8mb4;

truncate table emp;

insert into emp (id, workno, name, gender, age, idcardno, address, entrydate)
values (1, '100', '首师大', '女', 24, '123456789012345678', '北京', '2000-01-01'),
       (2, '101', '欧式角度', '男', 50, '123456789012345675', '上海', '2100-01-01'),
       (3, '102', '四大', 'X', 52, '12345678901234267X', '广州', '2000-08-01'),
       (4, '103', '丰富', 'F', 10, '123456789022345678', '北京', '2010-11-01'),
       (5, '104', '等♯', '男', 23, '123456789712345678', '武汉', '2058-10-01'),
       (6, '105', '公关部', '女', 26, '12345678901234567X', '广州', '2000-01-04'),
       (7, '106', '内核', '男', 27, '123456789012345678', '北京', '2000-02-01'),
       (8, '107', '沐', 'X', 20, '123456489012345678', '深圳', '2033-01-02'),
       (9, '108', '潍坊', '男', 14, '123456789012345678', '深圳', '2000-11-03'),
       (10, '109', null, '女', 6, '123456739012345678', '北京', '2010-01-31'),
       (11, '110', '华南虎', 'M', 8, '121456789012345678', '南京', '2060-01-02'),
       (12, '111', 'ikun', '男', 74, '22345678901234567X', '上海', '2040-01-09'),
       (13, '112', 'unknown', '女', 0, null, '北京', '2002-06-08');

# 普通查询

select * from emp;
# == (尽量不要写 * , 不直观而且效率稍低)
select id, workno, name, gender, age, idcardno, address, entrydate from emp;

select id, workno, age from emp;

select address as '工作地点' from emp;
# == 起别名
select address '工作地点' from emp;

select distinct address '地点' from emp;

# 条件查询

select address from emp where age > 20 || age = 8 || age between 10 and 20 || age in (1, 2, 3);

select age from emp where idcardno like '%X' and age <> 0 && id is not null && id is true;

select name from emp where name like '__';

# 聚合函数
# count max min avg sum  null值自动忽略

select count(*) from emp;  # 13
select count(idcardno) from emp;  # 12

select sum(age) from emp where address = '北京';

# 分组查询
# where 在分组前执行，不能聚合，having 在分组后，可聚合
select gender, avg(age) from emp where gender in  ('男', '女', 'X') group by gender;
select address, count(*) address_count from emp where age <= 25 group by address having address_count >= 2;
# select name, gender, avg(age) from emp group by gender;  # 报错或返回第一个符合条件的 name，因为这和你的分组没有关系

# 排序查询
select * from emp order by gender, entrydate desc;  # 不写默认 ASE

# 分页查询
# limit 是 mysql 的方言，其他语言自己学
select * from emp limit 0, 5;  # 从 0 开始，0 可以不写
select * from emp limit 5, 10;  # 到结尾自动截断
select * from emp limit 15, 10;  # 查到 0 条结果

# 综合
select gender, count(*) from emp where age < 50 group by gender;
select name, age from emp where age < 35 order by age, entrydate desc;
select * from emp where age between 20 and 40 order by age, entrydate desc limit 0, 5;

# 执行顺序
# 4 select ... 1 from ... 2 where ... 3 group by ...
# 3 having ... 5 order by ... 6 limit ...
select name ename, age eage from emp e where e.age > 15 order by eage;

# select colname [as] alias from tablename where conditions group by ...


# dcl 数据库用户管理（一般是数据库管理员 DBA 用的，开发人员了解即可）

select * from mysql.user;

create user if not exists 'itcast'@'localhost' identified by '123456';
create user if not exists 'heima'@'%' identified by '123456';  # 任意主机
drop user 'heima'@'%';  # 任意主机
alter user 'itcast'@'localhost' identified by '234567';

show grants for 'itcast'@'localhost';
grant insert, update, delete on hello_world.employee to 'itcast'@'localhost';
grant all privileges on *.* to 'itcast'@'localhost';
revoke all privileges on *.* from 'itcast'@'localhost';

