---
name: code-review-protocol
description: 代码审查协议。为 code-reviewer 提供 scope 合规、契约一致性和可维护性检查清单。
---

# 代码审查协议

## 目标

验证实现是否严格符合 scope-lock，并具备可维护性与可回归验证能力。

## 通用原则

1. **scope 合规优先于风格偏好**
2. **证据比感觉重要**
3. **测试是否有效比覆盖率数字更重要**
4. **不做架构重审，除非实现明显违背架构**

## 检查清单

### Scope 合规
- [ ] 修改范围与白名单完全一致
- [ ] 未触碰禁止事项
- [ ] 未引入未授权依赖
- [ ] 接口契约与 scope-lock / architecture 一致

### 代码质量
- [ ] 错误处理完备，无空 catch
- [ ] 命名清晰，结构可维护
- [ ] 无明显性能反模式

### 测试
- [ ] 覆盖 scope-lock 指定场景
- [ ] 边界情况有测试
- [ ] Bug 修复测试能复现原问题
- [ ] Refactor 重构测试保持行为等价

## Critical 示例

- ✗ 修改了白名单外文件
- ✗ 引入了未授权第三方依赖
- ✗ 接口签名与 scope-lock 不一致
- ✗ 测试没有真正覆盖修复场景

## 输出

写入 `.claude/artifacts/review-code-{task-id}-{n}.md`。

## 参考样品

写 review 前若不确定 artifact 长什么样，读：
- `examples/sample-review-code.md` — OAuth 登录审查的完整样品（Critical/Warning/Suggestion 三档示范，scope 合规 / 代码质量 / 测试 / 接口契约 四维度）

## Memory 自省（审查结束前必做）

审查完成后，写报告前做一次自检：**本次审查有没有暴露跨任务可复用的事实？**

触发写入 agent memory 的信号：
- 某类代码气味在本项目频繁出现（如"多处用 `any` 作为 escape hatch"）
- 团队约定被反复违反的地方（需要固化进规范 or memory）
- 某个审查维度在本项目特别重要（如某库的并发陷阱）
- 某种测试反模式（如"mock 数据库掩盖了真问题"）

**写入路径**：`$CLAUDE_PROJECT_DIR/.claude/agent-memory/code-reviewer/<short-title>.md`（先 `mkdir -p`）

**格式**：3 句话能说清；超长拆多条；不确定不写；负向不记、具体到单文件不记、重复已有不记。单个 memory ≤ 30 行。

无触发就不写。审查 memory 是冷数据，宁缺毋滥。
