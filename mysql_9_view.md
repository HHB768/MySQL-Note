# 视图、存储过程、触发器

-- 创建
-- or replace 可省
create or replace view stu_v_1 as
select id, name
from student
where id <= 10;

-- 查询
show create view stu_v_1;
-- res: CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `stu_v_1`
--      AS select `student`.`id` AS `id`,`student`.`name` AS `name` from `student` where (`student`.`id` <= 10)
select *
from stu_v_1
where id < 3; -- 就像查表一样

-- 修改
-- 也可以用 create or replace 会自动 replace
-- 另一种
    alter view stu_v_1 as select id, no
                          from student;
select *
from stu_v_1;

-- 删除视图
drop view if exists stu_v_1;
-- 最后一个视图被删除后，view 文件夹不再展示


-- 视图增删改
delete
from student
where id >= 6;

create or replace view stu_v_1 as
select id, name
from student
where id <= 20;
insert into stu_v_1
values (6, 'Tom'); # 实际上是插入到对应的基表中
insert into stu_v_1
values (30, 'Tommy');
# 插入成功，但是这个视图看不见，这就需要引入检查

-- cascaded and local
-- cascaded 检查当前表和依赖表的检查条件是否满足
-- local 检查当前表的条件，之前若有检查则检查，若无检查则不检查
delete
from student
where id >= 6;
create or replace view stu_v_1 as
select id, name
from student
where id <= 20;
create or replace view stu_v_2 as
select id, name
from stu_v_1
where id >= 10
with cascaded check option;
create or replace view stu_v_3 as
select id, name
from stu_v_2
where id >= 15;

insert into stu_v_3
values (12, 'Tommy'); # 成功
insert into stu_v_3
values (22, 'Tommy'); # 失败

delete
from student
where id >= 6;

create or replace view stu_v_4 as
select id, name
from stu_v_1
where id >= 10
with local check option;
create or replace view stu_v_5 as
select id, name
from stu_v_4
where id >= 15;

insert into stu_v_5
values (12, 'Tommy'); # 成功
insert into stu_v_5
values (22, 'Tommy');
# 成功

-- 视图可更新：视图中的行与基础表中的行一一对应，否则不能更新，比如：
-- 使用了聚合函数
-- distinct
-- group by
-- having
-- union / union all

create or replace view stu_v_count as
select count(*)
from student;
insert into stu_v_count
values (10);
# wrong! not insertable-into

# 视图的作用
-- 简单       简化用户对数据的理解，而且可以将经常使用的查询定义为视图
-- 安全       让用户看到特定的行列
-- 数据独立    可以屏蔽部分基表的改变

-- 案例
-- 屏蔽手机号和邮箱
create or replace view user_v as
select id, name, profession, age, gender, status, createtime
from tb_user;
select *
from user_v;

-- 将学生和课程的对应关系保存下来
create or replace view stu_cou_v as
select s.name as student_name, c.name as course_name
from student s,
     student_course sc,
     course c
where s.id = sc.studentid
  and sc.courseid = c.id;

-- 存储过程
-- 封装和重用一段代码
-- 可以接受和返回参数
-- 这段代码放在数据库中，一次调用执行一系列代码，减少交互

create procedure p1()
begin
    select count(*) from student;
end;

call p1();

# CREATE DEFINER=`root`@`localhost` PROCEDURE `p1`()
# begin
#     select count(*) from student;
# end

select *
from information_schema.routines
where routine_schema = 'hello_world';
show create procedure p1;
select routine_definition
from information_schema.routines
where routine_schema = 'hello_world';

drop procedure if exists p1;

# 在命令行中要使用
-- delimiter $$
-- 之类的命令改变自动执行的结束符
-- 记得用完改回来 delimiter ;

-- 系统变量分为全局和会话变量 GLOBAL SESSION（默认）
-- show [global | session] variables [like '...']  模糊
-- select @@...  精确
show variables;
show session variables like 'auto%';
select @@global.autocommit;

-- set [@@][global | session] ... [:]= ...
set autocommit = 0;
select @@global.autocommit;
select @@autocommit;
set autocommit = 1;
-- 手动提交是 commit

-- 注意：mysql服务重启后设置的参数（即使是全局的）也会重置，应该修改配置文件
-- 用户变量只能是当前连接的
-- set @var = expr
set @name = 'itcast';
set @age = 10;
set @gender := '男', @zhiyin := 'aiyo-niganma';
select @name, @zhiyin;
-- 推荐使用 := 因为 = 已经用来判断相等嘞
-- 另一种赋值：
select count(*)
into @count
from tb_user;
select @count;
select @abcdefg; -- 读取一个没有定义的变量，结果为null

-- 局部变量：用于存储过程的变量，在 begin ... end 之间，需要 declare
create procedure p2()
begin
    declare stu_count int default 0;
    select count(*) into stu_count from student;
    select stu_count;
end;

call p2();

-- 参数

drop procedure p3;
create procedure p3(in score int, out result varchar(10))
begin
    if score >= 85 then
        set result := '优秀';
    elseif score >= 60 then
        set result := '及格';
    else
        set result := '不及格';
    end if;
end;


call p3(100, @res);
select @res;
call p3(58, @res);
select @res;

