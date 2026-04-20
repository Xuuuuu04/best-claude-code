---
name: project-claudemd-template
description: 项目 CLAUDE.md 模板
template: true
---

<harness-template>
  <section id="overview">
    <title>项目概况</title>
    <content>
<ul>
<li>客户: {客户信息}</li>
<li>一句话描述: {项目做什么}</li>
<li>报价: {报价金额}</li>
<li>时间线: {起止时间}</li>
<li>当前阶段: {需求分析|设计|开发|测试|交付|售后}</li>
</ul>
    </content>
  </section>

  <section id="tech-stack">
    <title>技术栈</title>
    <content>
<ul>
<li>后端: {语言 + 框架}</li>
<li>前端: {框架}</li>
<li>数据库: {数据库类型}</li>
<li>部署: {部署方式}</li>
</ul>
    </content>
  </section>

  <section id="directory">
    <title>目录结构</title>
    <content>
<p>（由项目管理师在首次初始化时填写，后续按需更新）</p>
    </content>
  </section>

  <section id="architecture-decisions">
    <title>关键架构决策</title>
    <content>
<p>（由架构师Agent产出后，项目管理师更新到此处）</p>
    </content>
  </section>

  <section id="progress">
    <title>进度摘要</title>
    <content>
<p>（项目管理师定期根据progress-log.md更新的高层摘要）</p>
    </content>
  </section>

  <section id="references">
    <title>引用</title>
    <content>
<ul>
<li>需求文档: @docs/requirements/client-brief.md</li>
<li>架构设计: @docs/architecture/system-design.md</li>
<li>任务索引: @tasks/TASK.md</li>
</ul>
    </content>
  </section>
</harness-template>
