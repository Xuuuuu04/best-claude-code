---
name: agent-writing-standard
description: Agent 编写标准 - 统一 Agent 提示词结构、职责边界和写法风格
guide: true
---

<harness-guide>
  <section id="general-principles">
    <title>总原则</title>
    <content>
<p>每个 Agent 文件都应同时满足三件事：</p>
<ol>
<li>让主进程知道"什么时候该调它"</li>
<li>让 Agent 自己知道"拿到任务后该怎么做"</li>
<li>让用户和维护者知道"它不能做什么"</li>
</ol>

<p>如果一个 Agent 文件只强调能力，不说明触发条件、停止条件和升级边界，它就是不完整的。</p>
    </content>
  </section>

  <section id="recommended-structure">
    <title>生产标准骨架（v23 10 段式，现行事实标准）</title>
    <content>
<p>本项目现有 33 个 agent 经过 v23 升级，现统一使用 <strong>v23 10 段式 <code>&lt;agent&gt;</code> XML 骨架</strong>（顶部 Primacy + 底部 Recency 双铁律锚点）。新增或修改 agent 必须遵循此结构，不得简化回早期 7 段/旧 10 段版本。</p>

<ol>
<li><code>&lt;section id="rules"&gt;</code> <strong>铁律（Primacy Anchor）</strong> — 顶部硬规则 7 条左右，英文 MUST/NEVER/FORBIDDEN 为主 + 中文注释。最高优先级。</li>

<li><code>&lt;section id="role"&gt;</code> <strong>角色定位</strong> — 类比角色（如"拥有 X 年经验的 Y 专家"）+ 核心价值主张 + 与相邻 Agent 的根本区分。100-200 字中文。</li>

<li><code>&lt;section id="scope"&gt;</code> <strong>职责边界（In-Scope）</strong> — 明确列出能做什么，3-8 条中文。</li>

<li><code>&lt;section id="not-scope"&gt;</code> <strong>不承担的职责（Out-of-Scope）</strong> — 明确不做什么 + 转交给谁，3-6 条。防止越权。</li>

<li><code>&lt;section id="skill-tree"&gt;</code> <strong>技能树（3 层展开）</strong> — 一级领域 → 二级技能集 → 三级具体能力（含 API/工具链/版本号/命令示例）。2-4 个一级领域。</li>

<li><code>&lt;section id="methodology"&gt;</code> <strong>方法论与执行步骤</strong> — 标准工作流（编号 1/2/3 步骤，不是抽象原则）+ 关键决策点 + 常见反模式与对策。</li>

<li><code>&lt;section id="collaboration"&gt;</code> <strong>协作边界</strong> — 上游（谁派我）、下游（我点名谁做下一跳）、横向（同层 Agent 衔接）。</li>

<li><code>&lt;section id="output-contract"&gt;</code> <strong>产出合约</strong> — 每次返回必须包含的字段 + 格式清单 + 后续建议格式。</li>

<li><code>&lt;section id="dispatch-signals"&gt;</code> <strong>调度触发信号</strong> — 主进程应派我的关键词/场景 + "不要派我"的场景（防误派）。</li>

<li><code>&lt;section id="final_reminder"&gt;</code> <strong>Final Reminder（Recency Anchor）</strong> — 底部 5-10 行精简复读最高优先级铁律（措辞与顶部 rules 不同但语义一致）。</li>
</ol>

<h3>XML 骨架模板</h3>
<pre>
---
name: {Agent 中文名带后缀，如"代码审计师"}
description: {一句话角色 + 核心职责 + 触发信号}
model: {opus | sonnet | haiku}
color: {按 v23 8 色映射}
tools:
  - Read
  - Grep
  ...
---

&lt;agent&gt;
  &lt;section id="rules"&gt;...&lt;/section&gt;
  &lt;section id="role"&gt;...&lt;/section&gt;
  &lt;section id="scope"&gt;...&lt;/section&gt;
  &lt;section id="not-scope"&gt;...&lt;/section&gt;
  &lt;section id="skill-tree"&gt;...&lt;/section&gt;
  &lt;section id="methodology"&gt;...&lt;/section&gt;
  &lt;section id="collaboration"&gt;...&lt;/section&gt;
  &lt;section id="output-contract"&gt;...&lt;/section&gt;
  &lt;section id="dispatch-signals"&gt;...&lt;/section&gt;
  &lt;section id="final_reminder"&gt;...&lt;/section&gt;
&lt;/agent&gt;
</pre>

<h3>双铁律锚点（v23 关键改进）</h3>
<p>基于 Phase 3 范式研究，Primacy（顶部 rules）+ Recency（底部 final_reminder）双锚点可显著提升长 charter 下的铁律遵循率。新写或升级 agent 必须同时有这两个 section，措辞不同但语义一致。</p>

<h3>语言与长度</h3>
<ul>
<li>语言：中文为主（70-80%） + 英文硬规则（MUST/NEVER） + 英文 XML 标签/字段名</li>
<li>长度：sonnet/opus agent 目标 3000-5000 tokens，上限 6000；haiku agent 1500-3000</li>
<li>XML 嵌套深度 ≤ 3 层</li>
<li>超过 6000 tokens 考虑拆 core/extended 双层</li>
</ul>

<h3>历史备注</h3>
<p>v22 之前推荐旧 10 段骨架（anchor / signal / upstream-downstream / boundary / protocol / sop / skills / escalation / antipattern / rules）和更早的 7 段骨架。两者均已被 v23 10 段式覆盖（2026-04-18），保留作历史参考但不再用于生产。</p>
    </content>
  </section>

  <section id="writing-requirements">
    <title>角色文案要求</title>
    <content>
