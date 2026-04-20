---
name: task-input-protocol
description: 任务输入协议 v1.1
protocol: true
---

<harness-protocol>
  <section id="format">
    <title>指令格式</title>
    <content>
<pre>
---
**指令类型**: [新建 | 修改 | 修复 | 审查 | 测试 | 设计 | 调研 | 文档 | 部署 | 训练 | 研究 | 创意]
**目标项目**: [项目目录名或绝对路径，如 project-alpha 或 /Users/foo/workspace/project-alpha]
**任务文件**: [Task 文件的相对路径，如 projects/project-alpha/tasks/TASK-001-user-login.md]
**项目上下文**: [项目 CLAUDE.md 路径，如 projects/project-alpha/CLAUDE.md]
**关联文件**: [需要额外阅读的文件路径列表，每行一个]
**紧急程度**: [常规 | 加急]
**特殊说明**: [任何补充信息，可为空]
---
</pre>
    </content>
  </section>

  <section id="fields">
    <title>字段说明</title>
    <content>
<ul>
<li><strong>指令类型</strong> 决定了 Agent 应该执行的动作类别。Agent 应只接受与自身职责匹配的指令类型。</li>
<li><strong>目标项目</strong> 必填。用于定位项目根目录。Agent 读取该目录下的 CLAUDE.md、TASK.md、progress-log.md 以获取项目上下文。</li>
<li><strong>任务文件</strong> 是 Agent 的核心工作对象，Agent 必须完整阅读此文件后再开始工作。</li>
<li><strong>项目上下文</strong> 帮助 Agent 理解项目的宏观背景，Agent 应阅读其中的项目概况和技术栈部分。</li>
<li><strong>关联文件</strong> 包含 Agent 完成任务所需的补充信息，如架构文档、代码规范、之前的审查记录等。Agent 必须在开始工作前阅读所有关联文件。</li>
<li><strong>紧急程度</strong> 为"加急"时，Agent 应优先处理且在摘要中注明。</li>
</ul>
    </content>
  </section>

  <section id="agent-matching">
    <title>Agent 与指令类型的匹配关系</title>
    <content>
<table>
<tr><th>Agent</th><th>接受的指令类型</th></tr>
<tr><td>客户沟通师（client）</td><td>新建, 修改（仅需求层面）</td></tr>
<tr><td>项目管理师（pm）</td><td>设计（拆解 Task）、其他（综合调度）</td></tr>
<tr><td>开发组长（dev-lead）</td><td>设计</td></tr>
<tr><td>架构师（architect）</td><td>设计</td></tr>
<tr><td>后端开发师（backend）</td><td>新建, 修改, 修复</td></tr>
<tr><td>前端开发师（frontend）</td><td>新建, 修改, 修复</td></tr>
<tr><td>数据库工程师（database）</td><td>设计, 新建, 修改</td></tr>
<tr><td>代码审计师（code-review）</td><td>审查</td></tr>
<tr><td>功能测试师（test-func）</td><td>测试</td></tr>
<tr><td>界面测试师（test-ui）</td><td>测试</td></tr>
<tr><td>测试总监师（test-lead）</td><td>审查</td></tr>
<tr><td>技术调研师（tech-research）</td><td>调研</td></tr>
<tr><td>深度研究员（researcher）</td><td>研究, 调研</td></tr>
<tr><td>机器学习工程师（ml-engineer）</td><td>训练, 新建, 修改, 修复</td></tr>
<tr><td>创意策划师（creative）</td><td>创意, 新建</td></tr>
<tr><td>运维部署工程师（devops）</td><td>部署</td></tr>
<tr><td>文档工程师（doc-writer）</td><td>文档</td></tr>
<tr><td>小程序开发师（miniprogram-dev）</td><td>新建, 修改, 修复</td></tr>
<tr><td>视觉设计师（visual-designer）</td><td>设计</td></tr>
<tr><td>提示词工程师（prompt-engineer）</td><td>修改</td></tr>
<tr><td>安全审计师（security-auditor）</td><td>审查</td></tr>
<tr><td>进度管理师（scrum-master）</td><td>综合</td></tr>
</table>
    </content>
  </section>

  <section id="fast-path">
    <title>快速路径例外</title>
    <content>
<p>主进程在满足以下全部条件时可跳过 PM，直接调用下游专职 Agent：</p>

<ol>
<li>改动粒度明确为"单文件、局部修改"（例如改一行文案、调一个样式值、修一个显而易见的小 bug）</li>
<li>不涉及新增 API、数据库字段或业务规则</li>
<li>用户已在主进程输入中明确描述完整上下文</li>
</ol>

<p>跳过 PM 时仍必须在根 <code>Task.md</code> 留痕，并在后续发现改动超出"轻量"范围时立即回到标准链路。</p>
    </content>
  </section>
</harness-protocol>
