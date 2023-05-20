select concat('hello', 'MySQL');
select lower('Hello');
select upper('Hello');
select lpad('01', 5, '-');  # 在左边填充 '-' 直到长度为 5
select rpad('01', 5, '-');
select trim('   Hello  MySQL ');
select substring('hello MySQL', 2, 2);
# ==
select substr('hello MySQL', 2, 2) as hhb;

update hello_world.emp set workno = lpad(workno, 5, '0') where true;
select * from emp;

select ceil(1.5);
select floor(0.5);
select mod(7, 4);
select rand();  # 0~1
select round(2.3452, 2);  # 四舍五入保留两位

# 生成6位随机密码
select lpad(floor(rand()*1000000), 6, '0');
select substr(rand(), 3, 6);

select curdate();
select curtime();
select now();
select year(now());
select month(now());
select day(now());
select hour(now());
select minute(now());
select second(now());

select date_add(now(), interval 70 day);
select datediff('2023-07-20', curdate());

select * from (select *, datediff(curdate(), entrydate) duration from emp) as emp1 where duration > 20 order by duration;

select if(age > 20, 'OK', 'ERROR') from emp;
select ifnull(idcardno, 'niganma-aiyo') from emp;  # 替换 null 值

select
    name,
    case address when '北京' then '京✌' when '上海' then '沪✌' else '其他城市' end as 'address level'
from emp;

select  agelevel, count(name)
from (select name, case
    when age >= 50 then '你干嘛'
    when age >= 20 then '哎哟'
    else 'ikun'
    end as agelevel from emp) as emp1
group by agelevel;





