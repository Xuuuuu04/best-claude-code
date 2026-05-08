# Checklist

## Phase 1: 系统诊断与审计

- [x] 全部 Skill 已按知识型/流程型/能力型分类并记录
- [x] 缺少 `paths:` 门控的知识型 Skill 已识别（3 个）
- [x] 缺少 `disable-model-invocation: true` 的流程型 Skill 已识别（0 个缺失）
- [x] SKILL.md 过长（>200 行）应拆分 references/ 的 Skill 已识别
- [x] Skill 间内容重复已识别
- [x] 全部 Rules 已区分全局级和路径级
- [x] 应添加 `paths:` 门控的全局 Rule 已识别（6 个）
- [x] 与 CLAUDE.md / Skills 重复的 Rule 内容已识别
- [x] 可合并的 Rule 文件已识别
- [x] 全部 39 个 Agent 职责描述、Skills 绑定、工具列表已提取
- [x] 职责高度重叠的 Agent 对已识别（9 组）
- [x] 常见开发场景但无专门 Agent 覆盖的缺口已识别
- [x] BCC 设计哲学已文档化
- [x] 缺失的常见场景快捷入口已识别

## Phase 2: Skills 三层分类重构

- [x] 知识型 Skill 已添加 `paths:` frontmatter（14/14）
- [x] 过长 SKILL.md 的参考文档已移入 `references/` 子目录
- [x] SKILL.md 只保留导航索引和核心指令
- [x] Agent 的 `skills:` 绑定已更新
- [x] 流程型 Skill 已添加 `disable-model-invocation: true`（10/10）
- [x] 能力型 Skill 已评估（暂无适合 context: fork 场景）

## Phase 3: Rules 精细门控

- [x] 可路径门控的 Rule 已添加 `paths:` frontmatter（6 个新增）
- [x] 全局 Rules（无 paths）≤5 条（5 条）
- [x] 与 CLAUDE.md / Skills 重复的 Rule 内容已去重
- [x] 内容高度相关的 Rule 文件已评估（暂无合并需求）
- [x] Rule 中的流程性内容已评估（暂无迁移需求）

## Phase 4: Agent 矩阵优化

- [x] 职责重叠的 Agent 已评估（暂不合并，职责边界已通过系统提示区分）
- [x] dispatch-table.md 路由已评估（无需变更）
- [x] 缺失的专门 Agent 已评估（暂无关键缺口）
- [x] 全部 Agent 系统提示已添加标准化段落（39/39：上下文获取协议、返回协议、Artifact 协议）

## Phase 5: BCC 命令体系扩展

- [x] BCC 设计哲学已在 LEGION.md §3.3.1 文档化
- [x] 缺失 BCC 命令已补全（4 个新增：bcc-deploy, bcc-security-scan, bcc-perf-test, bcc-refactor）
- [x] CLAUDE.md 命令表已更新（10 条命令）

## Phase 6: 信息传递体系重构

- [x] 调度上下文传递格式已定义（legion-dispatch.md）
- [x] artifact 文件中转规范已定义
- [x] 混合模式落地规范已定义（摘要 + 文件双通道）
- [x] 每个 Agent 系统提示已添加上下文获取协议段落（39/39）
- [x] dispatch-table.md 调度模板已包含上下文摘要和 artifact 路径引用

## Phase 7: 文档对齐与验证

- [x] CLAUDE.md / LEGION.md 已更新
- [x] 数字徽章和版本号已对齐
- [x] CLAUDE.md ≤200 行（194 行）
- [x] Skill paths 门控验证通过（14 知识型 Skill 全部有 paths:）
- [x] Agent 上下文获取协议验证通过（39/39）
- [x] BCC 命令触发验证通过（10 条命令已列出）
- [ ] /bcc-doctor 全系统检查（需用户手动运行）
