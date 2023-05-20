# 多表查询
# 多对一/一对多可以通过外链解决
# 多对多：中间表
# 一对一，和一对一类似，设置外键 unique 保证唯一

create table student
(
    id   int auto_increment primary key comment '主键ID',
    name varchar(10) comment '姓名',
    no   varchar(10) comment '学号'
) comment '学生表';

insert into student
values (null, 'dadada', '2023412'),
       (null, 'xiexie', '2023413'),
       (null, 'yingying', '2023413'),
       (null, 'weiwei', '2023414');

create table course
(
    id   int auto_increment primary key comment '主键ID',
    name varchar(10) comment '课程名字'
) comment '课程表';
insert into course
values (null, 'JAVA'),
       (null, 'PHP'),
       (null, 'MySQL');

create table student_course
(
    id        int auto_increment comment '主键' primary key,
    studentid int not null comment '学生id',
    courseid  int not null comment '课程id',
    constraint fk_courseid foreign key (courseid) references course (id),
    constraint fk_studentid foreign key (studentid) references student (id)
) comment '中间表';

insert into student_course
values (null, 1, 1),
       (null, 1, 2),
       (null, 1, 3),
       (null, 2, 3),
       (null, 3, 3),
       (null, 4, 3);

# 可以右键表选 diagram 可视化查看

select *
from student,
     student_course; # 这样查是两个表笛卡尔只因直接合并
select *
from student,
     student_course
where student.id = student_course.studentid;
# 有一列是用来匹配的相同的列

# 连接查询（内连接，外连接（左外连接，右外连接），自连接），子查询
# inner outer 可以省略
# 内连接 （两张表都有的数据才显示）
# 隐式内连接（就是上面那个）
select u.*, d.name
from user u,
     dept d
where u.dep_id = d.id;
# 显式内连接
select u.*, d.name
from user u
         inner join dept d on u.dep_id = d.id;

# 外连接
# 左外 （完全包含左表，右表又对应数据就附上）
select u.*, d.name
from user u
         left outer join dept d on u.dep_id = d.id;
# 右外
select u.*, d.name
from user u
         right outer join dept d on u.dep_id = d.id;
# ==  （所以一般统一用左外，即你把要保留的放左边，然后无脑左外）
select u.*, d.name
from dept d
         left outer join user u on u.dep_id = d.id;

# 自连接 （可以是内连接也可以是外连接）
alter table user
    add managerid int comment '所属领导';
select u1.name as '职员名', u2.name as '领导名'
from user u1
         inner join user u2 on u1.managerid = u2.id;
select u1.name as '职员名', u2.name as '领导名'
from user u1
         left outer join user u2 on u1.managerid = u2.id;

# 联合查询
# 可以查多张表再合并，而且效率比 or 高

select *
from emp
where age < 50
# union all  # 直接合并
union
# 去重
select *
from emp
where address = '北京';


# 子查询
# 外层可以是 select，也可以是update、insert等
# 标量子查询
# 当然你也可以用内连接完成，但是笛卡尔积效率低下
select id
from dept
where name = '业务部';
select *
from user
where dep_id = 2;
-- ==
select *
from user
where dep_id = (select id from dept where name = '业务部');

select entrydate
from emp
where id = 5;
select *
from emp
where entrydate > '2058-10-01';
-- ==
select *
from emp
where entrydate > (select entrydate from emp where id = 5);

# 列子查询
select id
from dept
where name = '研发部'
   or name = '业务部';
select *
from user
where dep_id in (1, 2);
-- ==
select *
from user
where dep_id in (select id from dept where name = '研发部' or name = '业务部');

select *
from user
where age >= all (select age from user where dep_id = (select id from dept where name = '鼓励部'));
select *
from user
where age >= any (select age from user where dep_id = (select id from dept where name = '鼓励部'));
# some 和 any 是一样的

# 行子查询
select age, gender
from user
where name = 'John';
select *
from user
where (age, gender) < (select age, gender from user where name = 'John');

# 表子查询
select age, gender
from user
where name = 'John'
   or name = 'Mary';
