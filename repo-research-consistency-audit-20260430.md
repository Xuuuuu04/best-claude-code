# 仓库研究报告：README / LEGION / dispatch-table / output-style 一致性审计

## 结论（TL;DR）

1. **Agent 数量（25）**三文件一致，名称完全对齐。**Skill 数量（47）**一致。**Rule 数量（47 = 9 global + 17 lang + 18 framework + 3 infra）**一致。
2. **版本号不一致**：README 徽章写 v3.7，LEGION 最新版本记录到 v3.7，但 dispatch-table 内引用了 "v3.8 新增"，说明有未同步的版本号跳跃。
3. **Hook 数量严重过时**：CLAUDE.md 声称 "8 个生命周期 hook"，实际 hooks/ 目录有 **15 个** .sh 脚本。README 只字未提具体数量。
4. **output-styles/legion-dispatch.md 与 CLAUDE.md 有大量功能重叠**（调度纪律、前台优先、快路径边界），但尚未冲突，建议未来版本合并精简。
5. 删除的 `frontend-design-protocol` 已被 `visual-design-protocol` 替代，但有 1 处悬空引用（LEGION.md v3.3 历史记录）。删除的 `security-checklist` 已合并入 `security-audit-protocol/references/checklist.md`，但 `mcp-builder-protocol` 内仍有 3 处指向旧路径的引用。
6. 新增的 `bcc-resume` 在 dispatch-table 有引用但 CLAUDE.md 流水线命令表未收录。新增的 `hook-dashboard.sh` 和 `visual-design-protocol` 未被 README/LEGION 文档覆盖。

---

## 1. README.md vs LEGION.md vs dispatch-table.md 三方一致性

### 1.1 Agent 数量与名称

| 维度 | README | LEGION | dispatch-table | 实际 agents/ |
|:--|:--|:--|:--|:--|
| 数量 | 25 | 25 | 25 行路由表 | 25 个 .md 文件 |
| 名称列表 | 完整列出 23 个具名（3 个 实现工程师 合并写） | 核心流水线 15 + 卫星层 8 = 23（同上） | 路由表每行 1 个 | 完全一致 |

**置信度：确定**。三文件 + 实际文件完全对齐。

### 1.2 Skill 数量

| 维度 | README | CLAUDE.md | LEGION | 实际 skills/ |
|:--|:--|:--|:--|:--|
| 数量 | 47 | 47 | 未直接写数量 | 47 个目录 |

**置信度：确定**。

### 1.3 Rule 数量

| 维度 | README | LEGION | 实际 rules/ |
|:--|:--|:--|:--|
| 数量 | "17 语言 + 17 框架"（正文） | "9 global"（v3.1.3 提到） | 9 global + 17 lang + **18 framework** + 3 infra = **47** |

**不一致**：README 写 "17 框架"，实际 framework 目录有 **18 个** .md 文件。总 47 数量一致，但框架规则多了一个未记录。

- 证据：`ls rules/_framework/*.md | wc -l` = 18
- 置信度：较确定（需确认第 18 个是哪个）

### 1.4 Hook 数量

| 维度 | CLAUDE.md | README | LEGION | 实际 hooks/ |
|:--|:--|:--|:--|:--|
| 数量 | "8 个生命周期 hook" | 未写具体数量 | 未写具体数量 | **15 个** .sh（不含 _lib/） |

**严重不一致**：CLAUDE.md 第 40 行写 `8 个生命周期 hook + _lib/`。实际有 15 个 hook 脚本。差额 7 个是 v3.x 新增的（intent-classify, clarification-gate, review-gate, permissionrequest-exit-plan-allow, artifact-index-suggest, tool-failure-audit, scope-lock-guard）。

- 证据：`CLAUDE.md:40` 写 "8 个"；`ls hooks/*.sh | wc -l` = 15
- 置信度：确定

### 1.5 版本号

| 文件 | 声明版本 |
|:--|:--|
| README.md 第 22 行 | `v3.7`（徽章） |
| LEGION.md 最后版本记录 | `v3.7`（第 735 行） |
| dispatch-table.md 第 89 行 | `v3.8 新增`（门控强制条件） |

