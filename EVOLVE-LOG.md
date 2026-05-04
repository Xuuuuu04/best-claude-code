# Evolve Log

Agent Legion 系统的进化历史。每次 `/bcc-evolve` 执行后追加一条。

---

## 2026-04-23 · v1（首次进化）

### 触发

手动 `/bcc-evolve`。此前 `/bcc-reflect` 产出了 17 条 Memory（5 user + 11 feedback + 6 project），主要来自 Agent Legion 系统架构建造期的踩坑和自省。

### 批准的提案

**批准：4 / 4（全部）**

### 已执行的变更

- [NEW] `rules/_global/hook-scripts-pattern.md` — 合并 5 条 hook 相关 feedback 为一条全局 Rule
  - 来源：`hook-scripts-no-set-e`、`jq-append-needs-compact-mode`、`hook-if-field-env-var-danger`、`test-run-cwd-leaks`、`test-with-real-event-samples`
- [DOC] `LEGION.md § 3.4`（Subagents 机制）— 新增"SubagentStop 事件与 Transcript 对应关系"和"并发 Subagent 状态追踪"两小节
  - 来源：`subagent-stop-event-minimal-fields`、`subagent-transcript-location`、`concurrent-subagents-need-id-namespacing`
- [DOC] `LEGION.md § 3.12`（系统健康信号）— 新节
  - 来源：`healthy-prompt-cache-ratio`、`turn-count-as-quality-signal`
- [CLEAN] 清理 `feedback.md` 移除 8 条已固化条目，`project-notes.md` 移除 3 条已固化条目
  - MEMORY.md 索引同步更新，从 17 条缩到 10 条

### 跟踪指标

- 进化前 Memory 总行数: 337 → 进化后: ~160
- 新 Rule 预期触发频率: 每次修改 hook 脚本都应该被 高级代码审查师（hook 合规维度）+ 高级安全审计师（安全维度）参考
- LEGION.md 体积变化: +102 行（文档增量合理，用于替代 Memory 中的重复提醒）

### 元观察（为什么这次是"保守型进化"）

本次 Memory 条目**全部来自系统建造期**，而非流水线实战。这意味着：
- 结构性事实（Skills 扁平、hook 模式）— 已经充分验证，固化是安全的
- 但流水线使用层面的痛点 — **完全没有数据**（因为还没真正跑过端到端流水线）

因此本次进化只处理了"建造期结构教训"。流水线层面的经验需要 2 周实战积累后才能进化。

### 下次审查时机

**建议 2-3 周后**（约 2026-05-10 前后），前提是：
- 至少完成 3 次端到端流水线（`/bcc-new-feature` 或 `/bcc-fix-bug`）
- 至少触发 1 次 `/bcc-quick-fix`
- `/bcc-doctor` 运行过 ≥2 次
- cost-log 积累到 ≥30 次 subagent 调用

### 回退方式

如发现本次进化产出的 Rule 或文档有问题：
```bash
git revert <本次 commit hash>
```
Memory 条目也可从 git 历史恢复。

---

## 2026-04-25 · v2（外部仓库对比驱动）

### 触发

离线研究 [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code)（140K+ stars，Anthropic Hackathon Winner，v1.10.0）。对比其设计模式与 Agent Legion 的差异。详见 `artifacts/tech-research-ecc-compare-20260425.md`。

### 评估结论

ECC 走"广度 + 多 IDE + 商业化"路线（48 agents / 288 skills / 79 commands / 89 rules / 10 schemas / 136 scripts / 997 tests）。Agent Legion 走"深度 + 分层门控 + artifact 契约"路线。两条路都成立，ECC 的堆料策略不应模仿，但有三个可吸收点。

### 批准的提案

**批准：2 / 3**

- ✅ **P1: Hook Profile 运行时开关**（灵感来自 ECC `scripts/lib/hook-flags.js`，bash 独立实现）
- ❌ **P2: rules/_lang/ 子目录化**（拒绝理由见下）
- ✅ **P3: Artifact Schema PoC**（bash 轻量校验器，不引入 YAML parser）

### 已执行的变更

