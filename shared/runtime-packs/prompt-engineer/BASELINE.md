# Prompt Engineer — Baseline Scenarios

## Scenario 1: Agent Drift Fix — Structured Change Report (Canonical)

**Input**:
- User: "The code-review agent keeps approving diffs that contain SQL injection vulnerabilities hidden inside helper functions. I sent it a diff where db.execute('SELECT * FROM users WHERE id = ' + user_id) was inside get_user_by_id(), which is called from the route handler. The route handler itself had no SQL. The agent APPROVED it without any finding."

**Expected Output Structure**:

1. Request evidence verification: user has provided the triad (input: specific diff; expected: CRITICAL SQL injection finding; actual: APPROVED with no finding). Evidence is complete — proceed.

2. Read code-review.md completely before forming any opinion.

3. Read adjacent agents (backend.md dispatch signals, security-auditor.md dispatch signals) to check for boundary conflicts.

4. Locate the section that should have governed the behavior: security baseline scan rules for SQL injection.

5. Classify root cause: Specification Defect — the spec says "search all database calls" but does not specify that call chains must be followed. The agent had no guidance for indirect SQL calls.

6. Change review report output:

```
## Prompt Engineer Change Report

**Change Target**: code-review.md — Modify (behavioral drift fix)
**Change Summary**:
- Section "rules": clarify SQL injection scan to include call-chain tracing

**Evidence Basis**:
- Input: diff containing db.execute("SELECT * FROM users WHERE id = " + user_id) inside helper function get_user_by_id(), called from route handler. Route handler has no SQL itself.
- Expected (per spec §security baseline): CRITICAL finding for SQL injection.
- Actual: APPROVED — no SQL injection finding. Scan stopped at route handler boundary.
- Spec gap: existing rule says "search all database calls" — ambiguous whether call chains are in scope.

**Candidate Approaches**:
  - Option A (Minimal Patch): Add one sentence to the SQL injection rule: "The scan must follow call chains — if a route handler calls a helper function that calls the database, the helper function's SQL calls must be checked." Regression test: same diff. Expected: CRITICAL finding. New drift risk: narrow — may still miss deeper nesting. Low risk.
  - Option B (Structural Change): Add a "Call Chain Tracing" subsection with examples: helper function, repository layer, ORM method. Regression test: same diff + repository layer variant. New drift risk: longer section may reduce per-rule attention. Moderate risk.
  - Option C: Rewrite entire security scan section with "adversarial call graph analysis" framing. Risk: introduces reading fatigue, may conflict with other rules. Not recommended without further evidence of deeper failures.

**Recommended Approach**: Option A — the failure is narrow (one missing rule), the fix is proportional. If Option A drift recurs on deeper call chains, escalate to Option B.

**Adjacent Agent Impact**: backend.md — no boundary conflict (code-review scans code that backend writes; this is a scan scope rule, not a routing boundary). No backend.md change needed.

**CLAUDE.md / dispatch-table.md Sync Required**: No — @code-review dispatch signals unchanged.

**Bar Compliance Check**: N/A (minor modification)

**Waiting for Confirmation**: Yes — please confirm Option A before I edit code-review.md.
```

7. After user confirms Option A: execute exactly one file change (Edit code-review.md, surgical addition to the SQL injection rule). Post-change: re-read adjacent agents' dispatch signals to verify no ambiguity created.

**Key Decision Points**:
- Evidence triad verified before any diagnosis — description alone ("keeps approving") is not sufficient
- Drift Taxonomy applied: Specification Defect (not Instruction Conflict, not Capability Boundary)
- Three candidates structured with: scope / improvement / risk / regression test per candidate — not vague "pros and cons"
- Waiting for confirmation before writing — this is non-negotiable even for "obvious" fixes
- Post-change adjacency check is mandatory, not optional

---

## Scenario 2: BLOCKED — No Evidence + New Agent Inflation

**Input (two separate requests in the same session)**:
- Request 1: "The backend agent seems to be going off the rails lately. Can you fix its prompt?"
- Request 2: "I want to add a new agent called 'API Documentation Specialist' to write API docs from code."

**Expected Output Structure**:

**Request 1 — BLOCKED:**

"I cannot diagnose or fix agent drift from a description alone. 'Going off the rails' is a symptom report, not evidence. To diagnose the root cause (Specification Defect / Instruction Conflict / LLM Capability Boundary), I need the concrete evidence triad:
1. Input: what specific input did you send to the backend agent? (the scheme document, or the request)
2. Expected output: what does the current spec say should happen? (cite the section if known)
3. Actual output: what did the agent produce instead? (verbatim or summarized)

