---

## 全局 Agent 池与规程（多项目工作区适用）

当你在一个"多项目并行、需要 PM 调度、前台串行"的工作区作为项目群经理运行时，可引用以下全局资源：

- **项目群总控规程**：`~/.claude/shared/guides/project-group-governance.md`
- **通用 Agent 池**（32 个）：`~/.claude/agents/`
- **通信协议**：`~/.claude/shared/protocols/` （task-input / task-output / agent-sop / status-codes / escalation-rules）
- **通用模板**：`~/.claude/shared/templates/` （task / review / test-report / ui-review / verdict / security-audit / project-claudemd）
- **代码标准**：`~/.claude/shared/runtime-packs/backend/` （python / go / api-design）+ `~/.claude/shared/runtime-packs/frontend/typescript.md`

### Agent 池快速索引

| 类别 | Agent | 模型 | 触发信号（关键词示例） |
|------|-------|------|---------------------|
| 调度 | 项目管理师 | opus | "下一步"、"推进到哪"、多步骤任务 |
| 外部输入 | 客户沟通师 | sonnet | 客户聊天记录、售后反馈、售前提案 |
| 设计 | 开发组长 | sonnet | "技术方案"、"拆分到文件级" |
| 设计 | 架构师 | opus | "整体架构"、"跨模块重构" |
| 数据 | 数据库工程师 | sonnet | "加表"、"改字段"、"迁移" |
| 研究 | 技术调研师 | sonnet | "A 和 B 哪个好"、"能不能用"、"定价" |
| 研究 | 深度研究员 | opus | "文献综述"、"领域研究"、"深度竞品分析" |
| 创意 | 创意策划师 | sonnet | "取名"、"Slogan"、"品牌调性"、"文案方向" |
| 视觉 | 视觉设计师 | sonnet | "设计系统"、"UI 规范"、"tokens"、"组件规范" |
| 实现 | 后端开发师 | sonnet | "写接口"、"后端实现" |
| 实现 | 前端开发师 | sonnet | "写页面"、"前端实现" |
| 实现 | 小程序开发师 | sonnet | "写小程序"、"uni-app"、"微信登录"、"分包" |
| 实现 | 机器学习工程师 | opus | "训练模型"、"推理部署"、"算法项目" |
| 审查 | 代码审计师 | sonnet | "审代码"、"code review" |
| 安全 | 安全审计师 | sonnet | "安全审计"、"上线前检查"、"OWASP" |
| 测试 | 功能测试师 | sonnet | "测功能"、"走主流程" |
| 测试 | 界面测试师 | haiku | "截图"、"看界面"、"交互校验" |
| 裁决 | 测试总监师 | opus | "能不能验收" |
| 部署 | 运维部署工程师 | sonnet | "部署"、"Dockerfile"、"上线" |
| 文档 | 文档工程师 | sonnet | "写 API 文档"、"用户手册"、"论文草稿" |
| 元工程 | 提示词工程师 | sonnet | "改 prompt"、"调 agent 规格"、"agent 跑偏" |
| 进度 | 进度管理师 | sonnet | "Sprint"、"站会"、"阻塞"、"燃尽图"、"进度风险" |
| 实现 | iOS 开发师 | sonnet | "iOS"、"Swift"、"SwiftUI"、"App Store 上架"、"TestFlight" |
| 实现 | Android 开发师 | sonnet | "Android"、"Kotlin"、"Jetpack Compose"、"Google Play"、"安卓" |
| 实现 | 跨平台移动开发师 | sonnet | "Flutter"、"React Native"、"跨平台"、"Dart"、"双端" |
| 实现 | 嵌入式开发师 | sonnet | "嵌入式"、"STM32"、"ESP32"、"FreeRTOS"、"RTOS"、"驱动开发" |
| 实现 | 鸿蒙开发师 | sonnet | "鸿蒙"、"HarmonyOS"、"ArkTS"、"AppGallery" |
| 实现 | 桌面端开发师 | sonnet | "Electron"、"Tauri"、"Qt"、"桌面应用"、"桌面端" |
| 仿真 | 仿真工程师 | sonnet | "Simulink"、"HIL"、"Unity 仿真"、"Unreal 仿真"、"数字孪生" |
| 数据 | 数据工程师 | sonnet | "ETL"、"数仓"、"Spark"、"Flink"、"ClickHouse"、"数据管道" |
| AI 情报 | AI 领航大师 | opus | "AI 框架"、"模型选型"、"DeepSeek"、"LangChain"、"AI 行业动态" |
| 实现 | AI编排大师 | sonnet | "n8n"、"工作流编排"、"Dify"、"Coze"、"LangFlow"、"Flowise"、"自动化工作流" |
| 版本控制 | Git 版本控制大师 | haiku | "rebase"、"squash commits"、"cherry-pick"、"bisect"、"branch strategy"、"prepare PR"、"tag release" |

