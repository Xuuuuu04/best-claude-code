---
name: cross-sync
description: 多端项目(web + miniapp + backend 等)跨端一致性检查 —— 读项目 CLAUDE.md 的 Cross-end Shared 段,列出 shared 目录下的 enums/constants/contracts,grep 各端代码看谁缺谁。漫展、眼科等 4/6 多端项目适用。
disable-model-invocation: true
context: fork
agent: Explore
argument-hint: "[enum 或 contract 名称（可选）]"
---

# /cross-sync

防止"web 改了枚举但 miniapp 没改"类的跨端不一致问题。这是多端项目最容易翻车的地方。

## 何时调用

- 用户在多端项目中改了 enum / constant / API contract
- 主代理在 PR 之前主动检查
- 多端项目第一次开 task 时,先跑一次 baseline
- 用户说 `/cross-sync` / "对一下各端"

## 前置条件

项目 CLAUDE.md 必须有 `## Cross-end Shared` 段,例如:

```markdown
## Cross-end Shared(被 /cross-sync skill 读取)

- 共享目录:shared/
- 各端目录:
  - web/src/
  - miniapp/src/
  - backend/src/main/java/...(或类似)
- 关键文件类型:.ts/.js 的 enums 和 constants;.json 的 schema
```

如果项目没有这段,引导用户先加:

```
项目 CLAUDE.md 缺 ## Cross-end Shared 段。
检测到这是个多端项目(发现:[web/, miniapp/, backend/])。
建议加一段(我已经草拟,你看):
[草稿]
```

## 执行步骤

### 1. 读配置

从项目 CLAUDE.md 提取:
- `SHARED_DIR`(共享目录路径)
- `ENDS`(各端目录列表)

### 2. 列出共享符号

在 SHARED_DIR 下找:
```bash
# 枚举(TypeScript enum / Python Enum / Java enum)
grep -rE "^export (enum|const)" $SHARED_DIR --include="*.ts" --include="*.js"
grep -rE "^class.*Enum" $SHARED_DIR --include="*.py"
grep -rE "public enum" $SHARED_DIR --include="*.java"

# 常量
grep -rE "^export const [A-Z_]+" $SHARED_DIR --include="*.ts" --include="*.js"

# JSON schema 文件
find $SHARED_DIR -name "*.schema.json" -o -name "*-schema.json"

# API contract 文件
find $SHARED_DIR -name "*.contract.ts" -o -name "api-*.ts"
```

提取出符号名列表(枚举名、常量名、文件名)。

### 3. 在每端 grep 引用

对每个符号,在每个 END 目录 grep:

```bash
for SYMBOL in $SYMBOLS; do
  for END in $ENDS; do
    COUNT=$(grep -r "$SYMBOL" "$END" --include="*.ts" --include="*.js" --include="*.vue" -l | wc -l)
    echo "$END: $SYMBOL: $COUNT files"
  done
done
```

### 4. 生成报告

输出格式:

```
跨端一致性报告
================
共享目录:shared/
检查符号数:23

✓ 所有端都引用的(15):
  PaymentStatus, OrderType, TicketTier, ...

⚠️ 引用不平衡(5):
  - UserRole(web: 8 处, miniapp: 0 处)—— miniapp 未使用,可能漏改
  - PaymentMethod(web: 12 处, miniapp: 3 处, backend: 0 处)—— backend 是否对应?

✗ 仅一端引用(3):
  - LegacyStatus(web: 2 处)—— 是否过时未清?
  - DebugMode(miniapp: 1 处)—— 调试残留?

新增但未被任何端引用(0):
  (无)
```

### 5. 引导下一步

不要自动改代码 —— 这是检测工具,不是修复工具。输出:

```
建议:
- ⚠️ UserRole 在 miniapp 完全没用,确认是不是漏了
- 用 /brief + Edit subagent 修复其中一个不一致点
- 或在当前 Task Decisions 段记一笔"已知跨端差异 X 是有意为之"

是否需要我生成一个 brief 让 subagent 修复其中某一项?
```

如果在 Task 上下文中,在 Execution Log 加一行:
```markdown
- HH:MM /cross-sync:发现 5 处不平衡,3 处单端
```

## 项目特化模式

漫展(web + miniapp):
- SHARED_DIR = `shared/`
- ENDS = `web/`、`miniapp/`
- 重点检查 `shared/constants/enums.js`、`shared/copy/*.js`、`shared/crypto/*`

眼科(frontend + miniapp + backend):
- SHARED_DIR = (可能没有真正的 shared 目录,需要用户配置)
- ENDS = `frontend/`、`miniapp/`、`backend/src/main/java/`
- 重点检查 backend 的 enum 定义 vs 前端的 enum 引用

铝制B2B(单端):
- 不适用 —— 这个 skill 应该提示"非多端项目,无需 /cross-sync"

## 反例(别这样做)

- ❌ 自动改代码补齐缺失符号 —— 有些差异是有意为之,自动改会破坏
- ❌ 把所有"单端引用"都标红警告 —— 调试代码、平台特定代码合法
- ❌ 在非多端项目跑 —— 应该一眼判断退出
- ❌ 跨整个 monorepo grep 无关目录(node_modules、dist 等)

## 配置示例(用于参考,各项目自己加到 CLAUDE.md)

漫展项目的 `## Cross-end Shared`:
```markdown
## Cross-end Shared
- 共享目录:shared/
- 各端目录:web/src/、miniapp/src/
- 关键子目录:shared/constants/、shared/copy/、shared/crypto/、shared/utils/
- 排除路径:node_modules/、dist/、build/
```

眼科项目的(因为后端是 Java,需要特殊):
```markdown
## Cross-end Shared
- 共享目录:(无独立目录,跨端契约在 backend/src/main/java/.../enums/ 定义,前端 mirror)
- 各端目录:frontend/src/、miniapp/src/、backend/src/main/java/
- 检查模式:backend 的 enum class → 前端找同名 const/enum
- 备注:.env.example 也需要跨端同步
```
