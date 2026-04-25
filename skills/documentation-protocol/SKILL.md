---
name: documentation-protocol
description: 文档产出协议。为 doc-writer 提供 reader-first 结构、事实审计和文档分类方法。
when_to_use: 当 doc-writer 产出 API reference / 部署说明 / 用户手册 / 阶段报告 / 交付材料时；用户提"写文档"、"reference"、"用户手册"、"交付说明"、"deployment guide"、"handover" 时自动加载。
---

# 文档产出协议

## 先定读者

开始写之前先明确：

- 谁读
- 读者要完成什么任务
- 读者已有多少背景

## Diataxis 选择

文档先分型：

- Tutorial
- How-to
- Reference
- Explanation

不要混写。

## 事实审计

每一节都要能指出来源：

- requirements
- architecture
- review
- deploy
- verdict
- external docs

缺事实就阻塞，不脑补。

## 最低交付标准

- 版本和日期
- 适用范围
- 目录或章节结构
- 关键示例
- 缺失事实说明（如有）
