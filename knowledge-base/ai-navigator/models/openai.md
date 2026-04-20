# OpenAI — 全景知识

> last_updated: 2026-04-18
> 状态：[部分] 核心事实已模式 A 验证；定价页有 Cloudflare 防御未抓到，价格以 SDK + 官方公告数据为准

---

## 1. 模型矩阵（2026-04）

来源：[权威] `openai-python` v2.32.0（2026-04-15） `src/openai/types/shared/chat_model.py` 和 `all_models.py`

### GPT-5 主线（对话 / 通用）

| 模型 ID | 发布 | 备注 |
|---|---|---|
| `gpt-5.4`, `gpt-5.4-mini`, `gpt-5.4-nano` + `-2026-03-17` 日期后缀 | 2026-03-17 | [权威] 最新旗舰三档 |
| `gpt-5.3-chat-latest` | 滚动 | 对话专调，latest 别名 |
| `gpt-5.2`, `gpt-5.2-pro` + `-2025-12-11` | 2025-12-11 | Pro 高推理 |
| `gpt-5.1`, `gpt-5.1-codex`, `gpt-5.1-codex-max`, `gpt-5.1-mini` + `-2025-11-13` | 2025-11-13 | codex / codex-max 专项编码 |
| `gpt-5`, `gpt-5-mini`, `gpt-5-nano`, `gpt-5-codex`, `gpt-5-pro` + `gpt-5-pro-2025-10-06` | 2025-08-07 / 10-06 | 初代 GPT-5，兼容保留 |

### Reasoning 专线（o 系列）

| 模型 ID | 发布 | 用途 |
|---|---|---|
| `o4-mini`（2025-04-16）, `o4-mini-deep-research`（2025-06-26） | | 轻推理 + 深度研究 |
| `o3`, `o3-pro`（2025-06-10）, `o3-mini`, `o3-deep-research`（2025-06-26） | | 高推理 / 深研究 agent |
| `o1`, `o1-pro`（2025-03-19）, `o1-mini`, `o1-preview` | | 推理初代，仍可用 |

### 特殊能力

- `computer-use-preview-2025-03-11` — 屏幕/浏览器操作 Agent [权威]
- `gpt-4o-audio-preview-2025-06-03` — 实时语音 [权威]
- `gpt-4o-search-preview-2025-03-11` — 内置搜索
- `codex-mini-latest`, `chatgpt-4o-latest`

### GPT-4 家族（维护）

- `gpt-4.1`, `gpt-4.1-mini`, `gpt-4.1-nano`（2025-04-14）
- `gpt-4o` 系列（含 audio / search / mini-search）
- `gpt-4-turbo`（2024-04-09）

---

## 2. 定价（[待验证] — 官方 Pricing 页被 Cloudflare 拦截）

- 官方来源需人工验证或用经 OpenAI CLI auth 的接口
- 历史推断：
  - `gpt-5.4` ≈ $5/$15 per MTok 量级 [待验证]
  - `gpt-5.4-mini` ≈ $0.6/$2.4 [待验证]
  - `gpt-5.4-nano` ≈ $0.15/$0.60 [待验证]
- Batch API：50% 折扣（自 2024 年策略，2026 延续 [待验证]）
- Prompt Caching：Assistants v2 起延续 [待验证]
- **下轮研究必须**：openai.com/api/pricing 手工截图

---

## 3. Agent / SDK 生态（2026-04-18 最新）

| 项目 | 最新版 | 日期 | 要点 |
|---|---|---|---|
| `openai-python` | **v2.32.0** | 2026-04-15 | 基础 SDK |
| `openai-agents-python` | **v0.14.2** | 2026-04-18 | 多 Agent workflow |
| `openai/codex` | **rust-v0.122.0-alpha.10** | 2026-04-18 | Rust 编码 agent CLI，日发版 |
| `openai-agents-js` | 同步维护 | 活跃 | |
| `openai-realtime-agents` | — | | 实时语音 agent 模板 |

### openai-agents-python v0.14.0（2026-04-15）里程碑：**Sandbox Agents**

- 新增 `SandboxAgent` class：带 workspace manifest 的 isolated Agent
- 关键概念：
  - `Manifest`：workspace 合约（files / directories / Git repos / env / users / mounts）
  - `SandboxRunConfig`：per-run sandbox 配置
  - Capabilities / Snapshots / Resume — agent 可跨运行续接工作
- 意义：**对标 Claude Code 的 agent workspace 持久化**，但以 SDK 形式下沉

### v0.14.2 新增

- `MongoDB session backend`
- Sandbox extra path grants
- 持久化工具来源元数据

---

## 4. 关键产品动向

- **Codex Skills Catalog**（2026-04 活跃）— 对标 Claude Agent Skills
- **Symphony**（2026-04 内部实验）— 隔离项目自主实现
- **Flex / Priority inference tiers**（2026-04，Google/xAI 均跟进）— 成本 / 延迟优化分级

---

## 5. 官方资源

- 官网：`https://openai.com`
- API 文档：`https://platform.openai.com/docs`（Cloudflare 防御）
- 模型列表：`https://platform.openai.com/docs/models`
- Python SDK：`https://github.com/openai/openai-python`
- Cookbook：`https://github.com/openai/openai-cookbook`
- Agents SDK Python：`https://github.com/openai/openai-agents-python`
- Codex：`https://github.com/openai/codex`

## 6. 下轮研究重点

- [ ] per-million-token 价格（gpt-5.4 / mini / nano）— 需绕过 Cloudflare
- [ ] gpt-5.1-codex-max 与 Claude Opus 4.7 在 SWE-bench Verified 的对比数据
- [ ] Sandbox Agents vs Claude Code agent 运行时对比报告
- [ ] Reasoning "effort" 参数的成本影响曲线
