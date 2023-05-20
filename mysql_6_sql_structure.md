# 客户端连接器
# 服务端 -- 连接层（连接池、授权验证、安全等）
#          服务层（SQL接口、解析器、查询优化器、缓存）（核心功能，跨存储引擎的控制指令）
#          引擎层（可插拔存储引擎，负责数据的储存、索引、管理）（不同引擎有不同的功能和管理方法）
#          系统文件、日志（磁盘文件）

show create table emp;
show engines;

 create table myisam (
     id int
 ) engine = MyISAM;

# 默认为每一个表创建一个 innodb 表结构
show variables like 'innodb_file_per_table';

# 在 cmd 输入 ibd2sdi account.ibd 查看 ibd 文件
# innodb 的结构 : 表空间 tablespace - Segment 段 - Extent 区 - Page 页 - Row 行 ( trx id, roll ptr, col1, col2, ... )
# 有 ibd 文件

# MyISAM 是 MySQL 早期使用的默认引擎
# 不支持事务、外键、行锁，速度快
# 有多个文件，包括 sdi

# Memory
# 只能做临时表或缓存，断电丢失，大小有限
# 在内存中存放，支持 hash 索引，只有 sdi 一个文件

# 对比
#             Innodb      MyISAM      Memory
# 存储限制      64TB        有          有
# 事务安全      支持         -           -
# 锁           行锁         表锁        表锁
# B+ Tree     支持         支持        支持
# Hash idx      -           -         支持
# 空间使用      高           低          -
# 内存使用      高           低          中等
# 批量插入      慢           快          快
# 外键         支持          -          -

-- innodb 适用于事务（一般是核心业务）
-- myisam 适用于读取插入，更新删除较少，无事务需求（被mongob取代）
-- memory 速度快，数据小，临时缓存 （被redis取代）
