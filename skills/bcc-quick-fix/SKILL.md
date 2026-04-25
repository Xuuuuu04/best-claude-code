---
name: bcc-quick-fix
description: 轻量级快速修复流水线。用于 <20 行、单文件、无架构影响的小改动——typo、注释笔误、显然的单点 bug、小样式调整。默认由主会话直接完成，必要时再派遣 implementer。
disable-model-invocation: true
---

# 快速修复流水线（lite）

`$ARGUMENTS` 是修复描述，形如"修正 Login 组件的 label 拼写"。

完整流水线（`/bcc-new-feature` / `/bcc-fix-bug`）适合有架构影响或需要测试设计的任务。但大量日常修复是琐碎的：改错字、调 CSS 值、加一条 console.log、去掉一个多余 import。这些走 5 阶段属于杀鸡用牛刀。

此 Skill 是**单点直修**的通道：**跳过 product-analyst、architect、完整 reviewer/tester 链路**，默认由主会话直接完成；只有在需要隔离上下文或主会话无法安全判断时才派遣 implementer。

---

## 入口判断（重要）

在派遣前，用以下标准自检"这个任务真的适合 quick-fix 吗"？**任何一条不符就应转走完整流水线**：

- [ ] 改动预计 ≤ 20 行
- [ ] 改动集中在 **1 个文件**
- [ ] 不涉及**接口签名变更**
- [ ] 不涉及**数据库 schema**
- [ ] 不涉及**安全、权限、认证**
- [ ] 不引入**新依赖**
- [ ] 已经知道"改什么、怎么改"——这不是探索性任务

如果你（调度器）不确定是否符合，**默认走完整流水线**。宁可慢一步也不要用错工具。

---

## 执行

### Step 1: 微型 scope-lock（调度器自己写，不派 architect）

在对话中直接构造一个简短 scope-lock，不写入 artifact 文件：

```
白名单文件：
- src/components/Login.tsx（修正 label 拼写）

禁止：
- 不改动其他任何文件
- 不修改组件的 props/state 结构
- 不添加新依赖

完成标准：
- 拼写改正
- 运行 npm run typecheck 无新错
```

### Step 2: 选择执行方式

优先级如下：

1. **主会话直接修复（默认）**
   - 适用于 `~/.claude` 自身文件
   - 适用于单文件、边界明确、无需额外探索的小业务修复
   - 主会话直接按微型 scope-lock 修改并运行最小验证

2. **派遣 implementer（例外）**
   - 主会话对代码库不熟，读几处文件后仍不确定
   - 需要隔离上下文，避免污染主会话
   - 需要更强的领域实现约束（frontend / backend / mobile）

如需派遣，根据涉及文件类型选择：
- `.tsx` / `.vue` / `.css` / `.html` → `implementer-frontend`
- `.py` / `.go` / `.java` / 后端 `.ts` → `implementer-backend`
- `.swift` / `.kt` / `.dart` → `implementer-mobile`
- `.wxml` / `.wxss` / `.wxs` / `miniprogram` 目录 → `miniprogram-dev`

派遣时，**前台阻塞**运行，任务提示直接包含上一步的微型 scope-lock：

```
任务：快速修复。
描述：{$ARGUMENTS}

白名单路径（hook 会据此硬性拦截越界写入）：
{逐个列出文件路径}

完成后在对话里一句话汇报（不产出 artifact）：
- 具体改了什么
- 运行了哪个验证（typecheck / lint / test）
- 是否通过
```

### Step 3: 最小验证与汇报

无论由主会话还是 implementer 执行，都至少完成一项与改动最相关的验证：`typecheck` / `lint` / 单测 / 静态检查。

完成后，主会话用固定格式汇报给用户：

```
✓ 快速修复完成
  └ 路径：主会话直修 / implementer 派遣
  └ 文件：{路径}
  └ 改动：{一句话}
  └ 验证：{lint ✓ / typecheck ✓ / 测试 ✓}
```

---

## 中止条件（重要）

如果 implementer 报告：
- 改动超过 20 行，或
- 需要修改白名单外的文件（被 scope-lock-guard 拦截），或
- 发现其他相关 bug 需要一并处理

**立即停止 quick-fix**。向用户建议升级：

```
⚠ 任务超出 quick-fix 边界：{原因}

建议改走 /bcc-fix-bug（有需求分析、架构、审查） 或
/bcc-new-feature（完整流水线）。是否继续？
```

**不要**擅自"顺手"扩大改动。

---

## 不做代码审查是否安全？

`/bcc-quick-fix` 跳过完整 reviewer/tester 链路。安全性由以下轻量替代机制提供：

1. **微型 scope-lock**：先写清白名单、禁止事项、完成标准
2. **scope-lock-guard hook**：在支持环境变量注入的派遣场景下硬性阻止越界写入
3. **post-edit-lint hook**：自动跑 linter/formatter
4. **执行者自检**：至少跑一项最相关的验证
5. **用户可见性**：前台修复或前台派遣，用户看得到过程

对 20 行以内的单文件小改动，这套轻量保障**通常够用**。但以下情况宁可慢也要走完整流水线：
- 改动涉及安全/认证相关代码（即使只有 5 行）
- 改动在关键业务路径（支付、权限、数据持久化）
- 你对代码库不熟

**当疑虑时，默认完整流水线。**
