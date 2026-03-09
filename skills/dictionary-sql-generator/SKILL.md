---
name: dictionary-sql-generator
description: |
  数据字典 SQL 生成助手，连接数据库生成标准化的 INSERT 语句。

  触发场景：
  - 新增字典项需要快速生成 SQL 语句
  - 查询现有表结构，自动补充新字典项

  触发词：字典SQL、数据字典生成sql
---

# 数据字典 SQL 生成助手

## 概述

`dictionary-sql-generator` 是为工具技能，用于快速生成标准化的数据字典 INSERT SQL 语句。

## 文档结构

```
  dictionary-sql-generator/                                                 
  ├── SKILL.md                                             # 技能定义和说明文档  
  └── assets/                                                                 
      └── tbl_signed_document_recovery表数据字典sql示例.sql  # 示例 SQL 输出  
```

## 工作流程

```
必须在控制台输出以下日志：
第零部：使用/mcp list查用可用的MCP
第一步：使用mcp_server_mysql连接数据库读取表结构
第1.5步：向用户确认哪些字典需要生成
第二步：自动分析并生成字典配置
第三步：SQL 生成输出
```

### 第零部：mysql mcp确认

/mcp list查询所有mcp，没有mcp_server_mysql提醒用户安装

### 第一步：连接数据库读取表结构（⚠️强制使用）

用户提供表名，如 `tbl_signed_document_recovery`

**执行流程（必须按顺序执行，不允许跳过）：**

1. **【强制】调用 mcp_server_mysql 工具查询表结构**
   - 执行 `SHOW CREATE TABLE [表名]` 获取完整的表定义和注释
   - 不允许跳过此步或用其他方式替代（如查看实体类）
2. **解析表结构**，识别所有列（column_name、column_type、column_comment 等）
3. **自动识别关键字段**：
   - 状态字段（status、state 等）→ 创建字典类别
   - 枚举类型字段 → 创建字典项
   - 注释中包含枚举值 → 自动提取可选值

### 第1.5步：向用户确认哪些字典需要生成（⚠️强制确认）

**执行流程（必须按顺序执行）：**

1. **解析表结构后生成候选字典列表**
   - 将所有自动识别出的字典字段列出
   - 包含字段名、字段类型、注释、建议的字典类别名称

2. **使用 AskUserQuestion 工具向用户确认**
   - 显示所有候选字典字段（多选）
   - 用户可勾选需要生成的字典字段
   - 用户可取消或修改建议的字典名称

3. **等待用户反馈**
   - 用户确认选择后，才能继续执行第二步
   - 不允许跳过确认步骤直接生成 SQL

**示例确认对话：**
```
根据表结构分析，识别以下字段可生成字典：
- recovery_status（字段类型: VARCHAR）：建议字典名称"回收状态"
- enable_flag（字段类型: INT）：建议字典名称"启用标志"
- sync_status（字段类型: VARCHAR）：建议字典名称"同步状态"

请勾选需要生成的字典 👇
☐ recovery_status - 回收状态
☐ enable_flag - 启用标志
☐ sync_status - 同步状态
```

### 第二步：自动分析并生成字典配置

根据用户确认的字典字段，自动生成：
1. **模块字典**：以表名的中文注释作为模块名
2. **类别字典**：仅为用户确认的字段创建
3. **项字典**：根据字段的枚举值或注释自动生成

**仅基于用户在第1.5步确认的字典字段生成** SQL 语句（跳过未被选中的字段）。

### 第三步：SQL 生成输出

生成标准格式的 INSERT 语句 , 参照 `.claude/skills/dictionary-sql-generator/assets/tbl_signed_document_recovery表数据字典sql示例.sql`

#### 格式要求

必须按照标准格式输出

✅正确示例

```
-- 1. 插入模块字典：xxx
-- 2.1 插入类别字典：xxx
-- 2.2 插入类别字典：xxx
-- 3.1 插入项字典: xxx
-- 3.1 插入项字典: xxx
```

❌不允许扩展更改，示例如下

```
  -- ============================================                  
  -- xxx - 数据字典 SQL
  -- ============================================     
  -- 1. 插入模块字典    
  -- 2. 插入类别字典：xxx
  -- 3. 插入类别字典：xxx
  -- ============================================
  -- 3.1 xxx项
  -- ============================================
  -- ============================================
  -- 3.2 xxx项
  -- ============================================
```

✅正确示例，只改内容

```
INSERT INTO ts_dictionary
(DIC_KEY, DIC_NAME, DESCRIPT, PARENT_ID, DIC_VALUE, SN, PKEY_PATH, STATUS, CREATE_BY, UPDATE_BY)
VALUES ('XXXCODE', 'XXXNAME', NULL, (SELECT t.DIC_ID
                                 FROM (SELECT DIC_ID
                                       FROM ts_dictionary
                                       WHERE DIC_KEY = 'PARENT的DIC_KEY'
                                         AND PKEY_PATH = 'PARENT的PKEY_PATH'
                                       LIMIT 1) t),
        '状态', 1, 'PARENT的PKEY_PATH.PARENT的DIC_KEY', 1, NULL, NULL);

```

❌不允许改变示例sql的语句

```
  SET @parent_id = LAST_INSERT_ID();
  INSERT INTO `ts_dictionary` (`dic_key`, `dic_name`, `descript`, `parent_id`, `dic_value`, `sn`, `pkey_path`, `status`, `create_by`, `update_by`, `create_time`,
  `update_time`, `del_flag`, `tenant_id`) VALUES ('XXXCODE', 'XXXNAME', NULL, @parent_id, '', 1, CONCAT('PARENT的PKEY_PATH.',
  'PARENT的DIC_KEY'), 1, NULL, NULL, NOW(), NOW(), 0, 0);
```

## 核心规则

### 序列号（sn）

- 同 `parent_id` 下的 sn 必须连续递增（从 1 开始）

### 路径（pkey_path）

- SysArguSetting是根key路径，PKEY_PATH中必须包含并且在左边
- 格式：`SysArguSetting` 或 `SysArguSetting.ELECTRIC_TERMS`、`SysArguSetting.ELECTRIC_TERMS.USE_SYSTEM`（多层级）
- 通过查询父字典的 pkey_path 组合得到
- 用于表示层级关系，便于前端展示树形结构

## 常见错误

## 注意

- 本技能仅生成 SQL 语句，不执行数据库操作，用户需自行在目标环境执行
- 生成的 SQL 使用具体值而非占位符，可直接执行

## 字段说明详见

项目中 `ts_dictionary` 表的定义：
```
dic_key: KEY
dic_name: 名称，默认用于展示的文字
descript: 描述信息
parent_id: 父字典 ID
dic_value: 字典值
sn: 序列号（排序用）
pkey_path: 节点Key的路径
status: 状态：无效0，有效1
create_by: 创建者用户账号
update_by: 更新者用户账号
```
