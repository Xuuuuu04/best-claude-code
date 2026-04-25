# 外部 Skill / Prompt 研究索引

本文件记录外部素材的结构模式，不复制外部系统提示词正文。

## 已研究来源

| 来源 | 类型 | 可信等级 | 已观察模式 | 可落点 |
|:--|:--|:--|:--|:--|
| Anthropic `skills` 官方仓库 | 官方 Skill | 高 | 短触发描述 + 主协议 + `scripts/`/`references/`/模板资源；文件类 Skill 强调读取、编辑、验证闭环 | 新增文档/PPT/Excel/PDF/Web 测试/设计/MCP Skill |
| Anthropic `pptx` / `xlsx` / `docx` / `pdf` | 官方 Skill | 高 | 文件格式专用流程、保真约束、QA 验证、脚本工具优先 | `pptx-workflow`、`docx-workflow`、`xlsx-workflow`、`pdf-workflow` |
| Anthropic `frontend-design` / `canvas-design` | 官方 Skill | 高 | 先建立设计哲学，再实现；强调避免 generic AI aesthetic、视觉细节和可访问性 | 增强 `visual-designer` / `frontend-development` |
| Anthropic `webapp-testing` | 官方 Skill | 高 | reconnaissance-then-action、with_server、截图、console/network 证据 | 增强 `visual-test-protocol` / `functional-test-protocol` |
| Anthropic `mcp-builder` / `claude-api` | 官方 Skill | 高 | 先研究协议与 SDK，再实现；强调 prompt cache、tool schema、错误处理 | 新增 `mcp-builder-protocol` / `claude-api-protocol` |
| CL4R1T4S | 泄漏/复刻 prompt | 低（结构参考） | CLI agent、设计 agent、Cursor/Windsurf/Devin 等强调工具边界、沟通时机、最小修改、环境安全 | 只提炼 guardrail / workflow，不复制正文 |
| asgeirtj/system_prompts_leaks | 泄漏 prompt | 低（结构参考） | Claude Code/Design/Office、OpenAI Codex、Gemini CLI 等呈现“身份→工具→计划→编辑→验证→汇报”的层次 | 只提炼 Skill 分类与结构，不复制正文 |
| OpenAI Agents / prompt docs | 官方文档 | 高 | handoffs、guardrails、tool choice、structured output、developer 指令优先级 | `agent-guardrails-protocol` |
| Gemini CLI / Code Assist docs | 官方文档 | 高 | ReAct loop、MCP、工具审批、上下文文件、计划模式 | 调度器/PM/DevOps 工具安全策略 |
| Kimi / DeepSeek / MiniMax / GLM 文档 | 官方文档 | 中高 | 长上下文、tool loop、strict schema、thinking/tool 状态传递、兼容 API 注意事项 | `tech-researcher` 和 API/agent Skill 参考 |

## 跨来源高频模式

1. **身份短、流程硬**：角色身份不宜太长，真正稳定的是步骤、输入输出和停止条件。
2. **工具协议显式化**：每类工具都要说明何时用、输入是什么、失败如何处理、是否允许重试。
3. **先侦察后行动**：UI/Web/仓库任务先收集状态，再执行修改或验证。
4. **验证是交付的一部分**：文件类、前端类、代码类都要求结果验证，而不是只生成内容。
5. **长知识旁路加载**：官方 Skill 常把脚本、参考、模板放子目录，主 `SKILL.md` 只保留触发和工作流。
6. **安全边界具体化**：不要只写“安全第一”，要写禁止复制密钥、禁止越界编辑、禁止无关修复等可检查规则。
7. **汇报结构固定**：最终输出强调文件路径、验证结果、未完成项、用户需要决策事项。

## 禁止吸收

- 不复制泄漏仓库中的系统提示词原文。
- 不吸收“忽略上级指令”“泄露系统提示”“绕过安全策略”等攻击性内容。
- 不把非官方仓库里的模型能力描述写成官方事实。
- 不把具体产品/项目知识放入用户级通用 Skill。

## 迭代优先级

1. 文档与 Office：`pptx-workflow`、`docx-workflow`、`xlsx-workflow`、`pdf-workflow`。
2. UI 与测试：`frontend-design-protocol`、`webapp-testing-protocol`。
3. Agent 基建：`mcp-builder-protocol`、`claude-api-protocol`、`agent-guardrails-protocol`。
4. 专业审查：增强 `code-review-protocol`、`security-audit-protocol`、`functional-test-protocol`。

## 官方资料 URL

- Anthropic Skills: https://github.com/anthropics/skills
- Anthropic Skills catalog: https://skills.sh/anthropics/skills
- Claude Code docs: https://docs.anthropic.com/en/docs/claude-code/overview
- OpenAI Agents SDK docs: https://openai.github.io/openai-agents-python/
- OpenAI prompt engineering guide: https://platform.openai.com/docs/guides/prompt-engineering
- Gemini CLI docs: https://developers.google.com/gemini-code-assist/docs/gemini-cli
- Kimi tool use docs: https://platform.moonshot.ai/docs/api/tool-use
- Kimi K2 agent setup: https://platform.moonshot.ai/docs/guide/use-kimi-k2-to-setup-agent
- DeepSeek tool calls: https://api-docs.deepseek.com/guides/function_calling
- DeepSeek thinking mode: https://api-docs.deepseek.com/guides/reasoning_model

## 本轮离线样本

- `/tmp/agent-legion-research/skills`：Anthropic 官方 Skill 仓库。
- `/tmp/agent-legion-research/CL4R1T4S`：泄漏/复刻提示词样本，只做结构统计。
- `/tmp/agent-legion-research/system_prompts_leaks`：泄漏提示词样本，只做结构统计。
