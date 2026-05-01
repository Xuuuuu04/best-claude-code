<rule id="dispatch-table" severity="blocker">
  <rationale>
    本文件是 Agent Legion 的调度真源。主会话、<path>CLAUDE.md</path>、output style 和 <cmd>/bcc-*</cmd> 流水线若出现冲突，以本表为准。
    目标：把"用户信号 → 首调 Agent → 产出 artifact → 下一跳 → 是否可并发"标准化，减少主会话临场判断。
  </rationale>

  <section id="concurrency-levels">
    <concurrency-level id="S0" name="决策 / 裁决 / 写入真源" allow-concurrent="false" requirement="必须串行，完成后再派下一跳"/>
    <concurrency-level id="S1" name="只读研究 / 只读审查" allow-concurrent="true" requirement="输入 artifact 固定，输出文件互不覆盖"/>
    <concurrency-level id="S2" name="独立 scope-lock 实现" allow-concurrent="conditional" requirement="文件白名单无交集，依赖图无前后关系，验证命令可独立运行"/>
    <concurrency-level id="S3" name="测试 / 截图 / 验证" allow-concurrent="conditional" requirement="共享环境不会互相污染；否则串行"/>
  </section>

  <section id="concurrency-hard-rules">
    <subsection id="concurrency-allow-conditions">
      <constraint severity="blocker">
        允许并发前必须同时满足：
        <list>
          <item>每个 Agent 的输入 artifact 已经 <status>accepted</status> 或由调度器明确冻结</item>
          <item>每个 Agent 的输出 artifact 路径唯一</item>
          <item>写文件白名单无交集；若不确定，禁止并发</item>
          <item>依赖图无前后关系；<path>scope-plan</path> 中同一 Batch 才可并发</item>
          <item>不共享会被改写的运行环境、数据库、浏览器会话或部署目标</item>
          <item>并发启动前向用户说明：并发对象、互不冲突依据、回收顺序</item>
        </list>
      </constraint>
    </subsection>

    <subsection id="concurrency-forbidden-scenarios">
      <constraint severity="blocker">
        禁止并发的场景：
        <list>
          <item><agent>pm</agent>、<agent>architect</agent>、<agent>scope-planner</agent>、<agent>test-lead</agent> 这类决策节点</item>
          <item>数据库迁移、生产部署、依赖升级、全局配置修改</item>
          <item>同一文件、同一目录生成物、同一测试数据库、同一浏览器 session</item>
          <item>任何一个 Agent 需要根据另一个 Agent 的输出继续判断</item>
        </list>
      </constraint>
    </subsection>
  </section>

  <section id="routing-table">
    <route signal="客户聊天记录 / 售后反馈 / 接单整理" agent="client" artifact="client-brief-*" next="product-analyst 或 pm" concurrency="S0"/>
    <route signal="取名 / Slogan / 品牌调性 / 文案方向" agent="creative" artifact="creative-*" next="content-reviewer" concurrency="S1"/>
    <route signal="新功能 / 新页面 / 新接口" agent="product-analyst" artifact="requirements-*" next="requirements-reviewer" concurrency="S0"/>
    <route signal="需求是否完整 / 能不能开发" agent="requirements-reviewer" artifact="review-requirements-*" next="architect" concurrency="S0"/>
    <route signal="下一步 / 推进到哪 / 多阶段调度" agent="pm" artifact="dispatch-*" next="单一推荐 Agent" concurrency="S0"/>
    <route signal="整体架构 / 技术方案 / 跨模块重构" agent="architect" artifact="architecture-*" next="scope-planner" concurrency="S0"/>
    <route signal="范围锁定 / 拆 scope / 执行批次" agent="scope-planner" artifact="scope-lock-*, scope-plan-*" next="architecture-reviewer" concurrency="S0"/>
    <route signal="架构方案审查 / scope 是否可执行" agent="architecture-reviewer" artifact="review-architecture-*" next="implementer / 专项域" concurrency="S0"/>
    <route signal="仓库内定位 / 调用点 / 历史追溯" agent="repo-researcher" artifact="repo-research-*" next="research-reviewer" concurrency="S1"/>
    <route signal="外部库 / API / 价格 / 兼容性调研" agent="tech-researcher" artifact="tech-research-*" next="research-reviewer" concurrency="S1"/>
    <route signal="Web 前端 / UI 代码实现" agent="implementer-frontend" artifact="impl-report-*" next="code-reviewer" concurrency="S2"/>
    <route signal="后端 / API / 服务端逻辑实现" agent="implementer-backend" artifact="impl-report-*" next="code-reviewer" concurrency="S2"/>
    <route signal="iOS / Android / Flutter / RN" agent="implementer-mobile" artifact="impl-report-*" next="code-reviewer" concurrency="S2"/>
    <route signal="桌面应用 / Electron / Tauri / Qt / SwiftUI macOS" agent="implementer-desktop" artifact="impl-report-*" next="code-reviewer" concurrency="S2"/>
    <route signal="微信小程序 / uni-app / 微信登录支付" agent="miniprogram-dev" artifact="impl-report-*" next="code-reviewer" concurrency="S2"/>
    <route signal="加表 / 改字段 / 迁移 / 索引" agent="database-engineer" artifact="schema-*" next="code-reviewer + security-auditor" concurrency="S0"/>
    <route signal="训练模型 / fine-tune / 推理服务" agent="ml-engineer" artifact="ml-report-*" next="code-reviewer 或 devops" concurrency="S0"/>
    <route signal="代码审查 / diff 审查" agent="code-reviewer" artifact="review-code-*" next="security-auditor 或 functional-tester" concurrency="S1"/>
    <route signal="安全审计 / 上线前安全检查" agent="security-auditor" artifact="review-security-*" next="functional-tester 或 test-lead" concurrency="S1"/>
    <route signal="功能测试 / 回归验证" agent="functional-tester" artifact="review-functional-*" next="visual-tester 或 test-lead" concurrency="S3"/>
    <route signal="UI 截图 / 视觉回归 / 交互可用性" agent="visual-tester" artifact="review-visual-*" next="test-lead" concurrency="S3"/>
    <route signal="能不能验收 / 能不能上线 / 最终裁决" agent="test-lead" artifact="verdict-*" next="devops 或完成" concurrency="S0"/>
    <route signal="API 文档 / 部署说明 / 用户手册" agent="doc-writer" artifact="doc-*" next="content-reviewer" concurrency="S1"/>
    <route signal="设计系统 / tokens / UI 规范" agent="visual-designer" artifact="design-*" next="implementer-frontend 或 visual-tester" concurrency="S0"/>
    <route signal="改 agent / 改规则 / 调度跑偏" agent="prompt-engineer" artifact="prompt-governance-*" next="用户确认 / 调度器执行" concurrency="S0"/>
    <route signal="构建 / CI / 部署 / 回滚" agent="devops" artifact="deploy-report-* 或 incident-*" next="test-lead 或完成" concurrency="S0"/>
    <route signal="文档/创意内容审查" agent="content-reviewer" artifact="review-content-*" next="用户确认 / 下游消费" concurrency="S1"/>
    <route signal="技术调研/仓库研究审查" agent="research-reviewer" artifact="review-research-*" next="architect 或调度器" concurrency="S1"/>
    <route signal="接单报价 / 外包项目评估" agent="freelance-bidder" artifact="bid-proposal-*" next="用户确认" concurrency="S0"/>
    <route signal="简历优化 / 面试准备 / 薪资谈判" agent="career-coach" artifact="career-*" next="用户确认" concurrency="S0"/>
  </section>

  <section id="standard-pipelines">
    <subsection id="pipeline-new-feature">
      <pipeline id="new-feature">
        <step agent="client" condition="如有客户原话" optional="true"/>
        <step agent="product-analyst"/>
        <step agent="requirements-reviewer"/>
        <step agent="architect"/>
        <step agent="scope-planner"/>
        <step agent="architecture-reviewer"/>
        <step agent="implementer / 专项域" note="同 Batch 可并发"/>
        <step agent="code-reviewer" note="可按 impl-report 并发"/>
        <step agent="security-auditor" note="见下方强制条件"/>
        <step agent="functional-tester" note="medium 以上必须"/>
        <step agent="visual-tester" note="如有 UI"/>
        <step agent="test-lead" note="见下方强制条件"/>
      </pipeline>
    </subsection>

    <subsection id="gate-conditions">
      <constraint severity="blocker">
        以下条件命中任一，对应 agent 必须执行，不得跳过：
        <gate-condition agent="security-auditor" trigger="涉及后端 API / 认证 / 支付 / 数据库迁移 / 环境变量 / 敏感数据" basis="实战 0 次调用但角色关键"/>
        <gate-condition agent="functional-tester" trigger="任务档位 medium 或以上" basis="4/5 项目无 verdict"/>
        <gate-condition agent="test-lead" trigger="scope-lock 总数 ≥ 3，或涉及上线/交付/里程碑" basis="4/5 项目无最终裁决"/>
        <gate-condition agent="test-lead（跨 scope 一致性）" trigger="scope-lock 总数 ≥ 3 → 裁决前强制执行跨 scope 接口契约交叉比对" basis="v3.10 新增：跨 scope 签名不一致是最隐蔽的集成 bug"/>
        <gate-condition agent="visual-tester" trigger="涉及用户可见 UI 变更（页面/组件/样式）" basis="仅 1/5 项目有视觉测试"/>

        <gate-condition agent="test-lead（assurance submission）" trigger="assurance = submission 时，所有强制 reviewer 必须发出六级裁决（PASS/WARN/FAIL/NOT_APPLICABLE/BLOCKED/ERROR）之一" basis="ARIS 吸收：draft vs submission 动态门控"/>
        <gate-condition agent="test-lead（artifact 完整性）" trigger="assurance = submission 时，裁决前必须调用 verify-artifacts.sh 验证必需 artifact 存在且无 STALE" basis="ARIS 吸收：外部 verifier 阻塞机制"/>

        <note>**不触发的唯一理由**：用户显式说"跳过 XX 测试"。AI 不得自行判断"不适用"而省略。</note>
      </constraint>
    </subsection>

    <subsection id="issue-grading">
      <constraint severity="blocker">
        每个 reviewer/tester 必须按此三级框架判定，不得自定义分级体系：
        <grade level="blocker" meaning="不可行、不可上线、安全漏洞、scope 越界、关键证据缺失" effect="任何 1 项 → 驳回" examples="SQL 注入、密钥泄露、scope 白名单外修改、无截图证据给 PASS"/>
        <grade level="issue" meaning="设计缺陷、逻辑矛盾、关键遗漏、契约不一致" effect="累计 ≥3 项 → 驳回" examples="接口字段类型不匹配、缺错误处理、验收标准不可测"/>
        <grade level="nit" meaning="可改进但不阻塞" effect="不阻塞通过" examples="命名建议、注释补充、代码风格优化"/>

        <ruling>
          判定规则：
          <list>
            <item><verdict>APPROVED / PASS</verdict>：无严重 AND 一般 &lt; 3</item>
            <item><verdict>REJECTED / BLOCKED</verdict>：存在严重 OR 一般 ≥ 3</item>
            <item>各 reviewer 的审查维度中使用 <tag>[严重]</tag> / <tag>[一般]</tag> / <tag>[轻微]</tag> 标记，不得使用旧的 <tag>Critical</tag> / <tag>Warning</tag> 等模糊标签</item>
            <item>test-lead 最终裁决时，累计所有 reviewer 的严重和一般数量作为裁决依据</item>
          </list>
        </ruling>

        <token-mapping>
          与返回 token 的映射：
          <list>
            <item><token>REVIEW_REJECT:...:{严重数}blocker:{一般数}issue</token> — 驳回时附带计数</item>
            <item><token>SECURITY_REJECT:...:{严重数}blocker:{一般数}issue</token> — 安全驳回附带计数</item>
            <item>test-lead 收到 <token>REVIEW_REJECT</token> 且 blocker≥1 时直接 BLOCKED，无需再读文件</item>
            <item><token>CONTENT_REJECT:...:{严重数}blocker:{一般数}issue</token> — 内容审查驳回附带计数</item>
            <item><token>RESEARCH_REJECT:...:{严重数}blocker:{一般数}issue</token> — 调研审查驳回附带计数</item>
          </list>
        </token-mapping>
      </constraint>
    </subsection>

    <subsection id="pipeline-bug-fix">
      <pipeline id="bug-fix">
        <step agent="repo-researcher"/>
        <step agent="product-analyst" note="复现与验收边界"/>
        <step agent="requirements-reviewer"/>
        <step agent="scope-planner" note="小 bug 可跳过 architect"/>
        <step agent="implementer / 专项域"/>
        <step agent="code-reviewer"/>
        <step agent="security-auditor" note="涉及认证/权限/数据/支付时强制"/>
        <step agent="functional-tester"/>
        <step agent="visual-tester" note="UI bug"/>
      </pipeline>
    </subsection>

    <subsection id="pipeline-migration">
      <pipeline id="migration-database">
        <step agent="repo-researcher"/>
        <step agent="tech-researcher" note="版本升级时"/>
        <step agent="architect"/>
        <step agent="scope-planner"/>
        <step agent="database-engineer" note="schema / migration"/>
        <step agent="implementer-backend" note="业务适配"/>
        <step agent="code-reviewer"/>
        <step agent="security-auditor"/>
        <step agent="functional-tester"/>
        <step agent="devops" note="staging / production"/>
        <step agent="test-lead" note="生产前"/>
      </pipeline>
    </subsection>

    <subsection id="pipeline-miniprogram">
      <pipeline id="miniprogram">
        <step agent="product-analyst"/>
        <step agent="requirements-reviewer"/>
        <step agent="architect"/>
        <step agent="scope-planner"/>
        <step agent="miniprogram-dev"/>
        <step agent="code-reviewer"/>
        <step agent="functional-tester"/>
        <step agent="visual-tester" note="必须有截图 / 交互证据"/>
        <step agent="test-lead" note="发布前"/>
      </pipeline>
    </subsection>

    <subsection id="pipeline-ml">
      <pipeline id="ml">
        <step agent="tech-researcher" note="方法 / 框架调研，按需"/>
        <step agent="product-analyst" note="业务指标"/>
        <step agent="architect" note="系统接入方案"/>
        <step agent="ml-engineer"/>
        <step agent="code-reviewer"/>
        <step agent="security-auditor" note="数据 / 模型服务风险"/>
        <step agent="functional-tester"/>
        <step agent="devops" note="推理部署"/>
        <step agent="test-lead" note="上线前"/>
      </pipeline>
    </subsection>

    <subsection id="pipeline-content">
      <pipeline id="content-production">
        <step agent="doc-writer 或 creative"/>
        <step agent="content-reviewer"/>
        <step agent="用户确认 / 下游消费"/>
      </pipeline>
    </subsection>

    <subsection id="pipeline-research">
      <pipeline id="research">
        <step agent="tech-researcher 或 repo-researcher"/>
        <step agent="research-reviewer"/>
        <step agent="architect 或调度器"/>
      </pipeline>
    </subsection>

    <subsection id="pipeline-freelance">
      <pipeline id="freelance">
        <step agent="freelance-bidder" note="需求澄清 → 工时估算 → 风险评估 → 报价计算"/>
        <step agent="用户确认 / 签约"/>
      </pipeline>
    </subsection>

    <subsection id="pipeline-career">
      <pipeline id="career">
        <step agent="career-coach" note="岗位分析 → 背景评估 → 简历优化 → 面试准备 → 薪资建议"/>
        <step agent="用户确认 / 投递"/>
      </pipeline>
    </subsection>
  </section>

  <section id="resume">
    <route signal="恢复 / 续跑 / resume / 中断了" agent="调度器读 artifact 状态" artifact="同原流水线" next="从断点续跑" concurrency="S0"/>
    <note>断点续跑通过自然语言描述恢复——调度器自动从 artifact 状态定位断点。或显式使用 <cmd>/bcc-loop-dev</cmd> 启动自主恢复模式。</note>
  </section>

  <section id="concurrency-template">
    <requirement>
      并发前，调度器输出：
      <code-block language="text"><![CDATA[
并发批次：Batch {n}
对象：{agent-a} / {agent-b}
依据：scope-lock 白名单无交集；无依赖关系；输出 artifact 不冲突
回收：全部完成后进入 {next-agent}
风险：共享环境 {无 / 有，处理方式}
      ]]></code-block>

      并发回收后，调度器必须汇总：
      <code-block language="text"><![CDATA[
Batch {n} 回收：{完成数}/{总数}
失败项：{无 / 列表}
下一跳：{agent}
      ]]></code-block>
    </requirement>
  </section>

  <section id="fallback-rules">
    <constraint severity="blocker">
      <list>
        <item>路由不明 → <agent>pm</agent></item>
        <item>技术路线不明 → <agent>architect</agent></item>
        <item>外部事实不明 → <agent>tech-researcher</agent></item>
        <item>仓库事实不明 → <agent>repo-researcher</agent></item>
        <item>质量是否能放行不明 → <agent>test-lead</agent></item>
        <item>Agent 边界冲突 → <agent>prompt-engineer</agent></item>
      </list>
    </constraint>
  </section>

  <section id="cross-project">
    <route signal="跨子项目 / monorepo 多服务" agent="product-analyst（拆子项目边界）" artifact="requirements-*" next="architect（跨模块设计）→ 按子项目分别 scope-lock" concurrency="S0"/>
  </section>

  <section id="rule-cascading">
    <rationale>
      同一个文件可能激活多条 rule，例如编辑 <path>app/page.tsx</path>：
      <list>
        <item><path>rules/_lang/typescript.md</path>（TS 通用）</item>
        <item><path>rules/_framework/react.md</path>（.tsx 激活）</item>
        <item><path>rules/_framework/nextjs.md</path>（App Router 路径激活）</item>
      </list>
      **这是正常的层叠，不是 bug**。层级关系：语言 ⊂ 库 ⊂ 元框架，每层约束不冲突时全部生效；冲突时外层（元框架）优先。
    </rationale>

    <constraint severity="warning">
      **但某些 rule 的 <field>paths</field> 可能过宽并误激活**（比如一条 Python 框架 rule 匹配通用文件名 <path>main.py</path>）。发现此情况时：
      <list type="ordered">
        <item>主会话在应用该 rule 前，**先读 rule 的 <field>when_to_use</field> 字段**</item>
        <item>如该字段要求"确认项目为 X 才应用"，则主会话需用 <cmd>Grep</cmd> / <cmd>Read</cmd> 做快速验证</item>
        <item>验证不通过则视为不适用，不引用该 rule</item>
        <item>发现 rule 长期误激活 → 派 <agent>prompt-engineer</agent> 收紧其 paths 或 when_to_use</item>
      </list>
    </constraint>
  </section>

  <section id="router-tiers">
    <constraint severity="blocker">
      <cmd>UserPromptSubmit</cmd> hook 会注入 <token>[LEGION-INTENT] tier=...</token> 标记。主会话必须按 <path>output-styles/legion-dispatch.md</path> 的调度映射表执行：
      <tier name="trivial" dispatch="主会话直接答"/>
      <tier name="small" dispatch="快路径 / 单 implementer；code-reviewer 建议但非强制"/>
      <tier name="medium" dispatch="product-analyst → implementer → **code-reviewer 必经** + **接口字段对账必经**（见下）"/>
      <tier name="large" dispatch="完整流水线 + 全门控"/>
      <tier name="unclear" dispatch="已被 clarification-gate 拦截或追问，禁止假设推进"/>

      <note><token>[REVIEW-PENDING]</token> 标记出现时：本会话有未 review 的 implementer 改动，medium/large 档必须派 code-reviewer 或经用户明确跳过。</note>
    </constraint>
  </section>

  <section id="field-reconciliation">
    <constraint severity="blocker">
      <rationale>
        接口字段对账（medium 及以上 mandatory）

        **触发条件**：任务涉及前端调用后端 endpoint、判断接口枚举字段（payType / orderStatus / status 等）、或新增/修改 API 调用。

        **强制步骤**（任一缺失视为流水线违规）：
        <list type="ordered">
          <item>implementer 写代码前，**先 grep 项目内已上线 work 的同字段使用点**：<cmd>grep -rn "{fieldName}" --include="*.vue" --include="*.ts" --include="*.js"</cmd></item>
          <item>找到 <path>shared/constants/enums.js</path> / 类似字典文件 / OAS 真值表，**对照确认枚举方向与类型**</item>
          <item>当心"同名不同义"：同一字段在不同 endpoint/上下文取值可能不同（int vs string、不同语义集合）</item>
          <item>code-reviewer 审查时，**枚举判断必须有参考代码或 OAS 真值证据**，凭直觉的 <code>=== 1</code>、<code>=== '2'</code> 视为可疑</item>
        </list>

        **为什么 mandatory**：本协议增加是因为客户因接口字段方向反、字段缺漏类 bug 反复返工到不满意状态（feedback memory <token>enum-field-direction-cross-check</token>）。这是已知低级错误，必须用机制堵住。
      </rationale>
    </constraint>

    <subsection id="field-reconciliation-few-shot">
      <example type="bad" id="paytype-intuition">
        <description>反例：凭直觉判断 payType（最常见返工根因）</description>
        <code-block language="typescript"><![CDATA[
// ❌ 错误：implementer 凭直觉假设 1=微信 2=支付宝
if (order.payType === 1) {
  showWechatIcon();
} else if (order.payType === 2) {
  showAlipayIcon();
}
        ]]></code-block>
        <rationale>
          **为什么错**：
          <list>
            <item>同一 <field>payType</field> 字段在不同 endpoint 取值可能不同</item>
            <item>没有看 OAS/字典文件就假设方向</item>
            <item>code-reviewer 看到 <code>=== 1</code> <code>=== 2</code> 没有引用应判 Critical</item>
          </list>
        </rationale>
      </example>

      <example type="good" id="paytype-reconcile-first">
        <description>正例：先对账，再实现</description>
        <code-block language="typescript"><![CDATA[
// ✅ 步骤 1：grep 已上线代码
// $ grep -rn "payType" --include="*.vue" --include="*.ts"
// → src/shared/constants/payType.js:3
//
// 步骤 2：读字典
// export const PAY_TYPE = {
//   ALIPAY: 1,        // 注意：支付宝是 1，不是 2
//   WECHAT: 2,
//   APPLE_PAY: 3,
// } as const;
//
// 步骤 3：引用常量，不用 magic number

import { PAY_TYPE } from '@/shared/constants/payType';

if (order.payType === PAY_TYPE.WECHAT) {
  showWechatIcon();
} else if (order.payType === PAY_TYPE.ALIPAY) {
  showAlipayIcon();
}
        ]]></code-block>
      </example>

      <example type="bad" id="same-name-different-meaning">
        <description>反例：同名不同义陷阱</description>
        <code-block language="typescript"><![CDATA[
// ❌ 错误：在 /order/detail 和 /order/list 共用 status 判断
function isCompleted(order) {
  return order.status === 3;  // 危险：两个 endpoint 的 3 含义不同
}
        ]]></code-block>
      </example>

      <example type="good" id="endpoint-context-aware">
        <code-block language="typescript"><![CDATA[
// ✅ 正确：明确 endpoint 上下文
import { ORDER_DETAIL_STATUS, ORDER_LIST_STATUS } from '@/types/order';

function isCompletedInDetail(order: OrderDetailResponse) {
  return order.status === ORDER_DETAIL_STATUS.COMPLETED;
}
function isCompletedInList(order: OrderListItem) {
  return order.status === ORDER_LIST_STATUS.DONE;  // list 用的是 'DONE' 不是 'COMPLETED'
}
        ]]></code-block>
      </example>

      <example type="template" id="code-reviewer-template">
        <description>code-reviewer 审查模板</description>
        <code-block language="markdown"><![CDATA[
## 接口字段对账审查

| 字段 | 用法 | 引用证据 | 判定 |
|:--|:--|:--|:--|
| order.payType | === PAY_TYPE.WECHAT | shared/constants/payType.js:3 | ✅ |
| order.status | === 3 | （无引用） | ❌ Critical：magic number 无证据 |
        ]]></code-block>
        <note>无证据的枚举判断 = Critical，退回 implementer 重做。</note>
      </example>

      <example type="bad" id="threshold-intermediate-state">
        <description>反例：阈值判断的"中间态"陷阱（v3.5 新增）</description>
        <rationale>
          来自漫展项目实测：<code>orderStatus &gt;= 2</code> 漏掉 <code>status=1</code>「待发放」中间态，导致用户刚付完款立即点「已完成支付」时被错判未支付。
        </rationale>
        <code-block language="typescript"><![CDATA[
// ❌ 错误：直觉认为 "已支付" = status >= 2
if (order.orderStatus >= 2) {
  showPaidUI()
}

// 真实定义（@shared/constants/enums.js）：
//   0 = 待支付
//   1 = 待发放（**支付到账后、票券生成中的中间态**）  ← 容易漏
//   2 = 已发放
//   3 = 已完成
//   4/5/6 = 取消/退款
        ]]></code-block>
      </example>

      <example type="good" id="threshold-include-intermediate">
        <code-block language="typescript"><![CDATA[
// ✅ 正确：精确包含中间态
if (order.orderStatus !== ORDER_STATUS.PENDING_PAYMENT) {
  showPaidUI()
}
// 或语义化辅助函数
function isOrderPaid(s: number) { return s >= ORDER_STATUS.PROCESSING; }  // >=1
        ]]></code-block>
        <note>**判据**：状态机字段判断的边界（<code>&gt;=</code> / <code>&gt;</code> / <code>!==</code>）必须基于完整状态枚举表，不能凭直觉。</note>
      </example>

      <example type="bad" id="cross-endpoint-type-mismatch">
        <description>反例：同名字段跨 endpoint 类型不同（v3.5 实测案例）</description>
        <rationale>
          漫展项目真实情况——<field>payType</field> 在不同 API 取值类型与含义都不同：
          <table>
