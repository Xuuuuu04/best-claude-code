---
name: project-knowledge-template
description: 项目知识库模板。仅供 /bcc-init-project 和 /bcc-update-memory 在具体项目的 .claude/skills/project-knowledge/ 中生成项目级知识，不应承载用户级具体项目事实。
disable-model-invocation: true
---

<skill name="project-knowledge-template" domain="项目知识库" mode="template" target-path="<project>/.claude/skills/project-knowledge/SKILL.md">

<knowledge type="usage" id="role-and-scope">
本 Skill 是模板，不是运行时项目知识。具体项目的知识必须写入该项目目录：

```text
<project>/.claude/skills/project-knowledge/SKILL.md
```
</knowledge>

<reference type="required-structure" id="template-fields">
## 必填结构

```markdown
---
name: project-knowledge
description: {项目名} 项目级知识库。包含技术栈、模块结构、关键命令、API/数据模型摘要和变更日志。由 /bcc-update-memory 维护。
---

# 项目知识库：{项目名}

## 项目身份
- 名称：
- 一句话描述：
- 主要用户 / 场景：

## 技术栈
- 语言 / 运行时：
- 框架 / 库：
- 构建 / 测试 / 部署：

## 模块结构
- {模块}：{职责 / 入口 / 关键文件}

## 接口与数据
- API 摘要：
- 数据模型摘要：
- 外部依赖：

## 运行命令
- 安装：
- 开发：
- 测试：
- 构建：

## 变更日志
- {日期}：{更新摘要}
```
</reference>

<checklist id="constraints" type="guardrails">
## 约束

- 不要把具体项目事实写入用户级 `~/.claude/skills/`。
- 不要写入密钥、token、客户隐私或生产凭据。
- 内容应短而准；长 API 文档放项目 `docs/`，这里只保留索引。
</checklist>

</skill>