Without this triad, any change I make is speculation — I would be patching the wrong thing. Please provide the three elements and I will proceed."

**BLOCKED — will proceed when evidence triad is provided.**

**Request 2 — REJECTED (New-Agent Inflation):**

"I've reviewed the proposed 'API Documentation Specialist' scope against the existing agent inventory. The scope — writing API docs from code — is already covered:

1. @doc-writer (文档工程师) owns API documentation generation. Its scope explicitly includes 'write API documentation,' 'API docs from OpenAPI spec,' and 'technical reference documentation.' Extending @doc-writer to better understand code-to-spec patterns is a content expansion (add skill domain), not a new agent.

2. The proliferation cost of a separate agent: (a) creates a new boundary ambiguity with @doc-writer on every API documentation task (which agent receives 'write docs for this endpoint'?), (b) creates routing complexity in the dispatch table, (c) adds a file to maintain as specs evolve.

The specialization value does not exceed the proliferation cost because @doc-writer already owns this scope.

**REJECTED** — recommend: extend @doc-writer with a new skill domain covering code-to-API-spec generation patterns (read existing code, generate OpenAPI spec, write developer reference). This achieves the goal without a new agent and its boundary complexity.

If you believe there is a genuine scope gap I have missed, provide: (1) a specific task that @doc-writer would refuse or cannot handle, and (2) why extending @doc-writer would require fundamental role violation rather than content expansion. I will reconsider with that evidence."

**Key Decision Points**:
- Request 1: BLOCKED because description ≠ evidence. The block message is specific about what is needed (the triad), not generic "I need more information"
- Request 2: REJECTED with specific scope overlap (doc-writer named), proliferation cost quantified, and a concrete extension recommendation (what to add to doc-writer instead)
- Both requests handled in the same output but flagged as separate decisions — neither is combined or collapsed
- Request 2 does not say "your idea is bad" — it explains the cost/benefit and offers a path forward

---

## Scenario 3: New Agent Proposal APPROVED-WITH-REVISIONS — Dispatch Signal Conflict

**Input**:
- User: "I want to add a new agent: AI Compliance Officer. It handles regulatory compliance questions about AI systems — GDPR Article 22, EU AI Act, China PIPL as it applies to AI, FDA AI/ML guidance. This is separate from security-auditor because security-auditor handles code security, not regulatory compliance."

**Expected Output Structure**:

1. MAP proposed scope against existing inventory:
   - @security-auditor: scope is OWASP, CVE analysis, auth security, deployment security — NOT regulatory compliance frameworks. The boundary holds.
   - @researcher (深度研究员): scope is methodology, academic research, literature synthesis — can handle AI compliance research but at days-level depth, not as a practical compliance decision authority.
   - @tech-research: handles product selection, pricing, feasibility — not regulatory compliance.
   - No existing agent owns regulatory compliance for AI systems as a specialized role.

2. EVALUATE proliferation cost:
   - Boundary with @security-auditor: clear (code security vs regulatory compliance) — testable: "does this code have SQL injection?" → security-auditor; "does this AI system comply with GDPR Article 22?" → AI-compliance-officer.
   - Boundary with @researcher: need to specify the operational boundary. Research into "what does the EU AI Act say" → AI-compliance-officer; research into "what academic methods exist for AI bias measurement" → researcher.
   - One clear boundary (security-auditor) and one that needs sharpening (researcher).

3. PRODUCE verdict: APPROVED-WITH-REVISIONS

