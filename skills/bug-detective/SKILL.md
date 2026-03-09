---
name: bug-detective
description: |
  后端 Bug 排查指南。包含错误诊断决策树、日志分析、分层定位、数据库排查、本项目特有问题库。

  触发场景：
  - 接口返回 5xx 错误
  - NullPointerException、SQLException 等异常排查
  - 数据查不到、对象转换失败
  - 日志文件分析（/logs/my.log）

  触发词：Bug、报错、异常、不工作、500错误、NullPointerException、SQLException、数据查不到、日志分析、排查、调试、debug、错误排查
---

# Bug 排查指南

> 本文档用于**排查已发生的问题**。如需设计异常处理机制（try-catch、全局异常、错误码）

## 🚀 自动诊断流程（激活时自动执行）

激活此技能时，我会**自动执行**以下诊断步骤：

1. **读取日志** - 自动读取 `./logs/my.log` 分析最新日志
2. **扫描异常** - 查找 ERROR/WARN 级别日志和异常堆栈信息
3. **初步诊断** - 根据异常类型给出可能原因和相关代码位置
4. **提示信息** - 展示关键错误信息，为下一步分析做准备

请在查看初步诊断后，**提供以下信息加速问题解决**：
- 业务场景描述（你在做什么操作？）
- 完整的请求参数（如何复现？）
- 预期结果 vs 实际结果（应该怎样 vs 实际怎样）

---

## 问题类型速查表

| 问题类型 | 表现现象 | 排查方式 | 涉及层级 | 相关 Skill |
|---------|--------|--------|--------|----------|
| **接口 5xx 错误** | 服务端返回 500 | 读日志、打断点 | 后端全层 | bug-detective |
| **数据查不到** | 查询条件错误、租户隔离 | 执行 SQL 验证 | Service/Mapper 层 | bug-detective |

---

## 快速诊断入口

> **描述你的问题，根据关键词快速定位。如果用户没有提明确的问题，直接读取文件**`./logs/my.log`分析

### 错误关键词索引

