# Skill 架构规范

## 官方兼容

- 每个 Skill 必须是一个目录，入口文件为 `SKILL.md`。
- `SKILL.md` 必须包含 YAML frontmatter，至少写 `name` 与 `description`。
- `description` 前置触发条件，必要时补 `when_to_use`，两者合计保持精确，避免泛化触发。
- 长参考、模板、示例和脚本放到 supporting files，如 `references/`、`examples/`、`scripts/`。
- 主 `SKILL.md` 应作为导航和短协议，避免超过 500 行。

## Agent Legion 约束

- 用户级 Skill 不得包含具体项目事实；项目事实写入项目级 `.claude/skills/project-knowledge/`。
- 文件类 Skill 必须包含验证步骤和输出路径汇报要求。
- 审查类 Skill 必须区分 `BLOCKED / FAILED / WARNING / PASS`。
- 外部泄漏 prompt 只能转化为结构模式，不得复制原文。
- 新 Skill 接入 Agent 前，先检查预加载行数预算；默认通过自动触发优于无差别预加载。