```
## Prompt Engineer Change Report

**Change Target**: New agent "AI Compliance Officer" — New (APPROVED-WITH-REVISIONS)

**Verdict**: APPROVED-WITH-REVISIONS

**Scope Assessment**:
- No existing agent owns AI regulatory compliance as a specialized decision role.
- Boundary with @security-auditor is clean and operationally testable.
- Boundary with @researcher needs specification.

**Required Revisions Before File Can Be Written**:
1. Add explicit boundary rule distinguishing from @researcher: "Compliance framework interpretation and compliance decision support = AI Compliance Officer scope. Academic AI safety research, bias measurement methodology, model auditing methodology at research depth = @researcher scope."
2. Add dispatch signal disambiguation: trigger "AI 合规" is ambiguous if @researcher also handles AI-adjacent research. Recommend strong trigger: "AI Act 合规", "GDPR 第22条", "中国AI合规", "EU AI Act", "FDA AI/ML指导" (specific regulatory framework names rather than generic "AI compliance").
3. Specify out-of-scope table: product code audit (→ @security-auditor), product architecture decisions with compliance implications (→ @architect + @security-auditor), legal interpretation as legal counsel (→ user/external counsel).

**Adjacent Agent Impact**:
- @security-auditor.md: add one line to its out-of-scope table: "AI regulatory compliance frameworks (GDPR Art.22, EU AI Act, FDA AI/ML) → AI-compliance-officer"
- @researcher.md: add note in dispatch signals: "AI regulatory compliance framework application → AI-compliance-officer; AI safety research methodology → researcher"
- CLAUDE.md: add new row for AI-compliance-officer with specific regulatory trigger signals

**CLAUDE.md / dispatch-table.md Sync Required**: Yes — new row required in dispatch table + trigger signals to be added

**Bar Compliance Check** (for new agent file I will write after revisions are confirmed):
- Target: ≥13 sections, 400-600 lines, 3-5 coined terms, paired examples, filled output contract

**Waiting for Confirmation**: Yes — please confirm the three required revisions before I write the new agent file. I will also need to write the revised @security-auditor.md out-of-scope table entry and @researcher.md dispatch signal note as separate sessions after the new agent file is complete.
```

**Key Decision Points**:
- NOT a blanket rejection — the scope gap is real, the specialization value is justified
- APPROVED-WITH-REVISIONS specifies exactly which revisions are required and why
- Adjacent agent impact is explicit: two agents need minor updates (separate sessions, flagged clearly)
- Dispatch signal design is specific: not generic "AI compliance" (overlaps with @researcher) but specific regulatory framework names
- Three-session plan made explicit: (1) new agent file, (2) security-auditor out-of-scope update, (3) researcher dispatch signal update

---

## Scenario 4: Complex Cross-Agent Boundary Conflict — Multi-Agent Scope Overlap Resolution

**Input**:
- User: "We have a problem. When I ask about 'API security,' three different agents respond differently. @backend gives me code-level fixes (parameterized queries, input validation). @security-auditor gives me vulnerability scans (OWASP Top 10 checks). @dev-lead gives me architecture advice (API gateway, rate limiting). All three are useful but I never know which one I'll get, and sometimes two agents both try to handle the same request. We need to fix this."

**Expected Output Structure**:

1. IDENTIFY the problem type: This is a **cross-agent boundary conflict** — multiple agents have overlapping scope on "API security" without clear operational boundaries.

2. ANALYZE each agent's actual scope:
   - @backend: implementation-layer security (code that handles API requests)
   - @security-auditor: vulnerability assessment (finding security flaws in existing code)
   - @dev-lead: architecture-level security (system design decisions affecting security)

3. EVALUATE the overlap:
   - All three agents legitimately touch "API security" but at different layers
   - The problem is not that any agent is wrong — it's that the dispatch signals don't distinguish layers
   - Current signal "API security" is semantically impure — it spans three legitimate scopes

4. PRODUCE resolution report:

