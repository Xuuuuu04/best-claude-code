---
name: bcc-deploy
description: 一键部署流程——构建、测试、部署到目标环境
disable-model-invocation: true
argument-hint: "[environment]"
---

## 部署流程

参数：`$0` = 目标环境（staging / production），默认 staging

1. 确认当前分支和未提交变更状态
2. 运行完整测试套件：`!`npm test` || `!`go test ./...` || `!`pytest` 等（根据项目自动检测）`
3. 检查构建是否成功
4. 确认目标环境配置正确
5. 执行部署命令
6. 验证部署结果（健康检查 / 冒烟测试）
7. 输出部署报告

如果任何步骤失败，立即停止并报告失败原因。
