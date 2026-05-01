---
name: documentation-protocol
description: 文档产出协议。为 doc-writer 提供 reader-first 结构、事实审计和文档分类方法。
when_to_use: 当 doc-writer 产出 API reference / 部署说明 / 用户手册 / 阶段报告 / 交付材料时；用户提"写文档"、"reference"、"用户手册"、"交付说明"、"deployment guide"、"handover" 时自动加载。
---

<skill name="documentation-protocol">

<knowledge domain="reader-first">
<principle>开始写之前先明确三个问题</principle>
<checklist>
  <item>谁读</item>
  <item>读者要完成什么任务</item>
  <item>读者已有多少背景</item>
</checklist>
</knowledge>

<knowledge domain="diataxis">
<principle>文档先分型，不要混写</principle>
<convention name="Tutorial">学习导向，带读者完成一个任务</convention>
<convention name="How-to">问题导向，解决一个具体问题</convention>
<convention name="Reference">信息导向，描述技术细节</convention>
<convention name="Explanation">理解导向，解释背景和原理</convention>
</knowledge>

<knowledge domain="fact-audit">
<principle>每一节都要能指出来源</principle>
<checklist>
  <item>requirements</item>
  <item>architecture</item>
  <item>review</item>
  <item>deploy</item>
  <item>verdict</item>
  <item>external docs</item>
</checklist>
<rule>缺事实就阻塞，不脑补。</rule>
</knowledge>

<knowledge domain="minimum-delivery-standard">
<principle>最低交付标准</principle>
<checklist>
  <item>版本和日期</item>
  <item>适用范围</item>
  <item>目录或章节结构</item>
  <item>关键示例</item>
  <item>缺失事实说明（如有）</item>
</checklist>
</knowledge>

</skill>