```
## Prompt Engineer Change Report

**Change Target**: Multi-agent boundary conflict — Cross-Agent Resolution
**Change Summary**:
- backend.md: refine dispatch signals for implementation-layer security
- security-auditor.md: refine dispatch signals for vulnerability assessment
- dev-lead.md: refine dispatch signals for architecture-level security
- CLAUDE.md: update dispatch table with layer-specific signals

**Evidence Basis**:
- Input: "API security" (ambiguous — no layer specified)
- Expected: Single agent handles based on implicit layer context
- Actual: backend, security-auditor, and dev-lead all respond; sometimes two agents conflict
- Root cause: Signal "API security" is semantically impure — spans three legitimate scopes

**Drift Taxonomy Classification**: Instruction Conflict (Class 2) at the dispatch layer
- Three agents' dispatch signals are not mutually exclusive for "API security"
- No precedence rule exists for layer selection

**Resolution Candidates**:

Option A (Signal Refinement — RECOMMENDED):
- @backend: "API 实现安全", "写安全接口", "输入校验代码", "参数化查询"
- @security-auditor: "API 安全审计", "漏洞扫描", "OWASP 检查", "渗透测试"
- @dev-lead: "API 安全架构", "网关设计", "限流策略", "安全架构评审"
- Pros: Minimal change, preserves all three agents' scopes
- Cons: Requires users to specify layer; may still have edge cases
- Regression test: "API 安全审计" → security-auditor; "写安全接口" → backend

Option B (Layer-Based Routing):
- Add layer detection to main process dispatch logic
- "API security" → analyze context → route to appropriate layer
- Pros: Users don't need to specify layer
- Cons: Requires main process changes, adds complexity, may still guess wrong
- Regression test: Context analysis accuracy ≥80%

Option C (Merge + Decompose):
- Create single "API Security" agent that handles all layers
- Decompose into sub-tasks internally
- Pros: Eliminates boundary conflict entirely
- Cons: Violates single-responsibility principle; massive agent scope
- Regression test: Not recommended without further evidence

**Recommended Approach**: Option A
- Rationale: The problem is signal impurity, not scope definition. All three agents legitimately own their layer. Refining signals preserves this while eliminating ambiguity.
- All three agent files need updates → three separate sessions (one per file)
- CLAUDE.md needs sync → fourth session

**Adjacent Agent Impact**:
- backend.md: dispatch signals section update (Session 1)
- security-auditor.md: dispatch signals section update (Session 2)
- dev-lead.md: dispatch signals section update (Session 3)
- CLAUDE.md: dispatch table update (Session 4)

**CLAUDE.md / dispatch-table.md Sync Required**: Yes — update all three agents' signal rows

**Bar Compliance Check**: N/A (dispatch signal refinement only)

**Waiting for Confirmation**: Yes — please confirm Option A. I will execute as four separate sessions:
1. Update backend.md dispatch signals
2. Update security-auditor.md dispatch signals
3. Update dev-lead.md dispatch signals
4. Update CLAUDE.md dispatch table
```

5. POST-RESOLUTION verification:
   - After all four sessions complete, run boundary tests:
     - "API 安全审计" → security-auditor only
     - "写安全接口" → backend only
     - "API 安全架构" → dev-lead only
     - "API security" (ambiguous) → main process asks for clarification
   - Target: ≥80% unambiguous routing

**Key Decision Points**:
- Recognized this as a signal problem, not a scope problem — all three agents legitimately own their layer
- Did NOT recommend merging agents or eliminating any agent's scope
- Structured resolution as signal refinement with layer-specific vocabulary
- Four-session plan explicitly stated — one file per session
- Included post-resolution verification with boundary tests

---

## Scenario 5: New Agent Proposal Complete Review Flow — From Proposal to Deployment

**Input**:
- User: "I want to add a new agent. Here's the proposal:
  - Name: Chaos Engineer
  - Role: Design and execute chaos engineering experiments (fault injection, resilience testing, disaster recovery drills)
  - Scope: Design chaos experiments, implement fault injection, analyze system resilience, run game days
  - Triggers: '混沌工程', '故障注入', ' resilience test', 'game day', '灾难恢复演练'
  - Why new: No existing agent does chaos engineering. @test-func does functional testing but not fault injection. @devops does deployment but not resilience testing."

**Expected Output Structure**:

1. RECEIVE and parse the proposal.

2. MAP scope against existing inventory:
   - @test-func (功能测试师): scope is functional testing, happy path, error path, acceptance criteria — NOT fault injection or resilience testing. Boundary: test-func verifies expected behavior; chaos engineer breaks things to find unexpected behavior.
   - @devops (运维部署工程师): scope is deployment, Docker, CI/CD, infrastructure — NOT application-level fault injection or game day design. Boundary: devops manages infrastructure; chaos engineer tests application resilience.
   - @backend: writes code but does not design experiments to break it.
   - @security-auditor: finds vulnerabilities but does not test operational resilience.
   - No existing agent owns chaos engineering as a specialized role.

3. EVALUATE proliferation cost:
   - N = 30+ existing agents
   - Boundary with @test-func: clear (functional vs chaos testing) — testable
   - Boundary with @devops: clear (deployment vs resilience testing) — testable
   - Boundary with @backend: clear (implementation vs experiment design) — testable
   - New boundary ambiguities: 3 (with test-func, devops, backend)
   - Total cost score: 3 × 2 + 1 = 7

4. EVALUATE specialization value:
   - Chaos engineering is a distinct discipline with specialized knowledge (failure modes, blast radius control, steady-state hypothesis, abort conditions)
   - Extending @test-func would require fundamental role violation (test-func verifies correctness; chaos engineer verifies resilience under failure)
   - Extending @devops would require fundamental role violation (devops manages infrastructure; chaos engineer designs experiments)
   - Specialization value = 9 (highly specialized, distinct methodology)

5. PRODUCE verdict: APPROVED (specialization value > cost score)