- [NEW] `hooks/_lib/hook-flags.sh`（131 行）— 提供 `get_hook_profile` / `is_hook_enabled` / `get_disabled_hook_ids` / `hook_id_from_path` / `list_registered_hooks` 公共 API
- [NEW] `bin/test-hook-flags.sh`（27 条单元测试，全部通过）
- [NEW] `bin/validate-artifacts.sh`（172 行）— 实现 CRITICAL/WARNING/PASS 三级校验；经 4 种故意错误样本验证可精准捕捉
- [MOD] `hooks/_lib/run-with-logging.sh` — 集成 hook-flags：在执行 hook 前 source hook-flags.sh，禁用时消费 stdin、exit 0。9 个 hook 脚本本体零改动
- [MOD] `bin/doctor.sh` — 新增 §14 Hook Profile + §15 Artifact Schema，且去重扫描路径避免重复报告
- [DOC] `rules/_global/hook-scripts-pattern.md` — 新增 §8 Hook Profile 运行时开关 + 审查清单条目
- [DOC] `CLAUDE.md` — 新增"运行时开关"小节（4 行）
- [DOC] `LEGION.md § 3.6` — 补 Hook 集中网关与 Profile 分档原则；§3.11.5 新增 Artifact Schema
- [NEW] `artifacts/tech-research-ecc-compare-20260425.md` — ECC 对比研究 artifact（带完整 frontmatter，通过 schema 校验）

### 拒绝 P2 的理由

ECC 的 `rules/{common,typescript,python,golang,java,...}/` 子目录化有效，是因为**每种语言有多条规则**（typescript 下有 typescript-patterns / testing / security 等）。Agent Legion 当前 `rules/_lang/` 每语言只有一个文件（17 文件）。强行子目录化会把单层 17 文件拆成 17 子目录 × 1 文件，只增加路径深度、不减少定位时间。**overdesign**。未来若某语言规则增长到 ≥3 条再拆。

### 跟踪指标

- hook 脚本数量：9 → 9（零改动）
- hook-flags 登记 hook 数：9/9（覆盖完整）
- test-hook-flags 单元测试：27/27 通过
- validate-artifacts：当前 PASS 1 / WARNING 5 / CRITICAL 0（5 个 WARNING 来自历史 artifact 缺 frontmatter，符合向后兼容策略）
- doctor 全量：23 passed / 2 warnings / 0 failures

### 元观察

本次进化有三点特殊：
1. **首次由外部素材驱动**：此前 v1 纯内源，v2 展示了"安全吸收外部高质量设计"的范式
2. **P2 被主动拒绝**是健康信号：不盲目移植是成熟度指标，也是 `external-skill-source-policy` 落地验证
3. **零修改 hook 脚本实现 Profile 门控**：通过改造 wrapper 这一 chokepoint，9 个 hook 无需任何改动就获得统一运行时开关。是"最小化改动、最大化效果"的典型案例

### 下次审查时机

**建议 2-3 周后**（约 2026-05-15 前后），前提是：
- 实战验证 `CLAUDE_HOOK_PROFILE=minimal` 是否在调试 hook 时有用
- 新 artifact 产出时观察 schema 校验是否命中真实问题
- `bin/doctor.sh` 的 §14/§15 提示是否帮助识别漂移

### 回退方式

```bash
git revert <本次 commit hash>
```
回退后 wrapper 会自然退化为只做日志的版本（hook-flags.sh 缺失时跳过 Profile 门控），9 个 hook 脚本不受影响。

---

## 2026-04-25 · v3（Router 化 + 实战反馈驱动）

### 触发

用户在实战多周后报告 5 个系统性痛点（非个例 bug）：
1. 主会话调度"心里没数"——不知道任务走快还是走慢
2. researcher 不能查远程/云端，分不清线上 vs 本地
3. 需求不清不反问，模型偏好"假设性推进"
4. 快路径改完不 review
5. Rule 误触发（`.tsx` 任意触发 React，`.py` 任意触发 framework）

追加反馈：
6. agent 写 .claude 每次都要问权限，桌面项目区一片混乱
7. agent-memory 几乎空置，没人主动记
8. artifact 命名/组织无规范，一个一个项目去看全是乱的

### 研究依据（非拍脑袋）

