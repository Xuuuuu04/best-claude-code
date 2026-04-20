# Skill Engineering — 2026 新范式

> last_updated: 2026-04-18

---

## 1. 为什么 Skills 成为新范式

### 痛点：Tool 粒度太细

传统 function calling：
- 每个 tool 一个 JSON schema
- 超过 20-30 个 tool 后，模型选择准确率下降
- 跨项目复用难（每次都要重新写 schema + 实现）
- 任务级的"怎么使用这组 tool"没处放

### Skills 的抽象

Skill = **任务级能力包**：
- 多个 tool 的组合
- Markdown 形式的"使用指南"（给模型看）
- 配置 / 依赖 / 触发条件
- 可共享 / 可版本化 / 可市场化

---

## 2. 三大厂商的 Skills 实现

### A. Anthropic Claude Skills（[权威] 2026-04-16 公开仓）

仓库：`anthropics/skills`

Skill 结构（典型）：
```
my-skill/
├── SKILL.md          # 给模型读的指南（何时用，如何用）
├── scripts/          # 可执行 bash/python
├── resources/        # 静态资源
└── manifest.yaml     # 元数据
```

启用方式（Agent SDK v0.1.62+）：
```python
options = ClaudeAgentOptions(skills="all")  # 自动发现
```

Claude Agent Plugins 仓：`anthropics/knowledge-work-plugins`（2026-04-17）
- PowerPoint skill
- Excel skill
- Word skill
- 各类文档自动化

### B. OpenAI Codex Skills Catalog（[权威] 2026-04）

- 对标 Claude Skills
- 绑定 Codex CLI
- Catalog 形式供 Codex 发现
- [待验证] API / ChatGPT 侧是否复用同一 Skills 抽象

### C. Google Gemini "Built-in Tools" 组合调用

[权威] 2026-03-18 changelog

> "Built-in Tools and Function Calling Combination — 可在单次 API call 中同时使用 Gemini 内置 tools 和自定义 function calling tools"

- Grounding with Google Maps
- Grounding with Google Search
- Code Execution
- File search
- 可与用户自定义 tools 组合

功能上等价于 Skills，但没有统一包装格式。

---

## 3. Skills vs 其他抽象

| 抽象 | 定位 | 范围 |
|---|---|---|
| **Tool / Function** | 单动作 | call("func", args) |
| **Skill** | 任务型 | 多 tool + 指南 + 流程 |
| **MCP Server** | 跨进程服务 | 承载 prompts + resources + tools |
| **Plugin** | 产品级扩展 | Claude plugins = Skill + UI + 配置 |
| **Agent** | 自主决策体 | 自带规划 + 记忆 + skills 消费 |

**关系**：Plugins 打包 Skills；Agents 消费 Skills；MCP Servers 提供 Skills 可用的 tools。

---

## 4. 社区研究：Skills 作为知识蒸馏载体

### "Don't Retrieve, Navigate" 论文（HF 2026-04）

- 标题：*Distilling Enterprise Knowledge into Navigable Agent Skills for QA and RAG*
- 提议：把企业文档从"被检索"（RAG）转为"被导航"（Skills）
- Skills 带 hierarchy / index / 指南
- agent 像用户浏览 docs 一样逐步下钻
- **暗示**：Skills 可能成为 RAG 的部分替代

---

## 5. Skill 设计原则（萃取自 Anthropic skills 仓实践）

1. **单一聚焦任务**：一个 skill 解决一类任务，不做 god-skill
2. **SKILL.md 是第一公民**：模型读的指南决定调用质量
3. **参数最小化**：能推断就不传，减少决策负担
4. **幂等 + 可撤销**：鼓励先 dry-run
5. **独立依赖**：每个 skill 的依赖独立，避免冲突
6. **可测试**：提供 fixture / example
7. **版本化**：skill 升级不破坏 caller

---

## 6. 如何写一个 Claude Skill（模板）

```markdown
<!-- SKILL.md -->
# excel-analytics

## When to use
当用户需要对 .xlsx 做统计分析、透视表、图表生成时。

## How to use
1. 调用 `scripts/load.py <file>` 读取文件到结构
2. 调用 `scripts/analyze.py` 生成分析
3. 用 `resources/chart-template.html` 渲染图

## Arguments
- file_path (str): 绝对路径
- operations (list[str]): 分析操作列表

## Outputs
- JSON 结果
- 可选的 HTML 图表
```

---

## 7. 与 Harness v23 的映射

本团队 `~/.claude/skills/` 目录就是 Skill 载体；`shared/guides/` 是团队 skills 参考文档。

**建议**：随着 Claude Agent Skills 生态成熟，Harness 团队可以：
- 把 `skills/` 下的能力规范化为 `SKILL.md`
- 发布为公开仓（必要时）
- 用 Agent SDK `skills=` 参数管理

---

## 8. 下轮研究

- [ ] Claude Skills 官方仓的最佳 skill 案例拆解
- [ ] OpenAI Codex Skills Catalog 结构
- [ ] MCP Server 打包为 Skill 的可行性
- [ ] Skill marketplace 经济模型（付费 / 免费 / 企业）
- [ ] Skill 安全审计（恶意 skill 的检测）
