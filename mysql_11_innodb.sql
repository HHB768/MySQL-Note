# 表空间 (.ibd) table space
# 段 segment: 数据段（叶子节点）、索引段（非叶子节点）、回滚段
# 区 Extent 大小 1M 默认有 64 个连续的数据页
# 页 Page 磁盘管理的最小单元 16k， 为了保证页的连续性，每次申请4-5个区
# 行 row 数据按行存放，有两个隐藏字段：trx_id 对数据进行改动时，将事务id赋给trx_id
#                               roll_pointer 改动时把旧版本写入到 undo 日志中，用该指针来指向修改前的信息

# innodb 的内存结构
-- buffer pool : 优先操作缓冲池的数据，再以一定的频率刷新到磁盘，从而减少磁盘 IO
--             : 以页为单位管理，采用链表的形式，页分为 free / clean / dirty 三种状态
-- change buffger : 非唯一二级索引的 DML 操作时如果没有在 buffer pool 中缓存，则将数据变更缓存在 change buffer
--                : 因为二级索引的插入删除一般是随机的，引入这个缓冲的缓冲以减少 io
-- adaptive hash index : 用于优化 buffer pool 数据的查询，如果 innodb 监控到表上的查询用 hash 可以加速，则自动打开
show variables like '%hash_index%';
-- log buffer : 日志缓冲区 默认 16 MB (redo log / undo log)
show variables like '%log_buffer%';
show variables like '%flush_log%';

# 磁盘结构
--
show variables like '%innodb_data%';

-- 不想看了，还有几节后面再说吧
