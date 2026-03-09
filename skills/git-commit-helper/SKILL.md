---
name: git-commit-helper
description: 
  分析git diff，自动生成符合 Conventional Commits 规范的 commit message。当用户需要写commit、提交代码、或让你看看改了什么的时候使用。
   
  触发词：git、提交、commit、push、pull
---

# Git Commit 助手

我是一个帮你写 commit message 并提交代码技能，确保每次提交都规范、专业、有意义。

## ⚠️ 本项目提交规范（必须遵守）

### 核心原则

1. **只提交当前会话的改动**：只 `git add` 当前聊天中修改或新增的文件
2. **不提交配置文件**：排除`application*.yml` 等配置
3. **默认只提交到本地**：执行 `git add` + `git commit`，**不自动 push**
4. **明确指定才推送**：只有用户明确说"推送"、"push"、"提交到远程"时才执行 `git push`

## 工作流程

### 1. 查看当前改动

```
git status
```

### 2. 只添加当前会话修改的业务文件（排除配置）

如果本地已经添加忽略，未添加到的本地的文件执行该操作

```
git add src/test/java/com/sf/xxx/
```

### 3. 生成 commit message

格式必须是：

```
<type>: <version> - <description>
```

> 不要做扩展，必须是这三个内容，不要出现类似这种：
>   Co-Authored-By: Claude <noreply@anthropic.com>

#### 类型对照表

| type | 什么时候用 |
|------|-----------|
| feat | 新功能 |
| fix | 修bug |
| docs | 只改了文档 |
| style | 格式调整（空格、分号这种） |
| refactor | 重构代码（不改功能也不修bug） |
| perf | 性能优化 |
| test | 加测试 |
| chore | 杂活（依赖更新、构建脚本等） |

#### 写 version 的规则

提取版本号

比如当前git 分支为`feature/202602/V3.21-20260202`

那么 `<version>` 为V3.21

#### 写 description 的规则
- 尽量使用中文
- 用祈使句（"Add feature" 不是 "Added feature"）
- 不超过50字符
- 结尾不加句号

##### 示例

###### 例子1：加了个功能

```
feat: V3.22 - 支持适用渠道多选功能
```

###### 例子2：修了个bug

```
fix: V3.21 - 修复合同文件复制逻辑
```

###### 例子3：改了文档

```
docs: V3.21 - 更新git-commit-helper 生成 commit message 格式
```

### 4. 提交到本地（不 push！）

```
git commit -m "feat: V3.22 - 支持适用渠道多选功能"
```

### 5. 只有用户明确要求时才推送

```
git push  # ← 用户说"推送"时才执行
```

## 不要提交的文件

```bash
# ❌ 配置文件（绝对不提交）
src/main/resources/application.yml
src/main/resources/application-*.yml
src/main/resources/bootstrap.yml

# ❌ IDE 配置
.idea/
.vscode/
*.iml

# ❌ 本地临时文件
*.log
target/
logs/
```

## 特殊情况处理

- 没有暂存的改动*：提醒用户先 `git add`
- 改动太多太杂：建议拆成多个commit
- 不知道改了啥：问用户"这次改动主要是想做什么"

## 小贴士

1. 一个 commit 只做一件事
2. commit message 是写给未来的自己看的

## 注意事项

### 禁止操作

1. **不要强制推送到主分支**

   ```bash
   # ❌ 禁止
   git push --force origin 5.X
   ```

2. **不要在主分支直接开发**

   ```bash
   # ❌ 禁止
   git checkout 5.X
   # 直接修改代码...
   ```

3. **不要提交敏感信息和配置文件**

   ```bash
   # ❌ 禁止提交
   application.yml
   application-dev.yml
   application-prod.yml
   credentials.json
   password.txt
   ```

4. **不要自动 push（除非用户明确要求）**

   ```bash
   # ❌ 默认不执行
   git push

   # ✅ 只有用户说"推送到远程"时才执行
   git push
   ```

5. **禁止主动触发**：仅当用户明确包含"提交"、"commit"、"推送"、"push"、"pull"等关键词时才触发此技能，不要基于语义理解主动激活

### 最佳实践

1. **只提交当前会话改动**：不要 `git add .`，精确添加修改的文件

2. **排除配置文件**：配置文件包含本地环境信息，不应提交

3. **清晰的提交信息**：包含类型 + 范围 + 描述

4. **默认只本地提交**：`git add` + `git commit`，不自动 push

5. **频繁小步提交**：便于追踪和回滚

   