<h3>专职化优先</h3>
<p>不要把 Agent 写成"大而全专家"。每个 Agent 的文案都应强化"它负责什么"与"它不负责什么"。</p>

<p>示例：</p>
<ul>
<li><code>backend</code> 是后端实现者，不是技术路线裁决者</li>
<li><code>code-review</code> 是质量守门人，不是修复者</li>
<li><code>test-ui</code> 是页面状态采集者，不是审美裁决者</li>
<li><code>client</code> 是需求整理和客户表达桥梁，不是架构师</li>
</ul>

<h3>触发条件必须明确</h3>
<p>好的 Agent 描述里要写清楚：</p>
<ul>
<li>它通常在什么状态下被调用</li>
<li>它依赖什么输入</li>
<li>它最常见的上游是谁</li>
<li>它最常见的下游是谁</li>
</ul>

<h3>停止条件必须明确</h3>
<p>每个 Agent 都应明确：</p>
<ul>
<li>什么算"我已经完成了"</li>
<li>什么情况下我应该返回 <code>BLOCKED</code></li>
<li>什么情况下我必须拒绝继续做</li>
</ul>
    </content>
  </section>

  <section id="tool-permissions">
    <title>工具权限原则</title>
    <content>
<p>工具权限应尽量最小化。</p>

<p>推荐原则：</p>
<ul>
<li>只读类角色：优先 <code>Read / Glob / Grep</code></li>
<li>写文档类角色：再给 <code>Write</code></li>
<li>实现/测试/部署类角色：只有确有必要时再给 <code>Edit / Bash</code></li>
<li>联网调研类角色：只给联网调研相关工具，不给实现类工具</li>
</ul>

<p>不要因为"可能以后用得上"就给更多工具。</p>
    </content>
  </section>

  <section id="color-selection">
    <title>颜色选择原则</title>
    <content>
<p><code>color</code> 应传达角色语义。Claude Code 仅支持以下 8 种颜色：</p>

<p>推荐映射（与 Claude Code 官方语义对齐）：</p>
<ul>
<li><code>red</code>：安全审计、最终闸门、生产风险</li>
<li><code>orange</code>：文档、校对、界面测试</li>
<li><code>yellow</code>：审查、验证、调度管理、版本控制</li>
<li><code>green</code>：执行、部署、构建、数据工程</li>
<li><code>cyan</code>：前端实现、移动端开发、UI 设计系统、工作流编排</li>
<li><code>blue</code>：后端、架构设计、ML 工程、数据库</li>
<li><code>purple</code>：深度研究、AI 情报、专业知识、客户沟通、方案设计</li>
<li><code>pink</code>：创意生成、视觉设计、元工程（提示词工程）</li>
</ul>

<p>选择原则：同色系内的 agent 应有相近的职责语义。不同色系应反映不同的工作性质。如果一个角色承担"放行/否决"或"直接碰生产风险"的职责，优先 <code>red</code>。</p>
    </content>
  </section>

  <section id="output-requirements">
    <title>输出要求原则</title>
    <content>
<p>所有 Agent 的输出都应满足：</p>
<ul>
<li>能被 PM 或主进程直接消费</li>
<li>不依赖"主进程自己脑补"</li>
<li>能支撑下一跳调度</li>
</ul>

<p>至少要让上游读完后知道：</p>
<ul>
<li>做了什么</li>
<li>没做成什么</li>
<li>当前状态建议怎么变</li>
<li>下一步该派谁，或为什么先别派</li>
</ul>
    </content>
  </section>

  <section id="blocked-standards">
    <title>BLOCKED 的使用标准</title>
    <content>
<p>Agent 遇到以下情况应优先返回 <code>BLOCKED</code>，而不是硬做：</p>
<ul>
<li>缺少关键输入</li>
<li>需求本身歧义</li>
<li>技术路线明显有问题</li>
<li>当前任务已经超出本角色职责边界</li>
<li>需要用户做成本或范围决策</li>
</ul>

<p><code>BLOCKED</code> 不是"我不想做"，而是"在当前信息和权限下继续做会制造更大返工"。</p>
    </content>
  </section>

  <section id="style-requirements">
    <title>风格要求</title>
    <content>
<h3>语言风格</h3>
<p>整套体系保持：</p>
<ul>
<li>中文为主</li>
<li>专业但不装腔</li>
<li>具体、可执行、少空话</li>
<li>有角色感，但不演人格剧场</li>
</ul>

<h3>信息密度</h3>
<p>不要写"你很专业、你很强大、你非常擅长……"这种低信息密度赞美句。把篇幅留给：</p>
<ul>
<li>决策条件</li>
<li>动作顺序</li>
<li>质量标准</li>
<li>失败回退</li>
</ul>
    </content>
  </section>

  <section id="bad-practices">
    <title>对常见坏写法的限制</title>
    <content>
<p>以下写法应避免：</p>
<ul>
<li>只写角色，不写触发条件</li>
<li>只写能力，不写边界</li>
<li>只写目标，不写流程</li>
<li>只写"发现问题就上报"，但不说上报给谁</li>
<li>用大量抽象概念替代具体交付物</li>
<li>把多个角色的职责混在一起</li>
</ul>
    </content>
  </section>

  <section id="pm-relationship">
    <title>专职 Agent 与 PM 的关系</title>
    <content>
<p>PM 决定派谁，不替专职 Agent 做活。</p>
<p>专职 Agent 做本职工作，不替 PM 决定整体路线。</p>
<p>如果一个专职 Agent 需要越过自身边界才能继续推进，应该升级，而不是静默越权。</p>
    </content>
  </section>
</harness-guide>
