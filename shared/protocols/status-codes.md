---
name: status-codes
description: 任务状态机定义 v1.1
protocol: true
---

<harness-protocol>
  <section id="main-flow">
    <title>主状态流转</title>
    <content>
<p>待分析 → 需求已明确 → 方案设计中 → 方案已完成 → 开发中 → 开发完成待审查
→ 审查中 → 审查通过待测试 → 测试中 → 测试通过 → 已交付</p>
    </content>
  </section>

  <section id="research-creative-flow">
    <title>研究/创意型 Task 的旁路流转</title>
    <content>
<p>对于以下非实现型 Task，采用简化流转：</p>

<ul>
<li>研究型：待分析 → 研究进行中 → 研究完成 → 已交付</li>
<li>创意型：待分析 → 创意进行中 → 创意完成 → 已交付</li>
<li>调研型：待分析 → 调研进行中 → 调研完成 → 已交付</li>
</ul>

<p>这类 Task 不强制进入代码审查/测试链路，但必须通过 <code>doc-writer</code> 或 PM 做最终归档。</p>
    </content>
  </section>

  <section id="ml-flow">
    <title>机器学习 Task 的扩展流转</title>
    <content>
<p>待分析 → 需求已明确 → 数据与方案设计中 → 训练中 → 评估中 → 训练完成待审查
→ 审查中 → 审查通过待集成测试 → 测试中 → 测试通过 → 已交付</p>

<p>说明：</p>
<ul>
<li>训练中：ml-engineer 正在跑训练/调参</li>
<li>评估中：ml-engineer 基于指标做模型对比和失败案例分析</li>
<li>审查中：code-review 审查训练/推理代码；test-lead 审查指标结论</li>
<li>集成测试：test-func 验证推理接口的业务语义是否正确</li>
</ul>
    </content>
  </section>

  <section id="rollback">
    <title>回退状态（对抗机制触发）</title>
    <content>
<p>审查中 → 审查未通过-待修复 → 开发中/训练中（修复后重新进入审查）
测试中 → 测试未通过-待修复 → 开发中/训练中（修复后重新进入审查和测试）</p>
    </content>
  </section>

  <section id="state-detail">
    <title>状态详细说明</title>
    <content>
<table>
<tr><th>状态</th><th>含义</th><th>进入条件</th><th>退出条件</th></tr>
<tr><td>待分析</td><td>Task 已创建但需求未明确</td><td>项目管理师创建 Task 时</td><td>项目管理师完成业务描述</td></tr>
<tr><td>需求已明确</td><td>业务描述已完成</td><td>项目管理师编写完业务描述</td><td>项目管理师调用下游角色</td></tr>
<tr><td>方案设计中</td><td>dev-lead/architect 正在设计</td><td>设计角色被调用</td><td>设计角色返回 SUCCESS</td></tr>
<tr><td>方案已完成</td><td>技术方案就绪，可以开始开发</td><td>设计角色完成方案</td><td>项目管理师调用开发 Agent</td></tr>
<tr><td>数据与方案设计中</td><td>ml-engineer/dev-lead 正在设计数据路线和模型选择</td><td>机器学习 Task 进入设计</td><td>设计完成</td></tr>
<tr><td>训练中</td><td>ml-engineer 正在跑模型训练</td><td>训练启动</td><td>训练完成并有初步指标</td></tr>
<tr><td>评估中</td><td>ml-engineer 正在做指标评估和 case 分析</td><td>训练完成</td><td>评估报告产出</td></tr>
<tr><td>研究进行中</td><td>researcher 在做深度研究</td><td>researcher 被调用</td><td>研究报告产出</td></tr>
<tr><td>创意进行中</td><td>creative 在做命名/文案/视觉方向</td><td>creative 被调用</td><td>创意提案产出</td></tr>
<tr><td>调研进行中</td><td>tech-research 在做技术选型验证</td><td>tech-research 被调用</td><td>调研报告产出</td></tr>
<tr><td>开发中</td><td>开发 Agent 正在编写代码</td><td>开发 Agent 被调用</td><td>开发 Agent 返回 SUCCESS</td></tr>
<tr><td>开发完成待审查</td><td>代码已写完，等待审查</td><td>开发 Agent 完成</td><td>项目管理师调用代码审查</td></tr>
<tr><td>审查中</td><td>代码审计师 正在审查</td><td>代码审计师 被调用</td><td>代码审计师 返回</td></tr>
<tr><td>审查未通过-待修复</td><td>审查发现问题，需要修复</td><td>代码审查发现问题</td><td>开发 Agent 修复后重新提交</td></tr>
<tr><td>审查通过待测试</td><td>代码审查通过，等待测试</td><td>代码审查返回通过</td><td>项目管理师调用测试 Agent</td></tr>
<tr><td>测试中</td><td>测试 Agent 正在执行测试</td><td>测试 Agent 被调用</td><td>测试总监师做出判定</td></tr>
<tr><td>测试未通过-待修复</td><td>测试未通过，需修复</td><td>测试总监师判定打回</td><td>开发 Agent 修复后重走流程</td></tr>
<tr><td>测试通过</td><td>所有测试和 UI 审查通过</td><td>测试总监师判定通过</td><td>项目管理师标记完成</td></tr>
<tr><td>研究完成/创意完成/调研完成</td><td>对应非实现 Task 的完成态</td><td>对应 Agent 返回 SUCCESS</td><td>PM 归档</td></tr>
<tr><td>已交付</td><td>已交付客户</td><td>项目管理师确认交付</td><td>-</td></tr>
</table>
    </content>
  </section>

  <section id="key-rules">
    <title>关键规则</title>
    <content>
<ol>
<li>状态只能前进或在特定对抗节点回退，不能跳跃。不能从"待分析"直接跳到"开发中"。</li>
<li>回退时必须在 Task 文件的"迭代记录"部分记录回退原因，这些记录不可删除。</li>
<li>测试未通过回退时，Task 状态回到"开发中"而不是"审查通过待测试"，因为修复后必须重新经过代码审查。这是对抗机制的核心：每次修复都要重新接受审查和测试的双重检验。</li>
<li>研究/创意/调研型 Task 不走对抗流转，但必须由 PM 或 doc-writer 做最终归档，否则知识会遗失。</li>
<li>机器学习 Task 的"评估中"阶段不可省略。未经过失败案例分析就上线的模型视为方案不完整。</li>
</ol>
    </content>
  </section>

  <section id="test-ui-skip">
    <title>test-ui 的跳过条件</title>
    <content>
<p>以下情况下，PM 在"下一步调度"中可明确跳过 test-ui：</p>

<ul>
<li>纯后端 API 修改，无任何前端界面变化</li>
<li>纯配置文件、CI、脚本、迁移脚本变更</li>
<li>纯文档、注释、命名修改</li>
<li>纯模型训练/推理代码（ML 型 Task），无前端展示</li>
</ul>

<p>跳过时，PM 必须在"特殊说明"字段写明跳过理由。未写明跳过理由的，主进程默认仍调用 界面测试师。</p>
    </content>
  </section>
</harness-protocol>
