---
name: visual-test-protocol
description: 视觉测试协议。为 visual-tester 提供截图、视觉回归和关键交互验证方法。
when_to_use: 仅当 visual-tester Agent 在验证用户可见 UI 变更时加载（含截图、视觉回归、关键交互、暗色模式）。纯后端 / 接口 / 配置变更不应触发。
---

# 视觉测试协议

## 目标

验证用户可见界面的布局、文案、状态、截图和关键交互是否符合预期。

## 通用原则

1. **截图和步骤优先于主观判断**
2. **所有可见状态都要覆盖，不只看 happy path**
3. **视觉通过不替代功能通过**

## 与 functional-test-protocol 的边界

- **visual-test 负责**：可见性、布局、状态切换的视觉差异、暗色模式、响应式
- **functional-test 负责**：功能行为正确性、API 联通、权限控制
- **重叠场景"可见但不可达的按钮"**：视觉报"按钮显示正确"，功能报"点击无效"。两份证据各自独立，由 test-lead 合并裁决。

## 前置步骤：UI 反馈精确定位（拿到截图必做）

**禁止凭"看起来像"猜元素位置**。客户截图反馈到达后，先用文本反查找到精确 DOM：

1. 识别截图中可见的**文字**（按钮标签、列表项、提示文案、文案片段）
2. `grep -rn "{文字}" --include="*.vue" --include="*.ts" --include="*.tsx"` 找到精确 HTML 位置
3. 读源码确认这段文字所在的 class / component / 父容器
4. **然后才**改 CSS / 调整布局

**如果截图中没有可见文字**（纯图标 / 纯样式问题）：
- 用截图中的颜色 / 尺寸 / 位置在源码里反查
- 必要时让用户**圈出截图中具体元素**或提供 DOM hint
- 不要猜、不要假设"上次修过的地方就是这次目标"

## 检查清单

- [ ] 已用 grep 文字定位到精确 DOM（截图反馈场景必做）
- [ ] 关键页面/组件截图与预期一致
- [ ] loading、empty、error、success 状态完整
- [ ] 响应式布局无明显错位
- [ ] 文案、按钮、交互可见且可达
- [ ] 截图路径、复现步骤、环境信息可追溯

## Critical 示例

- ✗ 关键按钮不可见或不可用
- ✗ 错误态/空态明显缺失
- ✗ 移动端响应式严重错位

## 失败处理（截图不可达时的降级路径）

视觉测试依赖截图，但环境可能不可用。按以下顺序降级：

| 情况 | 降级方式 | 必须做 |
|:--|:--|:--|
| 服务未启动 / 端口不通 | 不算 PASS。先尝试 `npm run dev` / `pnpm dev` / 项目对应启动命令；启动失败则升级到主会话 | 在 review artifact 写明启动命令、错误日志 |
| 无 GUI 环境（headless / CI 容器） | 改用 Playwright/Puppeteer headless 截图；如不可用，用 `mcp__plugin_playwright_playwright__browser_take_screenshot` | 在报告标记"headless 截图，未做眼校" |
| 浏览器扩展 / Playwright 不可用 | 降级到只读源码 + 反查 DOM；产出 `WARNING: 无法截图，仅做静态校验` | **禁止**给 PASS，最高 CONDITIONAL PASS |
| 用户提供的截图不清晰 | `mcp__zai-mcp-server__extract_text_from_screenshot` 提文字反查；仍不行则用 AskUserQuestion 让用户圈出 | 不要凭"看起来像"猜元素 |

**硬规则**：无任何截图证据 = `BLOCKED`，绝不给 PASS。

## 输出

写入 `.claude/artifacts/review-visual-{task-id}.md`，必须包含证据链（截图路径 / 启动命令 / 反查 grep 结果）和 PASS / CONDITIONAL / BLOCKED 明确判定。