深度调研官方与社区最新资料：
- [Anthropic: Multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system)：承认"多 agent 常被用错"、token 成本 15×、必须硬编码 scaling 规则
- [Anthropic: Building effective agents](https://www.anthropic.com/research/building-effective-agents)：五种 agentic pattern；明确 **routing 是独立模式**
- [Anthropic: When to use multi-agent](https://claude.com/blog/building-multi-agent-systems-when-and-how-to-use-them)："多 agent 不适合大多数 coding work"
- [Claude Code: Hooks](https://code.claude.com/docs/en/hooks)：UserPromptSubmit 官方支持 `additionalContext` 注入和 `decision:"block"` 追问
- [Addy Osmani: Code Agent Orchestra](https://addyosmani.com/blog/code-agent-orchestra/)：verification is the real bottleneck

### 批准的提案

**批准：5/5 + 额外 3 项实战反馈**

### 已执行的变更

#### Router 化（5 档分类 + 三级 hook 链）
- [NEW] `hooks/intent-classify.sh`（198 行）：纯 bash + 关键词分类为 `trivial/small/medium/large/unclear`，注入 `[LEGION-INTENT]` 标记。8/8 真实样例精准分类
- [NEW] `hooks/clarification-gate.sh`（155 行）：只对 unclear + 无文件/错误日志/bypass 关键词 block，支持领域专项追问（miniprogram / deployment / auth / payment / backend / frontend）
- [NEW] `hooks/review-gate.sh`（70 行）：读 `subagent-events.jsonl` 比对 实现工程师 数 vs 高级代码审查师 数，差值>0 注入 `[REVIEW-PENDING]`
- [MOD] `settings.json`：注册 `UserPromptSubmit` 事件，串联 3 个 hook
- [MOD] `output-styles/legion-dispatch.md`：新增"Router First"顶层约束 + 5 档调度映射表（硬编码，非直觉）
- [MOD] `hooks/_lib/hook-flags.sh`：登记 3 个新 hook（intent-classify → minimal；clarification-gate / review-gate → standard）

#### Remote Researcher 能力扩展
- [NEW] `skills/remote-diag-protocol/SKILL.md`：远程只读诊断协议（命令白名单 / 黑名单 / 证据格式 / 升级触发）
- [MOD] `agents/技术调研专家.md`：description 扩展远程诊断职责；预加载 `remote-diag-protocol` skill

#### Rule 精准激活
- [MOD] `rules/_framework/wechat-mp.md`：删除 `pages/**` `components/**` 误触发 glob；加 `app.json` / `project.config.json` 特征 + `when_to_use` 字段
- [MOD] `rules/_framework/fastapi.md`：加 `when_to_use` 要求确认 `from fastapi import`；首行"适用判定"提示
- [MOD] `rules/_global/dispatch-table.md`：新增"Rule 层叠处理" + "Router 分档"小节

#### 项目级 .claude/ 权限 & 布局
- [MOD] `settings.json`：permissions.allow 加入 `**/.claude/{artifacts,agent-memory,logs,state,tmp}/**` 及相关 log 文件（agent 不再每次追问）
- [NEW] `rules/_global/dotclaude-layout.md`：**项目级 .claude/ 目录布局规范 + artifact 命名硬约束**（task-id = `{prefix}-YYYYMMDD[-slug]`，禁止无日期无前缀命名）
- [NEW] `bin/tidy-dotclaude.sh`：只读诊断工具，扫描项目 .claude/ 布局合规度，输出迁移建议（支持 `--suggest` / `--apply`）
- [MOD] `bin/validate-artifacts.sh`：增加 task-id 格式 WARNING 级检查（验证 `{prefix}-YYYYMMDD[-slug]`）

#### Agent Memory 自省
- [MOD] `skills/implementation-protocol/SKILL.md`：新增"Memory 自省（任务结束前必做）"段落，4 类触发信号 + 写入路径 + 格式约束
- [MOD] `skills/code-review-protocol/SKILL.md`：同上，专门针对审查结束时的 memory 触发信号

#### Doctor 强化
- [MOD] `bin/doctor.sh` §16 **Agent Memory Usage**：统计用户级/项目级/auto-memory 三类 memory 分布，暴露冷 agent
- [MOD] `bin/doctor.sh` §17 **Router Health**：校验 UserPromptSubmit 注册数 + 3 个 hook 可执行性 + 近 50 次分类分布

#### 文档同步
- [MOD] `LEGION.md` §3.6：补充 Hook Profile / Router 三级链路说明；§3.11.6 新节 **Router 分层（v3 新增·核心升级）** 含五档分类标准与设计取舍
- [MOD] `CLAUDE.md`：Rule 计数 46 → 47；Skill 计数 45 → 46；添加 Router 层描述
- [MOD] `README.md`：Rules 徽章 46 → 47

### 真实乱象审计（桌面项目区）

实地扫描 6 个真实项目，暴露了精准可修复问题：

| 项目 | 问题 |
|:--|:--|
| 赛博坦 | artifact 命名 30 个违规（`forumkit-11` / `task19-1` / 无日期无前缀），`init-analysis` / `review-init` 无 task-id |
| 眼科视力筛查小程序 | 113 WARNING + 5 CRITICAL；`cost-log.txt.broken.1776921065` / `scheduled_tasks.lock` 堆根目录 |
| 漫展官网购票系统 | `impl-report-27aba93`（commit hash 当 task-id）、`logout-analysis.md` 无类型前缀 |
| 海外推广增长 | `feat-20260423-02-1` 到 `-9` 共 9 个 impl-report 无索引 |
| 金盾项目 | `.claude/` 下只有 lock 文件和 `worktrees/`，没产出任何 artifact |
| 毕设代做项目 | 同类乱象；`backups/` 散放 |

所有问题被 `bin/validate-artifacts.sh` + `bin/tidy-dotclaude.sh` 精准命中，用户可用这两个工具定期审计。

### 跟踪指标

- hook 脚本数量：9 → 12（+3）
- Rule 数量：46 → 47（+1 dotclaude-layout）
- Skill 数量：45 → 46（+1 remote-diag-protocol）
- Agent 数量：25（不变）
- settings.json permissions.allow：0 → 18 条（项目级 .claude 安全路径自动放行）
- Doctor 节数：15 → 17（新增 Agent Memory + Router Health）
- 分类器真实测试：8/8 精准；validate-artifacts 在真实乱项目上发现 53-113 WARNING 精准命中
- hook-flags 单元测试：27/27 通过

### 元观察

三个本次进化的关键判断：

1. **"不如单 Agent 新会话"的担忧被官方证实，但不致命**：多 agent 不适合大多数 coding work（Anthropic 原话），所以 v3 的核心思路从"强制流水线"转为"智能路由"——让主会话的 trivial/small 档**就是单 Agent 模式**，只有 medium/large 才走流水线。系统从此**下限 ≥ 单 Agent，上限 = 多 Agent 协同**
2. **Hook 是硬约束的唯一正确位置**：prompt 里写的"必须 review""必须反问"都是软约束，模型在上下文压力下会忽略。Router 三级 hook 把关键决策从 prompt 搬到 hook，才有确定性
3. **实战数据揭露远超预判**：单看"桌面项目区"就有 113 CRITICAL+WARNING。这说明**没有 validator + 没有 doctor = 必然漂移**。v3 把 validator 和 doctor 都往前推

### 拒绝 / 不做的事

- **拒绝引入 MiniLM / ML 分类器**：200 行 bash 够用，60MB 模型塞进每次 hook 是 overdesign（参考 dev.to 案例我们选了其思路不选其实现）
- **拒绝自动整理真实项目 `.claude/`**：tidy-dotclaude 只读+建议模式，不自动 mv。用户对项目有最终话语权
- **拒绝给 25 个 agent 每个加 Memory 自省段**：只改 2 个 skill（implementation-protocol / code-review-protocol）覆盖最需要的 agent 类，不膨胀 prompt

### 下次审查时机

**建议 2-3 周后**（约 2026-05-15 前后），前提是：
- 跑过至少 10 个真实任务看 Router 分类准确率
- 看 agent-memory 是否真的开始积累（Memory 自省 prompt 生效与否）
- 看 clarification-gate 是否误打扰用户（从 `logs/clarification-gate.jsonl` 统计）
- 项目级 .claude/ 混乱率是否下降（跑 tidy-dotclaude 前后对比）

### 回退方式

```bash
git revert <本次 commit hash>
```

独立回退各 Phase：
- 仅撤 Router：从 settings.json 删 UserPromptSubmit 块；删 3 个新 hook 脚本
- 仅撤 dotclaude-layout：删 `rules/_global/dotclaude-layout.md`；从 validate-artifacts.sh 删 task-id 校验
- 仅撤权限：settings.json 的 permissions.allow 改回空数组
- 仅撤 Memory 自省：从两个 skill 删对应段落

所有改动向后兼容：Router hook 失败 → 主会话看不到 `[LEGION-INTENT]` 标记 → 按 medium 默认处理；validate-artifacts 新检查只报 WARNING 不阻塞。

---

## 2026-04-25 · v3.1（v3 紧后续修复）

### 触发

v3 落地后用户立即发现两个真实问题，且我自己刚刚遇到一次 false positive：

1. **intent-classify 误判**：`"还有需要升级的地方嘛"` 因含"升级"被分到 large，但实际是 trivial 咨询
2. 用户提"全部升级"作为继续指令时被分到 large，引发 over-routing 倾向

同时趁势把之前列出的高 ROI 5 项一起做完。

### 已执行的变更

#### A. 修 intent-classify false positive
- [MOD] `hooks/intent-classify.sh`：
  - `TRIVIAL_PATTERNS` 扩展：加入"还有.*嘛"、"建议"、"看法"、"对吗"、"是不是"等元对话词
  - 新增 `META_DISCUSSION_PATTERNS`：与 large 关键词冲突时优先 trivial
  - 决策树调整：trivial（短咨询）前置到 large 之前
  - large 加长度门槛 `LEN ≥ 8`：防"升级"单词被误判
- 12/12 真实样例全部分类正确（含 zsh 中文字符长度边界 case）

#### C. scope-lock-guard 真正硬化
- [MOD] `hooks/scope-lock-guard.sh`：
  - 主会话默认豁免（无 `agent_id` 时直接 exit 0）——避免误拦主会话快路径
  - 兼容 frontmatter `status: accepted` 和老 `**状态**: accepted` 两种格式
  - 白名单段落识别支持 `### N.` 编号 + `- path` 列表 + 行内代码 3 种格式
  - 写 artifact / agent-memory 路径永远豁免
- 5/5 集成测试通过（主会话豁免 / subagent 无 scope-lock no-op / 白名单内放行 / 白名单外拒绝 / artifact 豁免）

#### D. task-id ≥3 seq 自动建索引
- [NEW] `hooks/artifact-index-suggest.sh`（PostToolUse on Write）
- 检测同 task-id 累计 ≥3 时通过 `additionalContext` 提示主会话建 `index-{task-id}.md`
- marker 文件 `state/index-suggested-{task-id}` 防重复骚扰
- 4/4 场景测试通过（首触发 / marker 阻止重复 / 单 artifact 不触发 / 已有 index 跳过）
- [MOD] `settings.json`：注册到 PostToolUse；`hook-flags.sh` 登记为 standard

#### N. statusline 显示当前 tier
- [MOD] `statusline.sh`：从 `logs/intent-classify.jsonl` 读最近一条 `tier`，显示在第一行
- 5 档配色 + 图标：trivial(◌灰) / small(◯绿) / medium(◐琥珀) / large(◉橙) / unclear(?红)

#### F. /bcc-route 调试命令
- [NEW] `skills/bcc-route/SKILL.md`：user-invocable, `disable-model-invocation: true`
- 接受 `$ARGUMENTS` 作为模拟 prompt，调用 intent-classify 输出 tier/signals/suggest
- 不写日志，避免污染真实分类统计

### 跟踪指标变化

| 维度 | v3 | v3.1 |
|:--|--:|--:|
| Agents | 25 | 25 |
| Skills | 46 | **47**（+bcc-route） |
| Rules | 47 | 47 |
| Hooks | 12 | **13**（+artifact-index-suggest） |

### 元观察

v3.1 验证了两个判断：

1. **第一手实战 false positive 修复必须立刻做**——v3 落地几小时内就遇到 intent-classify 误判，证明分类器需要持续校准而非一次性写好。`/bcc-route` 这个调试命令的真实价值就在这里：以后遇到误判，用户能立刻预览不同措辞看效果。
2. **scope-lock-guard 主会话豁免**是 v2 的设计漏洞——v2 加 artifact 自动推导白名单后，hook 会对**主会话也激活**。v3.1 通过检测 `agent_id` 字段精确分流：subagent 内严格执行，主会话完全豁免。这种"行为按调用方分流"的模式应推广到其他 hook。

### 下次审查

仍约 2-3 周后。新观察项：
- statusline 上看到 tier 后，用户的"接管/纠正"频率是否下降？
- `/bcc-route` 实际使用频率（log 里观察）
- artifact-index-suggest 的 marker 是否需要 expire（同 task-id 长期持续后是否该重新提醒）

### 回退方式

每项独立可回退；详见 v3 节末尾的回退条目，新 hook（artifact-index-suggest）从 settings.json 删 PostToolUse 块的对应项即可。

---

## 2026-04-25 · v3.1.1（patch · review skill 加 examples）

### 触发

用户实战观察："很多 skill 做得很简单"。审计后发现 13 个协议类 skill 在 30-50 行（无 references / scripts / examples）——**短不是 bug，是设计**（协议类 vs 执行类有别），但**缺 examples 让 agent 不知道 artifact 长什么样**。

同时趁势加了 brevity 论文引用（之前评估 Caveman 时讨论过）。

### 已执行的变更

- [MOD] `output-styles/legion-dispatch.md`：在"极简"段加 brevity 论文引用（[Brevity Constraints Reverse Performance Hierarchies, 2026.3](https://juliusbrussee.github.io/caveman/) — 强制简洁 +26pp 准确率）
- [NEW] `skills/code-review-protocol/examples/sample-review-code.md`（OAuth 登录审查）
- [NEW] `skills/functional-test-protocol/examples/sample-review-functional.md`（并发 bug 验证）
- [NEW] `skills/quality-verdict/examples/sample-verdict-three-tiers.md`（PASS / CONDITIONAL PASS / BLOCKED 三档）
- [NEW] `skills/requirements-review-protocol/examples/sample-review-requirements.md`（5 处 Issue + 修复建议）
- [NEW] `skills/architecture-review-protocol/examples/sample-review-architecture.md`（6 维度 + Critical 处理）
- [MOD] 5 个对应 SKILL.md 末尾加"参考样品"段引用 examples

### 设计判断

不堆内容，**show > tell**。Anthropic 官方 docx/pptx/xlsx skill 都是这个模式：短 SKILL.md + 详细 references/examples。我们 review 类 skill 缺的就是这一层。

不动其他 13 个协议类 skill——它们各有 owner agent，使用频率较低，加 example 是 ROI 单位数收益。等数据驱动再说。

### 跟踪指标

- Skills 总数 47（不变）
- 5 个 review skill 现在都有 examples/
- 5 个 examples 平均 80 行，单文件足够 agent 直接当模板用

---

## 2026-04-25 · v3.1.2（外部素材深度合并 + skill-evals 拆除）

### 触发

用户提供 Anthropic Claude Design / Word / Excel / PowerPoint / Codex / Jules 公开行为协议素材 + 三个 GitHub skill 仓库（`thvroyal/kimi-skills` / `MiniMax-AI/skills` / `android/skills`）。要求"实地深读 + 合并到系统"，并指出 `skill-evals/` 作用不大可拆除。

### 已执行的变更

#### 拆除 skill-evals/
- [DEL] `skill-evals/`（之前是 phantom 目录，从未真正存在）
- [DEL] `bin/validate-skill-evals.sh` `bin/run-skill-eval-dryrun.sh`
- [MOD] `bin/doctor.sh` §11 改造：从 "Skill Evals" 改为 "Skill References & Examples" 覆盖率统计

#### 仓库实地研究（不只 WebFetch，全部 git clone 到 /tmp）
- `android/skills`（Apache 2.0 / Google LLC）：6 个真实 SKILL.md 全文读完——AGP 9 升级、Compose 迁移 10 步、Navigation 3、edge-to-edge、Play Billing、R8
- `MiniMax-AI/skills`（MIT, 11.2k stars）：17 skill 体量审计 + 关键 SKILL.md 全文读——`fullstack-dev` 1037 行 / `android-native-dev` 883 行 + 9 references / `ios-application-dev` 178 行 + 9 references / `frontend-dev` 570 行 + 10 references + 5 scripts
- `kimi-skills`（rights belong Moonshot AI）：仅结构研究，不复制内容

#### 5 份深度 references 合并落地（每份都标 attribution）
- [NEW] `skills/implementation-protocol/references/engineering-discipline.md` — 10 条工程纪律（综合自 Anthropic Word/Excel/PowerPoint agent + Codex + Jules）
- [NEW] `skills/docx-workflow/references/word-fidelity-traps.md` — 12 类 Word 保真陷阱（综合自 Anthropic Word agent）
- [NEW] `skills/xlsx-workflow/references/excel-financial-discipline.md` — Show Your Work + 颜色编码 + 财务建模规范（综合自 Anthropic Excel agent）
- [NEW] `skills/pptx-workflow/references/powerpoint-fidelity.md` — 字号 floor + slide master 5 项配齐 + AI slop 清单（综合自 Anthropic PowerPoint agent + Claude Design）
- [NEW] `skills/frontend-design-protocol/references/anti-slop-deeper.md` — AI slop 反模式 + design system fidelity + 多变体探索（综合自 Claude Design）

#### 移动端深度合并（用户最高频痛点）
- [NEW] `skills/mobile-development/references/ios-checklist.md` — UIKit/SwiftUI Quick Reference + 6 维度原则 + 完整 checklist（综合自 MiniMax MIT + Apple HIG，完整 attribution）
- [NEW] `skills/mobile-development/references/android-modern-stack.md` — Compose 迁移 10 步 + edge-to-edge + Navigation 3 + AGP 9 + R8 + Play Billing（综合自 Google Apache 2.0 android/skills + MiniMax MIT，完整 attribution）

#### 后端深度合并
- [NEW] `skills/backend-development/references/seven-iron-rules.md` — 7 条铁律 + 3 层架构 + Feature-First + 跨语言 DI 示例 + 启动/集成/生产 checklist + 反模式（综合自 MiniMax MIT fullstack-dev + 12-Factor + Clean Architecture + Fowler + Google SRE，完整 attribution）

#### 7 个 SKILL.md 末尾引用 references
- `skills/implementation-protocol/SKILL.md` 引用 engineering-discipline.md
- `skills/docx-workflow/SKILL.md` 引用 word-fidelity-traps.md
- `skills/xlsx-workflow/SKILL.md` 引用 excel-financial-discipline.md
- `skills/pptx-workflow/SKILL.md` 引用 powerpoint-fidelity.md
- `skills/frontend-design-protocol/SKILL.md` 引用 anti-slop-deeper.md
- `skills/mobile-development/SKILL.md` 引用 ios-checklist.md + android-modern-stack.md
- `skills/backend-development/SKILL.md` 引用 seven-iron-rules.md

### 版权与 attribution 边界

严格遵守 `rules/_global/external-skill-source-policy.md`：
- ✅ MIT / Apache 2.0 内容：可吸收方法论 + 跨语言示例，必须 attribution。来源（GitHub URL + 许可证）写在每个 references 顶部
- ❌ Anthropic 泄漏 prompt 原文：仅提炼**结构模式**，**不复制原文**，每个 references 都用我们自己的语言重写
- ❌ Kimi-skills（rights belong Moonshot AI）：仅结构研究，无内容引入

### 跟踪指标

- Skills: 47（不变）
- Rules: 47（不变）
- Hooks: 13（不变）
- 新增 references: **8 份**（implementation/docx/xlsx/pptx/frontend-design/mobile×2/backend）
- 总 references 行数：~2200 行实质方法论
- doctor §11 重构为 References & Examples 覆盖率指标

### 元观察

这是 Agent Legion 第一次把"外部世界经验"实质性合并进系统：
- 之前只在 `skills-research/external-prompt-sources.md` 做索引（不动作）
- 这一轮真正读完全文 + 提炼方法论 + 落地到 references + 标 attribution
- 系统从此能引用 Apple HIG / 12-Factor / Clean Architecture / Google SRE 等业界经典

不进 SKILL.md 主文件（保持入口短）+ 长资料按需读取——符合 Anthropic 官方 progressive disclosure 模式。

### 下次审查

仍约 2-3 周。新观察项：
- `references/seven-iron-rules.md` 在真实 backend PR review 中是否真被援引
- iOS/Android references 是否帮助 高级移动端工程师 减少返工
- 8 份 references 的实际触发率（需观察 doctor §11 覆盖率统计）

### 回退方式

```bash
git revert <本次 commit hash>
```

8 份 references 独立可删；7 个 SKILL.md 的引用段也可独立移除。

---

## 2026-04-25 · v3.1.3（patch · 整理清扫）

### 触发

3 个 Explore 并行审计后发现 v3.1.2 之后的小漂移和清理需求。Plan mode 经用户审批，定位为 patch 而非新版本。

### 已执行的变更

#### Phase 1：P0 清理

- [FIX] `README.md:63`：`13 种框架` → `18 种框架`（修历史漂移，文档实际值早已 18）
- [DEL] `agent-memory/quality-guardian/`（3 文件）：v1 后该 agent 已被删但 memory 残留。备份至 `/tmp/legion-cleanup-2026-04-25/`
- [ARCHIVE] `logs/instructions-loaded.jsonl`（1.3MB / 21964 行）→ `.legacy`：旧版 `jq -n`（无 `-c`）写入的多行美化数据，违反 JSONL 规范。新数据自动以正确格式重新累积
- [ARCHIVE] `logs/subagent-events.jsonl`（765KB / 910 行）→ `.legacy`：同上根因

#### Phase 2：选择性 when_to_use 补齐

给 9 个**自动触发场景明确**的 skill 加 `when_to_use` 字段（不是全部 38 个，避免堆料）：

- `architecture-patterns` — "架构设计 / 技术方案 / 模块边界"
- `db-patterns` — "加表 / 改字段 / 加索引 / 迁移"
- `backend-development` — "后端 / API / 服务 / controller / 中间件"
- `frontend-development` — "前端 / 组件 / 页面 / 动画 / React/Vue/Svelte"
- `mobile-development` — "iOS / Android / app / 原生 / Flutter / RN"
- `security-checklist` — "安全审查 / OWASP / 漏洞 / 鉴权 / SQL 注入 / XSS"
- `test-strategy` — "测试策略 / 测试金字塔 / 覆盖率"
- `documentation-protocol` — "写文档 / reference / 用户手册 / handover"
- `创意策划师-direction` — "取名 / slogan / 品牌调性 / 文案方向"

`api-guide` 已 `disable-model-invocation: true` 不需要 `when_to_use`，从清单移除。

其余 28 个缺 `when_to_use` 的 skill（`bcc-*` / 各类 protocol / project-knowledge-template）有明确 owner agent 显式预加载或手动调用，**不需要补**。

### 不做的事（明确边界）

- ❌ 不补全 38 个 skill 的 when_to_use（绝大多数不需要）
- ❌ 不强拆 6 个长 SKILL.md（200-500 行内容丰富不是 bug）
- ❌ 不改 CLAUDE.md 容量（196/200 行可接受）
- ❌ 不修复"冷 agent memory"（可能是真没业务，不是 prompt 问题，等数据驱动）
- ❌ 不动 v3.1.2 已固化的 9 份 references

### 跟踪指标

- Agents：25（不变）
- Skills：47（不变）
- Rules：47（不变）
- Hooks：13（不变）
- 新增 9 处 `when_to_use` 字段
- README.md 数字漂移 1 处修复
- 1 个孤儿 agent-memory 清理
- 2 个损坏 JSONL 归档

### 元观察

这是一次纯**清理类 patch**，无新机制。下次进化触发条件：积累 ≥10 真实分类样本 + ≥5 个完整流水线后再 `/bcc-evolve`。

### 回退方式

```bash
git revert <本次 commit hash>
```

`.legacy` 日志可保留备查或从 `/tmp/legion-cleanup-2026-04-25/` 恢复 quality-guardian memory。

---

## 2026-05-04 · v4.7（statusline 与调度闭环）

### 触发

用户要求修复 statusline 可用性，并补齐 `understanding / iteration / final_confirmation` 的强校验与入口闭环。

### 已执行的变更

- [FIX] `hooks/subagent-start-mark.sh`：active subagent 状态从 TSV 改为 JSON，记录 `session_id / agent_id / agent_type / started_at`
- [FIX] `hooks/subagent-stop-log.sh`：按 `agent_id` 精确清理 active 文件；缺失或不匹配时按同 session + agent_type 删除最老匹配项
- [FIX] `statusline.sh`：重排为两行布局，窄屏自动压缩标签、任务 ID 和多代理显示；自动清理明显陈旧的 active 文件
- [NEW] `bin/validate-dispatch-ticket.sh`：校验 `phase / gate_status / understanding / iteration / final_confirmation` 的合法组合
- [NEW] `rules/_global/release-version-consistency.md` / `runtime-state-git-hygiene.md` / `statusline-contract.md`：固化发布版本、运行态文件和 statusline 布局契约
- [NEW] `skills/release-checklist/SKILL.md`：发布前确定性检查清单
- [FIX] `bin/doctor.sh`：新增 Release Readiness 检查，覆盖版本漂移、README 数字徽章、hook 计数和 Git hygiene
- [FIX] `.gitignore`：忽略 settings 备份与 clarification pending 运行态文件
- [DOC] `README.md` / `CLAUDE.md` / `LEGION.md` / `output-styles/legion-dispatch.md`：统一 v4.7 文档版本，补充最终确认入口分类，移除诱导暴露原始思维链的 CoT/ToT 表述
- [DOC] `Task.md` / `progress-log.md` / `state/legion-session.json`：记录本轮 statusline 与 DispatchTicket 闭环升级证据

### 跟踪指标

- Agents：38
- Skills：58
- Rules：53
- Hooks：17 个主 hook + 3 个 `_lib` 辅助脚本
- `doctor.sh`：0 failures（仍有既有 warnings）

### 验证

```bash
bash -n statusline.sh hooks/subagent-start-mark.sh hooks/subagent-stop-log.sh hooks/clarification-gate.sh bin/validate-dispatch-ticket.sh
bin/validate-dispatch-ticket.sh state/legion-session.json
bin/test-hook-flags.sh
bin/validate-rules.sh
bin/doctor.sh
```

### 回退方式

```bash
git revert <本次 commit hash>
```