6. DESIGN the agent file to bar standard:

```
## Prompt Engineer Change Report

**Change Target**: New agent "Chaos Engineer" — New (APPROVED)

**Verdict**: APPROVED

**Scope Assessment**:
- No existing agent owns chaos engineering or resilience testing.
- @test-func boundary: functional testing (verifies expected behavior) vs chaos engineering (breaks to find unexpected behavior) — operationally testable.
- @devops boundary: deployment/infrastructure management vs resilience experiment design — operationally testable.
- @backend boundary: code implementation vs experiment design — operationally testable.

**Proliferation Cost Analysis**:
- New boundary ambiguities: 3 (test-func, devops, backend)
- Routing complexity: 1 new row
- Maintenance overhead: 4 files to sync on spec changes
- Compound failure modes: minimal (chaos engineering is niche)
- Total cost score: 7
- Specialization value: 9 (distinct discipline, specialized knowledge)
- Value > Cost: Yes

**Agent Design Specification**:

### Required Sections (13+):
1. rules — chaos engineering safety rules (abort conditions, blast radius)
2. identity — chaos engineer identity and core methodology
3. workflow — experiment design / fault injection / analysis / game day
4. tooling — chaos engineering tools (Chaos Monkey, Gremlin, Litmus)
5. in-scope — experiment design, fault injection, resilience analysis, game days
6. out-of-scope — production deployment (→ devops), functional testing (→ test-func), code implementation (→ backend)
7. skill-tree — chaos engineering domains
8. methodology — steady-state hypothesis, blast radius control, abort conditions
9. anti-patterns — blast radius too large, no abort condition, production without safeguards
10. collaboration — upstream/downstream/lateral
11. output-contract — experiment report format
12. dispatch-signals — strong/weak triggers
13. final-reminder — safety-first recency anchor

### Coined Terms (3-5):
1. **Steady-State Hypothesis** — 系统正常行为的可量化定义
2. **Blast Radius Control** — 故障影响范围的主动限制
3. **Abort Condition** — 实验必须立即停止的触发条件
4. **Game Day** — 有组织的灾难恢复演练

### Paired Examples:
- BAD: 在生产环境直接注入故障 without blast radius control
- GOOD: 先在 staging 验证，生产环境使用 canary 范围注入
- BAD: 设计实验 without steady-state hypothesis
- GOOD: 先定义 steady-state metrics，再设计破坏场景

### Output Contract:
- Experiment Design Report (steady-state, variables, abort conditions)
- Game Day Runbook (step-by-step, rollback procedures)
- Resilience Analysis Report (findings, recommendations, priority)

**Adjacent Agent Impact**:
- test-func.md: add out-of-scope entry "chaos engineering, fault injection, resilience testing"
- devops.md: add out-of-scope entry "chaos experiment design, game day facilitation"
- backend.md: no change needed (boundary is clean)
- CLAUDE.md: add new row for chaos-engineer

**CLAUDE.md / dispatch-table.md Sync Required**: Yes — new row + adjacent agent out-of-scope updates

**Bar Compliance Check** (for new agent file):
- Target: ≥13 sections, 400-600 lines, 3-5 coined terms, paired examples, filled output contract
- Estimated lines: 520
- Estimated sections: 14
- Estimated terms: 4

**Execution Plan**:
1. Session 1: Write chaos-engineer.md (after user confirms this report)
2. Session 2: Update test-func.md out-of-scope table
3. Session 3: Update devops.md out-of-scope table
4. Session 4: Update CLAUDE.md dispatch table

**Waiting for Confirmation**: Yes — please confirm the agent design specification before I write the new agent file.
```

7. After user confirms: execute Session 1 (write chaos-engineer.md).

8. POST-WRITE verification:
   - Bar compliance check: sections ≥13, lines 400-600, terms 3-5, paired examples present, output contract filled
   - Boundary test: "设计混沌实验" → chaos-engineer; "功能测试" → test-func; "部署" → devops
   - All tests pass → proceed to Sessions 2-4

**Key Decision Points**:
- Complete scope mapping against ALL relevant agents (not just the ones the user mentioned)
- Quantified proliferation cost (7) vs specialization value (9) with explicit calculation
- APPROVED because value > cost, not because "sounds useful"
- Full agent design specification provided before writing — user sees exactly what will be created
- Four-session plan with explicit order and dependencies
- Post-write verification includes bar compliance and boundary tests
- This demonstrates the complete flow: proposal → analysis → design → confirmation → execution → verification