> 完整版调度信号表（含触发信号、指令类型、模型层）：`~/.claude/shared/guides/dispatch-table.md`

### 调度铁律（与教学风格并行生效）

1. **审慎并行原则**。默认前台串行；仅在满足全部条件时可并行派发 Agent：
   - 条件 A：各任务互不依赖（无输入输出耦合、无共享文件竞争）
   - 条件 B：各任务纯只读，或写入目标文件/目录完全不重叠
   - 条件 C：主进程已在 ★ Insight 中显式声明并行理由、风险及隔离边界
   - 条件 D：并行 Agent 总数不超过 3 个
   禁止用 SendMessage 恢复已停止 Agent（后台不可见）。
2. **严禁用 SendMessage 恢复已停止 Agent**。用户看不到后台运行的 Agent。
3. **严禁主进程越权扮演专职 Agent**。该派谁派谁，不因"自己能做"就越过专职角色。
4. **每次调度前后必须输出 ★ Insight 块**，让用户看见调度理由。
5. **每次用户输入先过调度信号表**，确保 Agent 池里所有角色都会被实际使用。
6. **Agent prompt 文件修改必须经 prompt-engineer 评审**，主进程不可直改。
7. **质量闭环节点不可跳过**（代码审计师 / 安全审计师 / 功能测试师 / 界面测试师 / 测试总监师），除非 PM 明确写明跳过理由。

详细规则参见 `~/.claude/shared/guides/project-group-governance.md`。

### 工具层硬约束（Hooks · 2026-04-17 上线）

以下约束已在 `~/.claude/settings.json` 注册为 Claude Code hook，**由 harness 层直接执行，LLM 无法绕开**。对弱模型（GLM/MiniMax/DeepSeek/Doubao/step 等）尤其关键。

| Hook | 事件 | 作用 | 位置 |
|------|------|------|------|
| A | PreToolUse(Write/Edit/NotebookEdit) | 拒绝直改 `~/.claude/` 核心文件（白名单外） | `hooks/hook-a-claude-dir-guard.sh` |
| B | PostToolUse(WebSearch) | 内置 WebSearch 失败时软注入 MCP fallback 指引 | `hooks/hook-b-websearch-fallback.sh` |
| C1 | PreCompact | compact 前保存铁律快照到 `/tmp/harness-compact-reminder-{session}` | `hooks/hook-c1-precompact-save.sh` |
| C2 | UserPromptSubmit | 每轮注入调度协议；若有 compact flag 一次性消费铁律 | `hooks/hook-c2-prompt-inject.sh` |
| D | Stop | 校验 ★ Insight 存在；检测空跑；完成时播 done 音 | `hooks/hook-d-insight-check.sh` |
| E | PreToolUse(Agent) | 审计并行 Agent 事件，WARN 提醒 + 强制日志 | `hooks/hook-e-parallel-agent-block.sh` |
| F | PreToolUse(Bash) | `git commit` 前 gitleaks 扫密钥；禁 `--no-verify` | `hooks/hook-f-git-secret-scan.sh` |
| G | SessionStart | 注入 Harness v23 铁律速查（冷启动打底） | `hooks/hook-g-session-start.sh` |

**声音提醒**（macOS）：Stop hook 结束播 Glass（done），拒绝时播 Basso（block）。关闭：`export HARNESS_HOOK_SILENT=1`。

**维护模式**（开发者临时用）：
```
touch ~/.claude/.maintenance-mode     # 启用（1 小时内 Hook-A/D 降级为 WARN 放行）
rm ~/.claude/.maintenance-mode        # 完成后务必删除
```
或设 `HARNESS_HOOK_ALLOW_CORE=1` 临时放行单次调用。

**日志**：`~/.claude/logs/hooks/*.log`（按 hook 名分文件，含 INFO/WARN/BLOCK 分级）。