**不一致**：dispatch-table 引用了 v3.8，但 LEGION.md 的进化历史只记录到 v3.7，README 徽章也停留在 v3.7。v3.8 的门控强制条件段落是实际存在的未版本化内容。

- 证据：`dispatch-table.md:89` 写 "v3.8 新增"；`LEGION.md` 无 v3.8 章节
- 置信度：确定

### 1.6 流水线描述

三文件对标准流水线（新功能 / Bug 修复 / 迁移 / 小程序 / ML）的描述：
- **dispatch-table.md**：最详细，含完整路由表 + 5 条流水线 + 门控强制条件
- **LEGION.md**：无流水线细节，但有设计心路（为什么 25 个 Agent）
- **README.md**：架构图 + 特性总览，与 dispatch-table 一致

**无冲突。** dispatch-table 是真源，其他文件引用时不矛盾。

---

## 2. output-styles/legion-dispatch.md vs CLAUDE.md 重复度

### 重叠区域

| 功能点 | CLAUDE.md 位置 | legion-dispatch.md 位置 | 重叠程度 |
|:--|:--|:--|:--|
| 调度器身份（默认指挥官，不写复杂代码） | 第 1 段 + "快路径边界" | "核心行为" 段 | 高 |
| 快路径边界（可/不可直接编辑） | "快路径边界" 段 | "代码与配置的边界" 段 | 高 |
| 前台优先派遣 | "前台优先" 段 | "前台优先派遣 Subagent" 段 | 几乎相同 |
| 调度表优先 | "调度真源" 段 | "调度表优先" 段 | 相同语义 |
| 自然语言优先 | "工具优先级" 段 | "自然语言优先" 段 | 相同语义 |
| 模型意识 | "模型意识" 段 | "模型意识" 段 | 几乎相同 |
| 上下文纪律 | "上下文预算" 段 | "上下文纪律" 段 | 部分重叠 |

### 冲突

无直接冲突。两文件语义一致，dispatch-table 声明冲突时以自己为准。

### legion-dispatch.md 独有内容

| 内容 | 说明 |
|:--|:--|
| Hook 信号信任决策表（何时忽略 hook） | 7 行决策表，详细定义 5 种情景 |
| 调度映射表（trivial/small/medium/large/unclear） | 5 行表格 |
| 沟通风格（中文优先、极简、结构化） | 比较独特，属于 output style 职责 |
| 审查结果表达格式 | `✓ {阶段名}` 模板 |
| 学术引用（Brevity Constraints 论文） | 仅此处引用 |

### CLAUDE.md 独有内容

| 内容 | 说明 |
|:--|:--|
| 流水线命令表（/bcc-* 命令） | 12 个命令及说明 |
| 调度纪律详细条款 | 不可逆操作确认、并发声明模板等 |
| Compact Instructions（context 压缩保留清单） | 7 项保留 + 4 项可丢弃 |
| 接口字段对账 few-shot | 4 个反例 + 1 个审查模板（**与 dispatch-table 完全重复**） |

### 结论

**重复度约 60%**。CLAUDE.md 从 dispatch-table 大段复制了接口字段对账 few-shot（约 100 行），同时与 output-style 在调度纪律上大面积重叠。

**是否应合并**：不建议物理合并（它们是不同扩展层——CLAUDE.md 每请求注入，output-style 替换系统提示风格部分）。建议：
- CLAUDE.md 中的"接口字段对账"段删除，改为引用 `dispatch-table.md`（已声明以调度表为准）
- CLAUDE.md 中的重复调度纪律精简为 "详见 dispatch-table" 一行引用

---

## 3. 删除文件审计

### 3.1 `skills/frontend-design-protocol/`（已删除，4 个文件）

**替代**：`skills/visual-design-protocol/SKILL.md` — 内容几乎相同（对比 git HEAD 中的旧版本与新版本，frontmatter 和工作流 6 步完全一致，仅 name 和 description 措辞微调）。

