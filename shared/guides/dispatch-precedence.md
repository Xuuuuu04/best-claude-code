---
name: dispatch-precedence
description: 调度优先级与冲突裁决规则
guide: true
---

<harness-guide>
  <section id="priority-order">
    <title>优先级顺序</title>
    <content>
<p>从高到低如下：</p>
<ol>
<li>根目录 <code>CLAUDE.md</code></li>
<li><code>shared/protocols/</code> 下的协议文件</li>
<li><code>shared/guides/project-group-governance.md</code>（项目群总控规程）</li>
<li><code>shared/templates/</code> 下的模板文件</li>
<li><code>.claude/agents/</code> 下的 Agent 定义</li>
<li>项目内 <code>CLAUDE.md</code></li>
<li>Task 文件中的实现细节说明</li>
</ol>

<p>低层规则如果与高层规则冲突，必须服从高层规则。</p>
    </content>
  </section>

  <section id="arbiter-duties">
    <title>主进程的裁决职责</title>
    <content>
<p>主进程负责处理以下冲突：</p>
<ul>
<li>两份规则都能解释当前情形，但给出不同下一跳</li>
<li>下游 Agent 的建议与协议或根规则冲突</li>
<li>项目局部约束试图推翻项目群总控铁律</li>
<li>用户要求与既定流程冲突，需要决定是否让用户拍板</li>
</ul>

<p>主进程不能处理以下问题：</p>
<ul>
<li>具体技术方案优劣，由 <code>dev-lead / architect / database</code> 处理</li>
<li>具体实现是否正确，由 <code>code-review / test-func / test-lead</code> 处理</li>
</ul>
    </content>
  </section>

  <section id="common-conflicts">
    <title>常见冲突的默认处理</title>
    <content>
<h3>1. 项目内规则想并行，根总控要求串行</h3>
<p>按根目录 <code>CLAUDE.md</code> 执行。项目内可以表达"理论上可并行"，但主进程只能前台串行调度。</p>

<h3>2. PM 建议跳过审查或测试</h3>
<p>按协议和根总控执行，不允许跳过 <code>code-review</code>、<code>test-func</code>、<code>test-ui</code>、<code>test-lead</code> 中应有的节点。</p>

<h3>3. 开发 Agent 想在实现时改方案</h3>
<p>开发 Agent 应返回 <code>BLOCKED</code> 或在"后续建议"中升级，不得自行改写路线。PM 决定是否回到 <code>dev-lead</code> 或升级到 <code>architect</code>。</p>

<h3>4. 项目级 <code>CLAUDE.md</code> 与 PM Agent 口径不一致</h3>
<p>优先检查是否属于项目事实变更：</p>
<ul>
<li>如果是事实变更，PM 应先维护项目级 <code>CLAUDE.md</code></li>
<li>如果只是提示词冲突，按 PM Agent 与根规则执行</li>
</ul>

<h3>5. 用户明确要求越过流程</h3>
<p>主进程必须先说明风险和偏离点。若偏离会破坏质量闭环、日志真源或串行铁律，默认拒绝；只有在用户明确拍板且不违反绝对禁令时，才可做受控偏离。</p>
    </content>
  </section>

  <section id="user-confirmation">
    <title>用户拍板的触发条件</title>
    <content>
<p>以下情况默认需要用户拍板：</p>
<ul>
<li>改需求边界</li>
<li>改交付范围</li>
<li>改架构路线</li>
<li>增加工期或成本</li>
<li>需要回滚已经做出的项目级关键决策</li>
</ul>

<p>以下情况默认不需要用户拍板：</p>
<ul>
<li>既定方案下的正常下一跳</li>
<li>审查后回修</li>
<li>测试后回修</li>
<li>按状态机要求重走流程</li>
</ul>
    </content>
  </section>

  <section id="pm-single-step">
    <title>PM 的单步调度原则</title>
    <content>
<p>PM 每次只能返回一条"下一步调度"。</p>

<p>正确示例：</p>
<ul>
<li>当前先派 <code>@代码审计师</code></li>
<li>当前先派 <code>@功能测试师</code></li>
<li>当前先派 <code>@后端开发师</code> 处理审查打回</li>
</ul>

<p>错误示例：</p>
<ul>
<li>"先后端再前端再测试"</li>
<li>"建议同时调用后端和数据库"</li>
<li>"未来三步都列出来，主进程自行选择"</li>
</ul>
    </content>
  </section>

  <section id="separation">
    <title>实现与裁决分离</title>
    <content>
<p>整个体系始终保持以下分离：</p>
<ul>
<li>PM 负责调度，不负责实现</li>
<li>开发负责实现，不负责放行</li>
<li>审查负责挑问题，不负责修复</li>
<li>测试负责验证，不负责改代码</li>
<li>测试总监师负责裁决，不负责替代 UI 截图和功能测试</li>
</ul>

<p>谁发现问题，谁描述问题；谁有职责解决，谁解决；谁有职责拍板，谁拍板。</p>
    </content>
  </section>
</harness-guide>