select *
from user
where (age, gender) in (select age, gender from user where name = 'John' or name = 'Mary'); # in 只要和其中一行（一种参数值的组合）匹配即可

select u.id, u.name, u.age, d.name
from (select * from user where age >= 20) u
         left join dept d on u.dep_id = d.id;


-- 案例
-- 辅助表
create table salaryGrade
(
    grade int,
    losal int,
    hisal int
) comment '薪资等级';

insert into salarygrade
values (1, 0, 3000),
       (2, 3001, 5000),
       (3, 5001, 8000);
# 没有更高了，因为硕士八千博士一万

-- 隐式内连接：查询员工及其部门
select e.name, e.age, d.name
from emp e,
     dept d
where e.dept_id = d.id;

-- 显式内连接：查询30岁以下员工及其部门
select e.name, e.age, d.name
from emp e
         inner join dept d on e.dept_id = d.id
where e.age < 30;

-- 查询拥有员工的部门的信息
select distinct d.id, d.name, count(*) '员工人数'
from emp e
         inner join dept d on e.dept_id = d.id
group by e.dept_id;

-- 查询年龄大于 40 的员工及其所属部门
select *
from emp e
         left join dept d on d.id = e.dept_id
where e.age > 40;

-- 查询所有员工的工资等级
select e.id, e.name, e.salary, s.grade
from emp e
         left join salarygrade s on e.salary between s.losal and s.hisal; # 有null
select e.id, e.name, e.salary, s.grade
from emp e,
     salarygrade s
where e.salary between s.losal and s.hisal;
# 无null

-- 查询研发部员工的工资等级  （CTRL+ALT+L格式化）
select e.id, e.name, e.salary, s.grade
from (select id, name, salary
      from emp
      where emp.dept_id = (select id from dept where name = '研发部')) as e,
     salarygrade s
where e.salary between s.losal and s.hisal;
-- ==
select e.id, e.name, e.salary, s.grade
from emp e,
     dept d,
     salarygrade s
where e.dept_id = d.id
  and (e.salary between s.losal and s.hisal)
  and d.name = '研发部';

-- 查询研发部员工平均工资
select *
from (select d.name, avg(e.salary) '平均工资'
      from emp e,
           dept d
      where e.dept_id = d.id
      group by d.id) as e1
where e1.name = '研发部';
select avg(e.salary)
from emp e,
     dept d
where e.dept_id = d.id
  and d.name = '研发部';

-- 查询比”内核“薪资高的员工
select e.name, e.salary
from emp e
where e.salary > (select emp.salary from emp where emp.name = '内核'); # 子查询会慢一点~~
select e1.name, e1.salary
from emp e1,
     emp e2
where e2.name = '内核'
  and e1.salary > e2.salary;
# 表示对e2中的每一行，选出符合条件的e1，然后合并

-- 查询低于平均工资的员工
select id, name, salary
from emp e
where e.salary < (select avg(salary) from emp);

-- 查询低于本部门平均工资的员工
select dept_id, avg(salary)
from emp
group by dept_id;

select e.id, e.name, e.salary, d.name, e1.avgsal
from emp e,
     dept d,
     (select dept_id, avg(salary) avgsal from emp group by dept_id) e1
where e.dept_id = e1.dept_id
  and d.id = e.dept_id
  and e.salary < e1.avgsal;

-- ==

select e.id, e.name, e.salary, d.name
from emp e,
     dept d
where d.id = e.dept_id
  and e.salary < (select avg(e1.salary) from emp e1 where e1.dept_id = e.dept_id);

-- 统计所有部门的人数
select dept.name, count(dept.id) as counts
from emp,
     dept
where emp.dept_id = dept.id
group by emp.dept_id;
# 内连接，统计部门
-- ==
select d.id, d.name, (select count(*) from emp e where e.dept_id = d.id) 'counts'
from dept d;
# 查部门，包括空部门


-- 查询所有学生的选课情况
# 内连接，没有选课的就查不到了
select student.name, course.name
from student,
     course,
     student_course
where student.id = student_course.studentid
  and course.id = student_course.courseid;