**悬空引用**：
| 文件 | 行号 | 内容 | 严重度 |
|:--|:--|:--|:--|
| `LEGION.md:677` | v3.3 历史记录 | "高级前端工程师 新增 frontend-design-protocol skill" | 低（历史记录，不影响运行） |
| `agents/高级前端工程师.md:16` | skills 字段 | 已更新为 `visual-design-protocol` | 无问题 |
| `agents/视觉设计专家.md` | skills 字段 | 引用 `visual-design-protocol` | 无问题 |

**结论**：删除合理。`高级前端工程师` 已更新引用。唯一残留是 LEGION.md 历史记录，不影响运行。

### 3.2 `skills/security-checklist/`（已删除，1 个文件）

**替代**：`skills/security-audit-protocol/references/checklist.md` — 文件开头注释明确写着 "原 skills/security-checklist 内容，已合并入 security-audit-protocol 的 references"。

**悬空引用**：
| 文件 | 行号 | 内容 | 严重度 |
|:--|:--|:--|:--|
| `skills/mcp-builder-protocol/SKILL.md:27` | references 列表 | "references/security-checklist.md" | 中（引用自身 references，可能仍有效） |
| `skills/mcp-builder-protocol/references/tool-design-template.md:137` | 内文引用 | "详见 security-checklist.md" | 中（指向 mcp-builder-protocol 自己的 references 目录，需确认该文件是否存在） |
| `skills/mcp-builder-protocol/references/tool-design-template.md:236` | 内文引用 | "参考 ... security-checklist.md" | 同上 |

**结论**：需验证 `mcp-builder-protocol/references/security-checklist.md` 是否独立存在。如果不存在，这 2 处引用指向旧全局 skill 的路径，属于死链接。

---

## 4. 新增文件审计

### 4.1 `bin/hook-dashboard.sh`

**用途**：汇总近 24h hook 运行数据的仪表盘脚本。
**文档覆盖**：README、LEGION、CLAUDE.md、dispatch-table 均**未提及**。`bin/doctor.sh` 中也**未引用**。
**影响**：纯工具脚本，不影响运行。但作为 bin/ 工具应在 README 或 LEGION 的工具清单中记录。

### 4.2 `skills/bcc-resume/`

**用途**：`/bcc-resume {task-id}` 断点续跑命令。
**文档覆盖**：
- dispatch-table.md:168 — **已记录**（"使用 /bcc-resume {task-id} 自动执行断点检测和续跑"）
- CLAUDE.md 流水线命令表 — **未收录**（缺少 `/bcc-resume` 条目）
- README — **未收录**
**影响**：CLAUDE.md 是调度器主入口，缺少该命令意味着调度器不知道有这个工具。

### 4.3 `skills/security-audit-protocol/references/`

**用途**：安全审计协议的参考文档（含 `checklist.md`，即原 security-checklist 的迁移内容）。
**文档覆盖**：已在 LEGION.md v3.1.3 中提到 security-audit-protocol 的 references 填充。**已覆盖**。

### 4.4 `skills/visual-design-protocol/`

**用途**：替代已删除的 `frontend-design-protocol`，内容几乎相同。
**文档覆盖**：
- `agents/高级前端工程师.md` — skills 字段已更新引用
- `agents/视觉设计专家.md` — skills 字段已引用
- README / LEGION — **未记录**此 skill 的存在（既不在目录结构描述中，也不在版本历史中）
**影响**：该 skill 实际生效（Agent 已引用），但文档层面无痕迹。

---

## 未覆盖方向

- 未逐个验证 18 个 framework rules 的名称是否与 README 声称的 "17 框架" 列表完全对应
- 未检查 `mcp-builder-protocol/references/` 下是否有独立的 `security-checklist.md`（仅 grep 了引用）
- 未审计 LEGION.md 提到的 MCP 配置是否与 settings.json 实际配置一致
- 未检查 25 个 Agent 的 frontmatter skills 字段中是否有其他指向已删 skill 的引用