| 出处 | 类型 | 取值 |
|:--|:--|:--|
| `payOrder` 响应 | `int` | `1=微信`, `2=聚合（微信+支付宝）` |
| 订单详情 `PAY_TYPE` | `string` | `'0'=支付宝`, `'2'=微信支付` |
| 前端 QR 弹窗 `payQRType` | `int` | `1=仅微信`, `2=双通道` |
          </table>
        </rationale>
        <code-block language="typescript"><![CDATA[
// ❌ 错误：implementer 看到 payType 复用之前的判断
if (orderDetail.payType === 1) {  // 这是订单详情，1 不存在！(只有 '0'/'2')
  // 永远不进
}
        ]]></code-block>
      </example>

      <example type="good" id="cross-endpoint-independent-check">
        <code-block language="typescript"><![CDATA[
// ✅ 正确：每个调用点独立查 OAS
import { PAY_TYPE_DETAIL } from '@/types/order-detail'  // string union
import { PAY_TYPE_ORDER } from '@/types/pay-order'       // int enum

if (orderDetail.payType === PAY_TYPE_DETAIL.WECHAT) { ... }   // '2'
if (payOrderRes.payType === PAY_TYPE_ORDER.WECHAT) { ... }    // 1
        ]]></code-block>
        <note>**判据**：跨 endpoint 复用同名字段 = Critical。每个 endpoint 的字段都是独立类型空间。</note>
      </example>
    </subsection>
  </section>

  <section id="user-signals">
    <constraint severity="blocker">
      <rationale>
        用户态信号（v3.5 新增 — 客户压力下的强制门控）

        **触发条件**：用户对话中出现以下任一信号，立即升级为强制完整门控（无论 hook 标什么 tier）：
        <signal word="返工、反复修、又错了" meaning="累积失败 — 客户耐心耗尽"/>
        <signal word="客户不满、客户怒了、客户多次反馈" meaning="客户态恶化"/>
        <signal word="低级错误、这种 bug、又犯" meaning="已被识别为 implementer 失误"/>
        <signal word="终极摸排、全面审查、逐一核对" meaning="用户已要求最高严肃度"/>
      </rationale>

      <ruling>
        **强制规则**：
        <list type="ordered">
          <item>改动节奏放慢——禁止一次完成多文件，必经 scope-planner 拆 ≤3 个 scope-lock</item>
          <item>**强制走完整门控**：product-analyst → architect → scope-planner → implementer → code-reviewer + security-auditor + functional-tester</item>
          <item>**禁止 implementer 自报通过**——code-reviewer 不点头不允许 commit</item>
          <item>**接口字段对账升级为 mandatory**（无论是否枚举判断），先 grep 所有相关字段</item>
          <item>**每个 commit message 必须含**："已通过 code-reviewer 审查"</item>
        </list>

        <rationale>
          **为什么 mandatory**：来自漫展项目 feedback <token>client-rework-fatigue-state</token> + <token>never-skip-code-review-medium</token>。客户因 implementer 长上下文写出"字段方向反"等低级 bug 反复返工到不满意状态。implementer 无 review 直接推 = 让客户当 reviewer。
        </rationale>

        **code-reviewer 不可省略的硬规则**：medium 及以上档位（多文件 / 跨模块 / 接口字段判断 / 状态机判断），即使 implementer 自己说"build 通过"也**不算合规**，必须经 code-reviewer。
      </ruling>
    </constraint>
  </section>
</rule>
