# AI Navigator 知识库使用说明

本知识库由 `ai-navigator` Agent 维护，供自身两种模式使用：
- **模式 A（研究模式）**：主动更新各文件内容
- **模式 B（顾问模式）**：读取现有内容辅助回答

---

## Agent 读写协议

### 何时读 INDEX.md
- 每次进入模式 B 回答前，必须先读 `INDEX.md` 定位相关文件
- 每次进入模式 A 研究后写入前，必须先读 `INDEX.md` 确认文件路径

### 何时更新 research-log
- 每次模式 A 研究会话结束后，在 `research-log/` 下创建文件：`YYYY-MM-DD-{topic-slug}.md`
- 记录格式：研究主题、信息源列表、主要发现、待验证项

### 交叉验证要求
- `[待验证]`：仅有单一信息源，尚未交叉确认
- `[已验证]`：已有 ≥2 个独立信息源一致确认
- `[权威]`：来自官方文档、官方博客、官方公告
- 禁止将 `[待验证]` 升级为 `[已验证]` 时仅凭单一来源

### 日期版本格式规范
- 知识日期：`YYYY-MM`（精确到月）
- 版本号：遵循原项目版本格式（如 `v1.5.3`、`API v2`）
- 源引用格式：`[来源名称](URL)` 或 `官方文档 YYYY-MM`
- 禁止写入无日期的时效性信息

### 文件更新规则
- 更新任何文件后必须同步更新 `INDEX.md` 中对应条目的"最后更新"字段
- 新增文件必须在 `INDEX.md` 中注册
- 删除或重命名文件必须经用户明确授权

---

## 知识库目录结构

```
ai-navigator/
├── INDEX.md                    ← 索引入口（每次读写的起点）
├── README.md                   ← 本文件（协议说明）
├── models/                     ← 各 AI 厂商和模型知识
│   ├── anthropic.md
│   ├── openai.md
│   ├── google.md
│   ├── xai.md
│   ├── deepseek.md
│   ├── qwen.md
│   ├── kimi.md
│   ├── minimax.md
│   └── hunyuan.md
├── frameworks/                 ← AI 框架和工具链
│   ├── langchain.md
│   ├── langgraph.md
│   ├── llamaindex.md
│   ├── openclaw.md
│   ├── hermes.md
│   └── _other-oss.md
├── paradigms/                  ← AI 工程范式
│   ├── skill-engineering.md
│   ├── harness-engineering.md
│   ├── context-engineering.md
│   └── agent-design-patterns.md
├── industry-watch/             ← 行业动态（按季度）
│   └── 2026-Q2.md
└── research-log/               ← 每次模式 A 研究记录
    └── .gitkeep
```
