# 约束
# 也可以用傻瓜式 ui 来完成
create table user (
    id          int             primary key auto_increment          comment '主键',
    name        varchar(10)     not null unique                     comment '非空唯一',
    age         int             check ( age > 0 && age <= 120 )     comment '范围约束',
    status      char(1)         default '1'                         comment '带默认值',
    gender      char(1)                                             comment '无附加约束'
) comment '用户表';

insert into user(name, age, status, gender) values ('Tom', 19, '1', '男'), ('John', 25, '0', '男');
insert into user(name, age, status, gender) values ('Tom', 19, '1', '女');  # 失败，但是这次申请把 id3 给占用了
insert into user(name, age, status, gender) values ('Mary', 20, '1', '女');
insert into user(name, age, status, gender) values ('kunkun', 20, '1', '女');

# 外链约束（企业开发一般不建议使用
alter table user add dep_id int comment '部门（外链）';
create table dept (
    id int,
    name varchar(10)
) comment '部门表';

alter table dept modify id int primary key;
insert into dept(id, name) values (1, '研发部'), (2, '业务部'), (3, '鼓励部');

-- 添加外键  # 有趣的注释方式
#                                                        外键                 主键
alter table user add constraint fk_user_dept foreign key (dep_id) references dept(id);  # 引用的必须是 primary key or unique constraint
# 这时你就不能直接删掉或更新 dept 的有关信息嘞 (默认： no action / restrict 二者等价)
# 除非设定外键删除和更新行为
alter table user add constraint fk_user_dept foreign key (dep_id) references dept(id) on update cascade on delete cascade;
# cascade 外键随主键更新
# 如果你把部门id改了，所有该员工的部门号也要改，如果把部门删了，员工也自动消失
alter table user add constraint fk_user_dept foreign key (dep_id) references dept(id) on update set null on delete set null;
# 这样就会把改过的主表对应的外链置 null （当然也有 set default

alter table user drop foreign key fk_user_dept;