| 关键词/现象 | 可能原因 | 跳转章节 |
|------------|---------|---------|
| `NullPointerException` | 对象为空 | [#NPE 排查](#1-nullpointerexception) |
| `SQLException` / `SQL 语法` | SQL 错误 | [#SQL 异常](#2-sql-异常) |
| `404` / `接口不存在` | URL 路径错误 | [#接口调用失败](#1-接口调用失败) |
| `500` / `服务器错误` | 后端异常 | [#日志分析](#日志分析) |·
| `like 报错` / `MySqlSQL 类型错误` | like 仅限 String 类型 | [#like 方法类型限制](#3-like-方法类型限制) |


---

## 问题诊断决策树

### 接口返回错误

```
接口返回错误
├─ 状态码 4xx
│  ├─ 400 → 请求参数格式/类型错误
│  │         检查：@RequestBody/@RequestParam、参数名称、类型
│  └─ 404 → 接口路径不存在
│            检查：@RequestMapping 路径、Controller 是否扫描到
│
├─ 状态码 500
│  ├─ 控制台有堆栈 → 根据异常类型定位
│  │   ├─ NullPointerException → 对象未初始化/查询返回 null
│  │   ├─ SQLException → SQL 语法/字段名错误
│  │   ├─ ServiceException → 业务逻辑主动抛出
│  │   └─ 其他异常 → 查看具体异常信息
│  └─ 无堆栈信息 → 检查全局异常处理器是否吞掉了异常
│
└─ 状态码 200 
```

---

## 分层定位指南

### 快速判断问题在哪一层

```
步骤 1：用 Postman/curl 直接调接口
├─ 返回正确数据 → 问题在【前端】
└─ 返回错误 → 问题在【后端】

步骤 2（后端问题）：打断点或加日志
├─ Controller 收到请求 → 问题在 Service/Mapper
├─ Controller 没收到 → URL 路径/扫描问题
└─ Controller 参数为空 → 请求参数传递问题

步骤 3（后端问题）：在数据库直接执行 SQL
├─ 有数据 → 查询条件构建问题（Service 层 buildQueryWrapper）
└─ 无数据 → 数据本身不存在/租户问题
```

### 各层常见问题速查

| 层级 | 常见问题 | 排查重点 |
|------|---------|---------|
| **Controller** | 参数绑定失败、路径 404 | `@RequestMapping`、`@RequestBody`、`@PathVariable` |
| **Service** | 业务逻辑错误、事务回滚、查询条件不对 | `@Transactional`、`buildQueryWrapper`、业务校验逻辑 |
| **Mapper** | SQL 语法、字段映射、类型转换 | `@TableName`、`@TableField`、XML SQL、字段类型匹配 |

---

## 后端问题排查

### 常见错误类型

#### 1. NullPointerException

**原因**: 对象为 null 时调用方法或属性

**排查**:
```java
// 检查可能为 null 的位置
User user = baseMapper.selectById(id);  // 可能返回 null
user.getName();  // 如果 user 为 null 则报错

// 修复
if (user == null) {
    throw new ServiceException("用户不存在");
}
```

**本项目常见场景**:
- `baseMapper.selectById(id)` 返回 null
- `MapstructUtils.convert()` 源对象为 null
- 链式调用中间某环节为 null

#### 2. SQL 异常

**常见原因**:
- 字段名/表名错误
- SQL 语法错误
- 数据类型不匹配
- 唯一键冲突

**排查**:
```sql
-- 检查表是否存在
SHOW TABLES LIKE 'b_xxx';

-- 检查字段是否存在
DESC b_xxx;

-- 直接执行 SQL 查看错误
SELECT * FROM b_xxx WHERE id = 1;

-- 检查唯一键冲突
SELECT * FROM b_xxx WHERE unique_field = 'value';
```

#### 3. 事务问题

**表现**: 数据不一致、部分成功

**排查**:
```java
// 1. 检查是否添加事务注解
@Transactional(rollbackFor = Exception.class)

// 2. 检查是否有嵌套事务（默认 REQUIRED 传播）
// 3. 检查异常是否被 try-catch 吞掉
try {
    // 操作
} catch (Exception e) {
    log.error("错误", e);  // ❌ 异常被吞掉，事务不回滚
    throw e;  // ✅ 需要重新抛出
}

// 4. 检查是否在非 public 方法上使用（不生效）
@Transactional  // ❌ private 方法不生效
private void doSomething() {}
```

### 日志分析

**日志位置**: 控制台输出 / 日志文件

**关键信息**:
```
1. 异常类型: NullPointerException, SQLException...
2. 异常信息: 具体错误描述
3. 堆栈信息: 定位到具体代码行（at com.sf.xxx.xxx.XxxService:123）
4. 请求参数: 检查入参是否正确
```

**添加调试日志**:
```java
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class XxxServiceImpl implements IXxxService {
    public void doSomething(Long id) {
        log.info("开始处理, id: {}", id);
        // ...
        log.debug("中间状态: {}", state);
        log.info("处理完成, 结果: {}", result);
    }
}
```

### 日志文件分析（开发环境 - 重点！）

> **⭐ 新增能力**：开发环境现已配置日志文件，AI 可以直接读取分析！

#### 日志文件位置

**开发环境（非 prod）**：
- `./logs/my.log` - 本次启动的完整日志（控制台输出）
  - 包含：INFO、WARN、ERROR 所有级别日志
  - 包含：SQL 日志、业务日志、系统日志
  - 格式：`<property name="STANDARD_LOG_PATTERN" value="%d{yyyy-MM-dd'T'HH:mm:ss.SSSZ}|%p|%t|%c|%X{traceId}|%m%ex%n" />`
    解析每个占位符的含义：
    1、%d{yyyy-MM-dd'T'HH:mm:ss.SSSZ}：日期时间，格式为年-月-日'T'时:分:秒.毫秒时区，例如2023-10-05T14:30:00.123+0800。
    2、%p：日志级别，如DEBUG、INFO、WARN、ERROR等。
    3、%t：当前线程名。
    4、%c：日志记录器名称，通常是类名。
    5、%X{traceId}：从MDC（Mapped Diagnostic Context）中获取键为traceId的值，用于分布式链路追踪。
    6、%m：日志消息。
    7、%ex：异常信息，如果有的话。
    8、%n：换行符。
    示例：
    2025-11-14T10:40:58.756+0800|DEBUG|http-nio-8001-exec-24|com.sf.contract.mapper.ContractQueryMapper.selectOne|18facf310d804b66b7f52e78518f9b32|==> Parameters: 25102116502959(String)|[TID:65e9b3dd9eff44e8843d8ac78fea15a7.392.17630880586730159]|

#### AI 自动读取日志流程（必须执行）

**触发条件**（满足任一即读取日志）：
1. 用户报告问题但未提供错误堆栈
2. 需要分析 SQL 执行情况
3. 需要查看业务流程日志
4. 需要定位异常发生的时间点
5. 用户说"看日志"、"分析日志"、"日志里有什么"

**执行步骤**：
```bash
# 步骤 1：读取最新日志（开发环境）
Read ./logs/my.log

# 步骤 2：分析日志内容
# - 查找 ERROR/WARN 级别日志
# - 定位异常堆栈信息
# - 分析 SQL 执行耗时
# - 检查业务逻辑流程

# 步骤 3：给出诊断结果和解决方案
```

#### 日志内容识别规则

**日志格式**：
```
2026-03-04T17:17:43.561+0800|INFO|main|com.alibaba.nacos.plugin.auth.spi.client.ClientAuthPluginManager||[ClientAuthPluginManager] Load ClientAuthService com.alibaba.nacos.client.auth.impl.NacosClientAuthServiceImpl success.
2026-03-04T17:17:43.562+0800|INFO|main|com.alibaba.nacos.plugin.auth.spi.client.ClientAuthPluginManager||[ClientAuthPluginManager] Load ClientAuthService com.alibaba.nacos.client.auth.ram.RamClientAuthServiceImpl success.
2026-03-04T17:17:44.455+0800|ERROR|main|org.springframework.boot.SpringApplication||Application run failedjava.lang.IllegalStateException: Logback configuration error detected: 
ERROR in ch.qos.logback.core.rolling.RollingFileAppender[CONFIG_LOG_FILE] - 'File' option has the same value "/Users/01450358/logs/nacos/config.log" as that given for appender [CONFIG_LOG_FILE] defined earlier.
```

**关键信息提取**：
| 信息类型 | 提取规则 | 用途 |
|---------|---------|------|
| **异常堆栈** | `ERROR` + 多行异常信息 | 定位错误原因 |
| **SQL 日志** | `INFO p6spy` | 分析查询性能、SQL 语法 |
| **业务流程** | `INFO/WARN` + 业务 Logger | 理解执行流程 |
| **执行耗时** | `Cost: X ms` | 性能分析 |
| **请求参数** | 日志中的参数输出 | 检查输入数据 |

#### 常见日志分析场景

**场景 1：接口报 500 错误**
```bash
# 1. 读取日志
Read ./logs/my.log

# 2. 搜索 ERROR 关键字
grep "ERROR" ./logs/my.log | tail -2000

# 3. 定位异常类型（NullPointerException/SQLException等）
# 4. 查看堆栈信息，定位到具体代码行
# 5. 给出解决方案
```

**场景 2：查询慢/性能问题**
```bash
# 1. 读取日志
Read ./logs/my.log

# 2. 查找 SQL 日志

# 3. 分析 Cost 耗时
# - Cost < 50ms → 正常
# - Cost 50-200ms → 需要关注
# - Cost > 200ms → 需要优化

# 4. 检查是否有 N+1 查询
# 5. 给出优化建议（添加索引/使用批量查询）
```

**场景 3：功能不工作/无报错**
```bash
# 1. 读取完整日志
Read ./logs/my.log

# 2. 按时间顺序查看业务流程日志
# 3. 定位哪一步没有执行或逻辑分支错误
# 4. 检查是否有 WARN 级别的警告
# 5. 分析可能的原因
```

**场景 4：租户数据问题**
```bash
# 1. 读取日志中的 SQL
# 2. 检查 SQL 中的 tenant_id 条件
# 3. 对比数据库实际数据
# 4. 给出解决方案
```

#### 日志分析最佳实践

1. **优先读取日志文件**
   - ✅ 日志文件包含完整上下文（SQL + 业务逻辑）
   - ✅ 可以看到时间顺序和执行流程
   - ✅ 比用户描述更准确

2. **结合代码分析**
   - 从日志找到出错代码行号
   - Read 对应的代码文件
   - 分析代码逻辑

3. **时间线分析**
   - 按时间顺序查看日志
   - 理解请求的完整生命周期
   - 定位哪一步出现问题

4. **SQL 性能分析**
   - 关注 Cost 超过 200ms 的 SQL
   - 检查是否有重复查询
   - 建议添加索引或优化查询

#### 示例：完整的日志分析流程

```
用户问题：接口返回 500，但不知道原因

AI 执行：
1. Read /logs/my.log
   → 发现最后一个 ERROR：NullPointerException at XxxService.java:45

2. Read src/main/java/com/sf/xxx/xxx/service/impl/XxxServiceImpl.java:45
   → 代码：user.getName()

3. 分析日志中的 SQL
   → 发现 SELECT * FROM sys_user WHERE id = 999 返回空

4. Bash 连接数据库验证
   → 确认 ID 999 的用户不存在

5. 给出诊断结果：
   - 原因：用户不存在时，代码未判空
   - 解决方案：添加 null 检查或改用 Optional
```

#### 日志文件维护说明

**自动清空机制**：
- 开发环境日志保留 1 天（`my.log`）
- 保证日志只包含本次运行的内容
- 方便 AI 分析，无历史干扰

**如需保留历史日志**：

```bash
# 重启前备份日志
cp /logs/my.log /logs/my-$(date +%Y%m%d-%H%M%S).log
```

**日志过大处理**：
```bash
# 只查看最后 3000 行
Read ./logs/my.log (offset: -3000)

# 或使用 tail 命令
tail -n 3000 ./logs/my.log
```

---

## 本项目特有问题库（重点！）

### 1. 查询条件不生效

```java
// ❌ 错误：忘记添加条件判断（null/空字符串时也拼接条件）
private LambdaQueryWrapper<Xxx> buildQueryWrapper(XxxBo bo) {
    LambdaQueryWrapper<Xxx> lqw = Wrappers.lambdaQuery();
    lqw.eq(Xxx::getStatus, bo.getStatus());  // ❌ status 为 null 时会报错或查不到数据
    lqw.like(Xxx::getName, bo.getName());    // ❌ name 为空时会拼接 LIKE '%%'
    return lqw;
}

// ✅ 正确：在 Service 实现类的 buildQueryWrapper 中添加条件判断
@Service
@RequiredArgsConstructor
public class XxxServiceImpl implements IXxxService {
    private final XxxMapper baseMapper;

    private LambdaQueryWrapper<Xxx> buildQueryWrapper(XxxBo bo) {
        LambdaQueryWrapper<Xxx> lqw = Wrappers.lambdaQuery();
        lqw.eq(bo.getStatus() != null, Xxx::getStatus, bo.getStatus());
        lqw.like(StringUtils.isNotBlank(bo.getName()), Xxx::getName, bo.getName());
        return lqw;
    }

    @Override
    public List<XxxVo> list(XxxBo bo) {
        LambdaQueryWrapper<Xxx> wrapper = buildQueryWrapper(bo);
        return baseMapper.selectVoList(wrapper);
    }
}
```

**排查场景**：
- 查询条件不生效（缺少条件判断）
- 分页查询结果不对（条件构建错误）
- 搜索功能不工作（like 条件处理错误）

### 2. 租户数据问题

```sql
-- 检查数据是否在当前租户下
SELECT * FROM b_ad WHERE id = 1 AND tenant_id = '000000';

-- 检查请求头中的 tenant-id 是否正确传递
-- 前端需要在请求头中添加：
-- tenant-id: 000000
```

```java
// 检查 Entity 是否继承 TenantEntity
// ❌ 错误：继承 BaseEntity（无租户隔离）
public class Xxx extends BaseEntity { ... }

// ✅ 正确：继承 TenantEntity（有租户隔离）
public class Xxx extends TenantEntity { ... }
```

**排查场景**：
- 数据明明存在但查询不到
- 不同租户数据串了
- 新增数据没有 tenant_id

### 3. like 方法类型限制

> ⚠️ **like() 方法应仅用于 String 类型字段！非 String 类型应使用精确匹配方法。**

```java
// ❌ 错误：对非 String 类型使用 like
lqw.like(Xxx::getId, searchValue);          // ❌ Long 类型不适合模糊匹配
lqw.like(Xxx::getCreateTime, searchValue);  // ❌ Date 类型不适合模糊匹配

// ✅ 正确：like 仅用于 String 类型字段
lqw.like(StringUtils.isNotBlank(bo.getName()), Xxx::getName, bo.getName());  // ✅ String

// ✅ 非 String 类型使用 eq/in/between 等精确匹配
lqw.eq(bo.getId() != null, Xxx::getId, bo.getId());  // ✅ Long → eq
lqw.between(params.get("beginTime") != null && params.get("endTime") != null,
    Xxx::getCreateTime, params.get("beginTime"), params.get("endTime"));  // ✅ Date → between
```

**规则**：
| 字段类型 | 推荐方法 | 说明 |
|---------|---------|------|
| `String` | `like()` | 模糊匹配 |
| `Long/Integer` | `eq()`/`in()` | 精确匹配 |
| `Date/LocalDateTime` | `between()`/`ge()`/`le()` | 范围查询 |

**框架示例**（参考 `SysUserServiceImpl.java`）：
```java
.like(StringUtils.isNotBlank(user.getUserName()), SysUser::getUserName, user.getUserName())
.like(StringUtils.isNotBlank(user.getNickName()), SysUser::getNickName, user.getNickName())
.like(StringUtils.isNotBlank(user.getPhonenumber()), SysUser::getPhonenumber, user.getPhonenumber())
```

## 数据库问题排查

### 主动排查流程（AI 自动执行）

> **重要**：当排查涉及数据问题时，AI 应主动连接数据库进行验证，而不只是给出 SQL 让用户执行。

#### 步骤 1：使用MCP连接数据库执行查询

#### 步骤 2：根据结果分析问题

```
查询结果分析决策树：
├─ 返回数据
│  ├─ 数据正确 → 问题不在数据库，转查代码
│  ├─ 数据不对 → 分析哪个字段有问题
│  └─ 数据被删除（del_flag='1'）→ 数据已逻辑删除
├─ 无数据返回
│  ├─ 检查 tenant_id → 是否租户不匹配
│  ├─ 检查 del_flag → 是否被删除
│  └─ 检查 ID 值 → 是否 ID 错误
└─ 执行报错
   ├─ 表不存在 → 检查表名/数据库
   ├─ 字段不存在 → 检查字段名
   └─ 语法错误 → 检查 SQL 语法
```

### 常用排查 SQL 模板

#### 数据存在性检查

```sql
-- 基础检查
SELECT * FROM [表名] WHERE id = [ID值];

-- 含租户和逻辑删除检查
SELECT * FROM [表名] WHERE id = [ID值] AND tenant_id = '000000' AND del_flag = '0';

-- 检查最近的数据
SELECT * FROM [表名] ORDER BY create_time DESC LIMIT 10;
```

#### 数据关联检查

```sql
-- 检查关联数据
SELECT a.*, b.*
FROM table_a a
LEFT JOIN table_b b ON a.id = b.a_id
WHERE a.id = [ID值];

-- 检查外键引用
SELECT * FROM [子表] WHERE [外键字段] = [主表ID];
```

#### 性能问题检查

```sql
-- 查看执行计划
EXPLAIN SELECT * FROM [表名] WHERE [条件];

-- type 字段说明：
-- ALL = 全表扫描（需要优化）
-- index = 索引扫描
-- range = 范围扫描
-- ref = 使用索引
-- const = 常量查询（最优）

-- 检查索引
SHOW INDEX FROM [表名];

-- 检查表结构
DESC [表名];
SHOW CREATE TABLE [表名];
```

### 场景化排查指南

| 问题场景 | 排查 SQL | 说明 |
|---------|---------|------|
| 数据查不到 | `SELECT * FROM 表 WHERE id=? AND tenant_id='000000' AND del_flag='0'` | 检查三要素 |
| 权限不足 | `SELECT perms FROM sys_menu WHERE menu_id IN (SELECT menu_id FROM sys_role_menu WHERE role_id=?)` | 检查角色权限 |
| 字典不显示 | `SELECT * FROM sys_dict_data WHERE dict_type=?` | 检查字典数据 |
| ID 重复 | `SELECT id, COUNT(*) FROM 表 GROUP BY id HAVING COUNT(*) > 1` | 检查重复数据 |
| 关联数据丢失 | `SELECT a.id FROM 主表 a LEFT JOIN 子表 b ON a.id=b.主表id WHERE b.id IS NULL` | 检查孤立数据 |

## 常见问题速查表

| 问题 | 可能原因 | 解决方案 |
|------|---------|---------|
| 接口 404 | URL 错误 / 后端未启动 | 检查 URL，重启后端 |
| 接口 500 | 后端代码异常 | 查看后端控制台日志 |
| 数据为空 | 条件错误 / 数据不存在 | 检查 SQL 条件 |
| 租户数据查不到 | tenant_id 不匹配 | 检查请求头 tenant-id |
| like 报错 | 非 String 类型 | 改用 eq/in/between |
| 事务不回滚 | 异常被吞 / 非 public 方法 | 检查 @Transactional 使用 |
| Bean 注入失败 | 未加注解 / 包路径错误 | 检查 @Service 和包路径 |

---

## 调试建议

1. **保持冷静**: 不要急于修改代码
2. **复现问题**: 确保问题可以稳定复现
3. **二分法**: 逐步缩小问题范围
4. **看日志**: 日志是最重要的线索
5. **查文档**: 确认 API 用法是否正确
6. **搜索**: 错误信息通常能搜到解决方案
7. **最小复现**: 创建最小示例复现问题

---

### 数据库直连排查（内置能力，无需激活其他技能，使用MCP）

当遇到以下情况时，**直接读取配置并连接数据库**：

| 问题类型 | 排查 SQL |
|---------|---------|
| 数据查不到 | `SELECT * FROM 表名 WHERE id = ? AND tenant_id = '000000' AND del_flag = '0'` |
| 数据不一致 | `SELECT * FROM 关联表 WHERE 外键 = ?` |
| 权限报错 | `SELECT * FROM sys_menu WHERE menu_id = ?` |
| 字典不显示 | `SELECT * FROM sys_dict_data WHERE dict_type = '?'` |
| 性能问题 | `EXPLAIN SELECT ...` |

**执行流程**：

```
执行诊断 SQL → 分析结果给出方案
```

---

## 排查流程决策树（完整版）

### 判断问题在哪一层

```
现象：功能不工作、数据不正确、接口返回错误
     ↓
第 1 步：用 Postman 或浏览器直接调接口
     ├─ 返回正确数据 → 问题在【前端层】
     │  └─ 检查：@RestController 路径、@Validated、参数绑定
     │
     └─ 返回错误（4xx/5xx） → 问题在【后端层】
        └─ 进入"后端问题排查流程"（见下）

后端问题排查流程：
     ↓
第 2 步：读取 ./logs/my.log（开发环境）
     ├─ 有 ERROR 日志 → 查看堆栈信息
     │  ├─ NullPointerException → 对象未初始化或查询返回 null
     │  ├─ SQLException → SQL 字段/表名/语法错误
     │  ├─ ServiceException → 业务逻辑主动抛出异常
     │  └─ 其他异常 → 根据具体异常信息定位
     │
     └─ 无 ERROR 日志或日志看不出问题 → 进入"分层定位"
        └─ 第 3 步：打断点或加日志（按调用链向下）
           ├─ Controller 收到请求，参数正确 → 问题在 Service/Mapper
           ├─ Controller 没收到请求 → URL 路径/扫描问题
           └─ Controller 参数为空 → 请求参数传递问题

分层定位（从上到下）：
     Controller 层：检查 @RequestMapping、@RequestBody、参数类型
          ↓ 参数正确
     Service 层：检查业务逻辑、@Transactional、数据转换
          ↓ 逻辑正确
     Mapper 层（查询构建）：检查 buildQueryWrapper、查询条件、字段类型匹配
          ↓ 条件正确
     Mapper 层：检查 SQL 语句、字段映射、表名
          ↓ SQL 正确
     数据库：直接执行 SQL 验证数据
```

---

## 排查清单

### 后端排查清单

- [ ] **是否读取了日志文件？** (`./logs/my.log`)
- [ ] **异常堆栈中的类名包名是否为 `com.sf.*`？**
- [ ] **是否检查了 Controller 的 @RequestMapping 路径？**
- [ ] **参数绑定是否使用了 @RequestBody/@RequestParam？**
- [ ] **Service 的 buildQueryWrapper 中是否正确构建查询条件？**
- [ ] **非字符串字段是否使用了 eq/in/between 而不是 like？**
- [ ] **返回值类型是否符合规范？（LIST→TableDataInfo, GET→R<T>, EXPORT→void）**
- [ ] **数据库中是否真的存在需要的数据？（SQL 验证）**

---

## 最佳实践

### 1. 日志优先原则

```
问题出现 → 【立即读取日志】→ 95% 的问题能在日志中找到根本原因
```

**为什么日志最重要**：
- ✅ 包含完整的执行上下文（时间、线程、SQL）
- ✅ 不依赖用户的口头描述
- ✅ 可以看到时间顺序和流程
- ✅ SQL 日志显示实际执行的 SQL 和耗时

### 2. 分层排查原则

不要一上来就改代码，要按这个顺序排查：
1. **外部因素**：数据库连接、请求参数、权限配置
2. **日志分析**：找堆栈、定位异常类型
3. **代码路径**：从 Controller 开始向下逐层检查
4. **数据库验证**：直接执行 SQL 对比实际数据

### 3. 重现问题原则

不能稳定重现的问题很难排查，所以：
- ✅ 找到稳定复现的步骤
- ✅ 记录每一步的输入和输出
- ✅ 隔离变量（先排除前端，再排除中间件）

### 4. 代码版本原则

修改代码前：
- ✅ 理解问题的根本原因
- ✅ 制定解决方案
- ✅ 再进行修改

不要：
- ❌ 盲目改代码希望能解决问题
- ❌ 加一堆 try-catch 来"压制"错误
- ❌ 重复修改同一个地方

---

## 常见误区

| 误区 | 错误做法 | 正确做法 |
|------|--------|--------|
| 日志没看 | 直接改代码 | 先读日志找原因 |
| 包名错 | 使用 `com.sf.*` | 必须 `com.sf.*` |
| 查询构建 | new LambdaQueryWrapper 直接用 | Service 层 buildQueryWrapper 方法 |
| like 方法 | Long/Date 字段用 `.like()` | 必须用 `.eq()`/`.between()` |
| Bean 扫描 | 其他包路径 | 必须 `com.sf.*` |

---

## 快速参考

### 常见错误速查

```
NullPointerException         → 对象为空，加 null 检查
SQLException                → SQL 错误，检查字段/表名
ClassNotFoundException       → 类未找到，检查包路径
404 Not Found              → 路径错误，检查 @RequestMapping
500 Internal Server Error  → 服务异常，读日志
like 报错                  → 非字符串用 eq/in/between
```

