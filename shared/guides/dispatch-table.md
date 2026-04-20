---
name: dispatch-table
description: 调度信号表单一真源 — 33 Agent 完整映射（CLAUDE.md 为精简索引，本文件为完整版）
guide: true
---

<harness-guide>
  <section id="dispatch-table">
    <title>调度信号表（单一真源）</title>
    <content>

> 本文件是调度信号表的**唯一完整版本**。`~/.claude/CLAUDE.md` 保留精简索引供快速查阅。
> 其他文件（output-style / governance）中的调度表已废弃，不再维护。

| 领域 | Agent 名称 | 文件名 | 模型 | 颜色 | 触发信号 | 指令类型 |
|------|-----------|--------|------|------|---------|---------|
| 外部输入 | 客户沟通师 | client.md | sonnet | orange | 客户聊天记录、售后反馈、售前提案 | 新建, 修改(需求) |
| 调度 | 项目管理师 | pm.md | opus | yellow | "下一步"、"推进到哪"、多步骤任务、信号不明 | 设计(拆解), 综合 |
| 设计 | 开发组长 | dev-lead.md | sonnet | orange | "技术方案"、"怎么实现"、"拆分到文件级" | 设计 |
| 设计 | 架构师 | architect.md | opus | blue | "整体架构"、"跨模块重构" | 设计 |
| 数据 | 数据库工程师 | database.md | sonnet | blue | "加表"、"改字段"、"迁移" | 设计, 新建, 修改 |
| 研究 | 技术调研师 | tech-research.md | sonnet | cyan | "A 和 B 哪个好"、"能不能用"、"定价" | 调研 |
| 研究 | 深度研究员 | researcher.md | opus | yellow | "文献综述"、"领域研究"、"深度竞品分析" | 研究, 调研 |
| 创意 | 创意策划师 | creative.md | sonnet | purple | "取名"、"Slogan"、"品牌调性"、"文案方向" | 创意, 新建 |
| 视觉 | 视觉设计师 | visual-designer.md | sonnet | purple | "设计系统"、"UI 规范"、"tokens"、"组件规范" | 设计 |
| 实现 | 后端开发师 | backend.md | sonnet | blue | "写接口"、"后端实现" | 新建, 修改, 修复 |
| 实现 | 前端开发师 | frontend.md | sonnet | cyan | "写页面"、"前端实现" | 新建, 修改, 修复 |
| 实现 | 小程序开发师 | miniprogram-dev.md | sonnet | cyan | "写小程序"、"uni-app"、"微信登录"、"分包" | 新建, 修改, 修复 |
| 实现 | 机器学习工程师 | ml-engineer.md | opus | blue | "训练模型"、"推理部署"、"算法项目" | 训练, 新建, 修改, 修复 |
| 审查 | 代码审计师 | code-review.md | sonnet | red | "审代码"、"code review" | 审查 |
| 安全 | 安全审计师 | security-auditor.md | sonnet | red | "安全审计"、"上线前检查"、"OWASP" | 审查 |
| 测试 | 功能测试师 | test-func.md | sonnet | red | "测功能"、"走主流程" | 测试 |
| 测试 | 界面测试师 | test-ui.md | haiku | red | "截图"、"看界面"、"交互校验" | 测试 |
| 裁决 | 测试总监师 | test-lead.md | opus | red | "能不能验收"、"裁决" | 审查 |
| 部署 | 运维部署工程师 | devops.md | sonnet | blue | "部署"、"Dockerfile"、"上线" | 部署 |
| 文档 | 文档工程师 | doc-writer.md | sonnet | orange | "写 API 文档"、"用户手册"、"论文草稿" | 文档 |
| 元工程 | 提示词工程师 | prompt-engineer.md | sonnet | orange | "改 prompt"、"调 agent 规格"、"agent 跑偏" | 修改 |
| 进度 | 进度管理师 | scrum-master.md | sonnet | orange | "Sprint"、"站会"、"阻塞"、"燃尽图"、"进度风险" | 综合 |
| 实现 | iOS 开发师 | ios-dev.md | sonnet | orange | "iOS"、"Swift"、"SwiftUI"、"UIKit"、"App Store 上架"、"TestFlight"、"Core Data" | 新建, 修改, 修复 |
| 实现 | Android 开发师 | android-dev.md | sonnet | orange | "Android"、"Kotlin"、"Jetpack Compose"、"Google Play"、"FCM"、"NDK"、"安卓" | 新建, 修改, 修复 |
| 实现 | 跨平台移动开发师 | crossplatform-mobile-dev.md | sonnet | cyan | "Flutter"、"React Native"、"跨平台"、"Dart"、"双端"、"Fastlane"、"Codemagic" | 新建, 修改, 修复 |
| 实现 | 嵌入式开发师 | embedded-dev.md | sonnet | green | "嵌入式"、"STM32"、"ESP32"、"FreeRTOS"、"Zephyr"、"RTOS"、"驱动开发"、"OTA 固件"、"低功耗" | 新建, 修改, 修复 |
| 实现 | 鸿蒙开发师 | harmonyos-dev.md | sonnet | green | "鸿蒙"、"HarmonyOS"、"ArkTS"、"ArkUI"、"AppGallery"、"原子化服务"、"分布式" | 新建, 修改, 修复 |
| 实现 | 桌面端开发师 | desktop-dev.md | sonnet | cyan | "Electron"、"Tauri"、"Qt"、"桌面应用"、"桌面端"、"macOS 应用"、"自动更新" | 新建, 修改, 修复 |
| 仿真 | 仿真工程师 | simulation-engineer.md | sonnet | green | "Simulink"、"HIL"、"SIL"、"Unity 仿真"、"Unreal 仿真"、"数字孪生"、"MATLAB 仿真" | 新建, 修改, 调研 |
| 数据 | 数据工程师 | data-engineer.md | sonnet | blue | "ETL"、"数仓"、"Spark"、"Flink"、"Airflow"、"ClickHouse"、"BigQuery"、"数据管道" | 新建, 修改, 设计 |
| AI 情报 | AI 领航大师 | ai-navigator.md | opus | magenta | "AI 框架"、"模型选型"、"DeepSeek"、"LangChain"、"Qwen"、"AI 行业动态"、"prompt 范式" | 调研, 研究 |
| 实现 | AI编排大师 | workflow-orchestrator.md | sonnet | cyan | "n8n"、"工作流编排"、"Dify"、"Coze"、"LangFlow"、"Flowise"、"自动化工作流" | 新建, 修改, 修复 |
| 版本控制 | Git 版本控制大师 | git-master.md | haiku | yellow | "rebase"、"squash commits"、"cherry-pick"、"bisect"、"git history"、"conflict resolution"、"branch strategy"、"prepare PR"、"tag release" | 修改, 修复, 审查 |

<h3>信号不明时的默认路由</h3>
<p>信号不匹配任何触发关键词时，默认派 <strong>项目管理师</strong> 做判断。PM 有责任在 3 轮内识别出正确调度路径。</p>

<h3>PM vs 进度管理师 的区分规则</h3>
<ul>
<li>项目管理师（pm）：Task 生命周期管理（"做不做/谁做/何时做"）、需求拆解、调度判断、冲突裁决</li>
<li>进度管理师（scrum-master）：Sprint 节奏管理（"站会/燃尽图/阻塞跟踪/进度风险预警"），不负责调度判断</li>
<li>区分信号：用户提到"Task/任务/需求/方案"→ 项目管理师；用户提到"Sprint/迭代/站会/燃尽图"→ scrum-master</li>
</ul>

    </content>
  </section>
</harness-guide>