create procedure p4(inout score int)
begin
    set score := score * 0.5; # 四舍五入
end;

set @score := 155;
call p4(@score);
select @score;

create procedure p5(in month int)
begin
    declare result varchar(10);

    case
        when month >= 1 and month <= 3 then set result := '第一季度';

        when month >= 4 and month <= 6 then set result := '第二季度';

        when month >= 7 and month <= 9 then set result := '第三季度';

        when month >= 10 and month <= 12 then set result := '第四季度';

        else set result := '非法参数';

        end case;

    select concat('您输入的月份为: ', month, ', 所属的季度为: ', result);
end;

call p5(4);

drop procedure p6;
create procedure p6(in n int)
begin
    declare total int default 0;
    while n > 0
        do
            set total := total + n;
            set n := n - 1;
        end while;
    select total;
end;

call p6(10);


create procedure p7(in n int)
begin
    declare total int default 0;
    repeat
        set total := total + n;
        set n := n - 1;
    until n <= 0 end repeat;
end;

call p7(10);

drop procedure p8;
create procedure p8(in n int)
begin
    declare total int default 0;
    sum :
    loop
        -- 起个名字
        if n <= 0 then leave sum; end if;
        set n := n - 1;
        if n % 2 then
            iterate sum;
        end if;
        set total := total + n;

    end loop sum;
    select total;
end;

call p8(10);

-- cursor 游标/光标
drop procedure p9;
drop table if exists tb_user_pro;
create procedure p9(in uage int)
begin
    declare uname varchar(10);
    declare uprof varchar(20);
    declare u_cursor cursor for select name, profession from tb_user where age <= uage;
    -- 游标应该在所有变量声明之后
#     declare exit handler for SQLSTATE '02000' close u_cursor;  -- 声明一个条件处理，当 02000 状态时退出
    declare exit handler for not found close u_cursor; -- 这个也可以

    create table if not exists tb_user_pro
    (
        id         int primary key auto_increment,
        name       varchar(10),
        profession varchar(20)
    );

    open u_cursor;
    while true
        do
            fetch u_cursor into uname, uprof;
            insert into tb_user_pro values (null, uname, uprof);
        end while;
    close u_cursor;
end;

call p9(20);

-- 存储函数，只能有 in 参数，用返回值返回
-- 可以被存储过程完全替代
-- deterministic: 给定参数给出确定结果  no sql: 没有sql语句  reads sql data: 只读不写
drop function func;
create function func(n int)
    returns int
    deterministic
begin
    declare total int default 0;

    while n > 0
        do
            set total := total + n;
            set n := n - 1;
        end while;

    return total;
end;

select func(10);

-- 触发器
-- mysql 只支持行级触发器

create table if not exists user_logs
(
    id               int(11)     not null auto_increment,
    operation        varchar(20) not null comment 'insert/update/delete',
    operation_time   datetime    not null comment 'time',
    operation_id     int(11)     not null,
    operation_params varchar(500),
    primary key (id)
) engine = innodb
  default charset = utf8;

truncate user_logs;

drop trigger tb_user_insert_trigger;
create trigger tb_user_insert_trigger
    after insert
    on tb_user
    for each row
begin
    insert into user_logs(id, operation, operation_time, operation_id, operation_params)
    values (null, 'insert', now(), new.id, concat('插入的内容为: id = ', new.id, ', name = ', new.name, ' 其他懒得写了...'));
end;

show triggers;

insert into tb_user(id, name, phoneno, email, profession, age, gender, status, createtime)
values (null, 'cxk', '52348962178', 'nigama_aiyo@kk.com', '练习生', 25, '1', '1', now());


drop trigger if exists tb_user_update_trigger;
create trigger tb_user_update_trigger
    after update
    on tb_user
    for each row
begin
    insert into user_logs(id, operation, operation_time, operation_id, operation_params)
    values (null, 'update', now(), new.id, concat('更新前的内容为: id = ', old.id, ', name = ', old.name,
        '\t更新后的内容为: id = ', new.id, ', name = ', new.name));
end;

show triggers;

update tb_user set name = 'zhiyin' where id = 15;  -- 实际作用了几行就会触发几次，要是没有 id=15，则不会触发
                                                   -- 若修改后的内容与之前一样，也算作修改

drop trigger if exists tb_user_delete_trigger;
create trigger tb_user_delete_trigger
    after delete
    on tb_user
    for each row
begin
    insert into user_logs(id, operation, operation_time, operation_id, operation_params)
    values (null, 'delete', now(), old.id, concat('删除前的内容为: id = ', old.id, ', name = ', old.name));
end;

show triggers;

insert into tb_user(id, name, phoneno, email, profession, age, gender, status, createtime)
values (null, 'kkkk', '11115555999', 'nigama_aiyo@kk.com', '偶像练习生', 25, '1', '1', now());

delete from tb_user where profession = '偶像练习生';

-- 视图：虚拟表，不保存结果，只保存逻辑，简单安全独立
-- 存储过程：事先定义好的一段sql语句，减少交互提高性能封装重用，变量、ifelse、inout、whilerepeatloop、cursor、handler
-- 存储函数：参数为in，有返回值，可被存储过程代替
-- 触发器：可以在表数据变化之前或之后触发，确保完整性、日志记录、数据校验
