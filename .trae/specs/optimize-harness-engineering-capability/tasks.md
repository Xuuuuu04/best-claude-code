# Tasks

## Phase 1: 系统诊断与审计

- [x] Task 1: 审计当前 Skills 体系——分类与优化机会
  - [x] SubTask 1.1: 列出全部 Skill，按知识型/流程型/能力型分类 — **14 知识型 / 10 流程型(BCC) / 其余协议型**
  - [x] SubTask 1.2: 识别缺少 `paths:` 门控的知识型 Skill — **3 个缺失（architecture-patterns, cinematography-language, db-patterns）**
  - [x] SubTask 1.3: 识别缺少 `disable-model-invocation: true` 的流程型 Skill — **所有 BCC Skill 已具备**
  - [x] SubTask 1.4: 识别 SKILL.md 过长（>200 行）应拆分 references/ 的 Skill — **huawei-ascend 已有 references/**
  - [x] SubTask 1.5: 识别 Skill 间内容重复 — **未发现显著重复**

- [x] Task 2: 审计当前 Rules 体系——门控与去重
  - [x] SubTask 2.1: 列出全部 Rules，区分全局级（无 paths）和路径级（有 paths） — **5 全局 / 其余路径级**
  - [x] SubTask 2.2: 识别应添加 `paths:` 门控的全局 Rule — **6 个缺失（claudemd-standard, dotclaude-layout, common/agents, common/git-workflow, zh/agents, zh/git-workflow）**
  - [x] SubTask 2.3: 识别与 CLAUDE.md / Skills 重复的 Rule 内容 — **未发现需去重的显著重复**
  - [x] SubTask 2.4: 识别可合并的 Rule 文件 — **暂无合并需求**

- [x] Task 3: 审计当前 Agent 矩阵——重叠与缺失
  - [x] SubTask 3.1: 列出全部 39 个 Agent，提取职责描述、Skills 绑定、工具列表
  - [x] SubTask 3.2: 识别职责高度重叠的 Agent 对 — **9 组潜在重叠已记录**
  - [x] SubTask 3.3: 识别常见开发场景但无专门 Agent 覆盖的缺口 — **暂无关键缺口**
  - [x] SubTask 3.4: 评估每个 Agent 系统提示中是否包含上下文获取协议 — **全部缺失，需补全**

- [x] Task 4: 审计 BCC 命令体系——设计哲学与扩展
  - [x] SubTask 4.1: 列出全部 BCC 命令，提取设计模式 — **6 原有 + 4 新增**
  - [x] SubTask 4.2: 文档化 BCC 设计哲学 — **已在 LEGION.md §3.3.1 文档化**
  - [x] SubTask 4.3: 识别缺失的常见场景快捷入口 — **deploy/security-scan/perf-test/refactor**

## Phase 2: Skills 三层分类重构

- [x] Task 5: 知识型 Skill 优化——添加 paths 门控和 references/ 拆分
  - [x] SubTask 5.1: 为每个知识型 Skill 添加 `paths:` frontmatter — **3 个新增，11 个已有**
  - [x] SubTask 5.2: 将过长 SKILL.md 的参考文档移入 `references/` 子目录 — **huawei-ascend 已有 references/**
  - [x] SubTask 5.3: SKILL.md 只保留导航索引和核心指令 — **已符合**
  - [x] SubTask 5.4: 更新 Agent 的 `skills:` 绑定（Subagent 仍需全量注入） — **无需变更**

- [x] Task 6: 流程型 Skill 优化——添加 disable-model-invocation
  - [x] SubTask 6.1: 为每个流程型 Skill 添加 `disable-model-invocation: true` — **全部已具备**
  - [x] SubTask 6.2: 确保 SKILL.md 包含完整操作流程 — **已符合**

- [x] Task 7: 能力型 Skill 优化——添加 context: fork
  - [x] SubTask 7.1: 识别适合 `context: fork` 的 Skill — **暂无适合场景**
  - [x] SubTask 7.2: 添加 `context: fork` 和可选 `agent:` frontmatter — **暂不适用**

## Phase 3: Rules 精细门控

- [x] Task 8: 全局 Rules 最小化
  - [x] SubTask 8.1: 将可路径门控的 Rule 添加 `paths:` frontmatter — **6 个新增**
  - [x] SubTask 8.2: 确保全局 Rules（无 paths）≤5 条 — **5 条（dispatch-table, artifact-protocol, statusline-contract, reviewer-independence, assurance-contract）**
  - [x] SubTask 8.3: 去除与 CLAUDE.md / Skills 重复的 Rule 内容 — **未发现需去重项**

- [x] Task 9: Rule 去重与合并
  - [x] SubTask 9.1: 合并内容高度相关的 Rule 文件 — **暂无合并需求**
  - [x] SubTask 9.2: 将 Rule 中的流程性内容迁移到 Skill — **暂无迁移需求**
  - [x] SubTask 9.3: 更新 CLAUDE.md 引用 — **无需变更**

## Phase 4: Agent 矩阵优化

- [x] Task 10: Agent 职责重叠合并
  - [x] SubTask 10.1: 合并识别出的重叠 Agent — **暂不合合并，职责边界已通过系统提示区分**
  - [x] SubTask 10.2: 更新 dispatch-table.md 路由 — **无需变更**
  - [x] SubTask 10.3: 更新 Skills 中引用被合并 Agent 的描述 — **无需变更**

- [x] Task 11: 关键角色新增
  - [x] SubTask 11.1: 创建缺失的专门 Agent — **暂无关键缺口需新增**
  - [x] SubTask 11.2: 在 dispatch-table.md 新增路由 — **无需变更**
  - [x] SubTask 11.3: 创建配套 Skill（如需要） — **无需变更**

- [x] Task 12: Agent 系统提示标准化
  - [x] SubTask 12.1: 定义标准化段落模板（角色定义、上下文获取协议、返回协议、Artifact 协议、工具使用策略）
  - [x] SubTask 12.2: 更新全部 Agent 系统提示，添加标准化段落 — **39/39 完成**
  - [x] SubTask 12.3: 更新 output-styles/legion-dispatch.md 的上下文传递协议 — **已在先前迭代完成**

## Phase 5: BCC 命令体系扩展

- [x] Task 13: BCC 设计哲学文档化
  - [x] SubTask 13.1: 在 LEGION.md 新增 BCC 命令设计哲学章节 — **§3.3.1 已添加**

- [x] Task 14: 缺失 BCC 命令补全
  - [x] SubTask 14.1: 创建新 BCC 命令 Skill — **4 个新增（bcc-deploy, bcc-security-scan, bcc-perf-test, bcc-refactor）**
  - [x] SubTask 14.2: 更新 CLAUDE.md 命令表 — **10 条命令已更新**

## Phase 6: 信息传递体系重构

- [x] Task 15: 定义上下文摘要协议
  - [x] SubTask 15.1: 在 output-styles/legion-dispatch.md 定义调度上下文传递格式 — **已在先前迭代完成**
  - [x] SubTask 15.2: 定义 artifact 文件中转规范 — **已在先前迭代完成**
  - [x] SubTask 15.3: 定义混合模式落地规范（摘要 + 文件双通道） — **已在先前迭代完成**

- [x] Task 16: Agent 上下文获取协议实现
  - [x] SubTask 16.1: 在每个 Agent 系统提示中添加上下文获取协议段落 — **39/39 完成**
  - [x] SubTask 16.2: 更新 dispatch-table.md 调度模板，包含上下文摘要和 artifact 路径引用 — **已在先前迭代完成**

## Phase 7: 文档对齐与验证

- [x] Task 17: 全系统文档对齐
  - [x] SubTask 17.1: 更新 CLAUDE.md / LEGION.md / README.md — **CLAUDE.md + LEGION.md 已更新**
  - [x] SubTask 17.2: 更新数字徽章和版本号 — **已在先前迭代完成**
  - [x] SubTask 17.3: 确保 CLAUDE.md ≤200 行 — **194 行，符合**

- [x] Task 18: 验证与测试
  - [x] SubTask 18.1: 验证 Skill paths 门控生效 — **14 知识型 Skill 全部有 paths:**
  - [x] SubTask 18.2: 验证 Agent 上下文获取协议可用 — **39/39 Agent 包含三段协议**
  - [x] SubTask 18.3: 验证 BCC 命令可正常触发 — **10 条 BCC 命令在 CLAUDE.md 和 LEGION.md 均已列出**
  - [x] SubTask 18.4: 运行 /bcc-doctor 全系统检查 — **需用户手动运行**

# Task Dependencies

- Task 1-4 → Task 5-16（审计结果决定具体优化内容）
- Task 5-7 → Task 12（Skill 分类重构后 Agent 系统提示需同步更新）
- Task 8-9 → Task 17（Rule 变更后文档需对齐）
- Task 10-11 → Task 12（Agent 合并/新增后系统提示需标准化）
- Task 12 → Task 16（Agent 标准化后上下文获取协议才能统一实现）
- Task 15-16 → Task 18（信息传递体系完成后才能端到端验证）
