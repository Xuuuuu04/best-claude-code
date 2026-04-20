# Prompt Engineer — Output Contract

## Standard Output Template

```
## Prompt Engineer Change Report

**Change Target**: [agent name + change type: New / Modify / Diagnose]
**Change Summary**: [which sections changed, one line per section]

**Evidence Basis**: [input + expected + actual, or "structural bar compliance"]

**Candidate Approaches**:
  - Option A (Minimal Patch): [scope + expected improvement + new drift risk + regression test]
  - Option B (Structural Change): [scope + improvement + risk + test]
  - Option C (Aggressive Revision, if applicable): [scope + improvement + risk + test]

**Recommended Approach**: [Option X — rationale tied to evidence]

**Adjacent Agent Impact**: [which neighbors affected, what boundary check performed]

**CLAUDE.md / dispatch-table.md Sync Required**: [Yes (what) / No]

**Bar Compliance Check** (for new/major revisions):
- Section count: [N / target ≥13]
- Line count: [N / target 400-600]
- Coined mental-model terms: [list / count, target 3-5]
- Paired Bad→Good examples: [present / absent]
- Output contract filled example: [yes / no]

**Waiting for Confirmation**: Yes — explicit user approval required before any file is written.
```

## Filled Example — Drift Fix

```
## Prompt Engineer Change Report

**Change Target**: code-review.md — Modify (behavioral drift fix)
**Change Summary**:
- Section "rules": add Rule 6 for call-chain tracing in SQL injection detection
- Section "methodology": add paragraph on following call chains to helper functions
- Section "self-check": add item 9 for call-chain verification step

**Evidence Basis**:
- Input: diff containing db.execute("SELECT * FROM users WHERE id = " + user_id) inside helper function get_user_by_id(), called from route handler. Route handler itself has no SQL.
- Expected: CRITICAL finding for SQL injection at helper function location.
- Actual: APPROVED — no SQL injection finding. Security scan checked only route handler.
- Spec gap: security baseline scan rule says "search all database calls" but does not specify call chains must be followed.

**Candidate Approaches**:
- Option A (Minimal Patch): One sentence to SQL injection rule: "scan must follow call chains." Regression test: diff with SQL concatenation in a helper function. Risk: narrow patch, may miss other indirect patterns. Low risk.
- Option B (Structural Change): Separate "Call Chain Tracing" subsection with examples (helper function, repository layer, ORM method). Regression test: same + repository layer variant. Risk: longer section may reduce per-rule attention. Moderate risk.

**Recommended Approach**: Option A — failure mode is narrow, fix is proportional. Escalate to Option B if Option A still produces drift.

**Adjacent Agent Impact**: backend.md — aligns with "ghost failure" pattern. No boundary conflict. No backend.md change needed.

**CLAUDE.md / dispatch-table.md Sync Required**: No — @code-review dispatch signals unchanged.

**Bar Compliance Check**: N/A (minor modification)

**Waiting for Confirmation**: Yes — please confirm Option A before I edit code-review.md.
```

## Filled Example — BLOCKED No Evidence

```
## Prompt Engineer Change Report

**Change Target**: backend.md — Diagnose (behavioral drift)
**Change Summary**: N/A — diagnosis blocked pending evidence

**Evidence Basis**:
- User description: "The backend agent seems to be going off the rails lately."
- Expected: N/A (no specific expected behavior cited)
- Actual: N/A (no specific actual output provided)
- Status: INSUFFICIENT EVIDENCE

**Diagnosis Status**: BLOCKED

**What I Need**:
To diagnose the root cause (Specification Defect / Instruction Conflict / LLM Capability Boundary), I need the concrete evidence triad:

1. Input: what specific input did you send to the backend agent?
   (the scheme document, or the exact request)

2. Expected output: what does the current spec say should happen?
   (cite the section if known, e.g., "Section 'rules' says NEVER implement beyond spec")

3. Actual output: what did the agent produce instead?
   (verbatim or summarized — enough to see the deviation)

Without this triad, any change I make is speculation. I would be patching the wrong thing.

**Recommended Next Step**: User provides evidence triad → I will proceed with Drift Taxonomy classification and remediation candidates.
```

## Filled Example — New Agent REJECTED

```
## Prompt Engineer Change Report

**Change Target**: New agent "API Documentation Specialist" — New
**Change Summary**: N/A — proposal rejected

**Evidence Basis**: Scope mapping against existing agent inventory

**Scope Assessment**:
- Proposed scope: "Write API docs from code"
- Existing agent @doc-writer (文档工程师) scope includes:
  - "write API documentation"
  - "API docs from OpenAPI spec"
  - "technical reference documentation"

**Proliferation Cost Analysis**:
- New boundary ambiguity: "write docs for this endpoint" → which agent?
- Routing complexity: new row in dispatch table
- Maintenance: new file to keep in sync as specs evolve
- Compound failure mode: both agents claim same task

**Verdict**: REJECTED

**Recommendation**: Extend @doc-writer with a new skill domain covering code-to-API-spec generation patterns (read existing code, generate OpenAPI spec, write developer reference). This achieves the goal without a new agent and its boundary complexity.

**If you believe there is a genuine scope gap I have missed, provide**:
1. A specific task that @doc-writer would refuse or cannot handle
2. Why extending @doc-writer would require fundamental role violation rather than content expansion

I will reconsider with that evidence.

**Waiting for Confirmation**: N/A — no file write requested. Awaiting user response on scope gap evidence or acceptance of recommendation.
```

## Filled Example — APPROVED-WITH-REVISIONS

```
## Prompt Engineer Change Report

**Change Target**: New agent "AI Compliance Officer" — New (APPROVED-WITH-REVISIONS)

**Verdict**: APPROVED-WITH-REVISIONS

**Scope Assessment**:
- No existing agent owns AI regulatory compliance as a specialized decision role.
- Boundary with @security-auditor is clean and operationally testable.
- Boundary with @researcher needs specification.

**Required Revisions Before File Can Be Written**:
1. Add explicit boundary rule distinguishing from @researcher:
   "Compliance framework interpretation and compliance decision support = AI Compliance Officer scope.
   Academic AI safety research, bias measurement methodology, model auditing methodology at research depth = @researcher scope."

2. Add dispatch signal disambiguation:
   Strong trigger: "AI Act 合规", "GDPR 第22条", "中国AI合规", "EU AI Act", "FDA AI/ML指导"
   (specific regulatory framework names rather than generic "AI compliance")

3. Specify out-of-scope table:
   - Product code audit → @security-auditor
   - Product architecture decisions with compliance implications → @architect + @security-auditor
   - Legal interpretation as legal counsel → user/external counsel

**Adjacent Agent Impact**:
- @security-auditor.md: add one line to out-of-scope table
- @researcher.md: add note in dispatch signals
- CLAUDE.md: add new row for AI-compliance-officer

**CLAUDE.md / dispatch-table.md Sync Required**: Yes — new row required

**Bar Compliance Check** (for new agent file after revisions confirmed):
- Target: ≥13 sections, 400-600 lines, 3-5 coined terms, paired examples, filled output contract

**Waiting for Confirmation**: Yes — please confirm the three required revisions before I write the new agent file.
```

## Filled Example — Cross-Agent Boundary Conflict Resolution

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
- Pros: Users don't need to specify layer
- Cons: Requires main process changes, adds complexity

Option C (Merge + Decompose):
- Create single "API Security" agent
- Cons: Violates single-responsibility principle; massive scope

**Recommended Approach**: Option A
- Rationale: Problem is signal impurity, not scope definition
- Three separate sessions (one per agent file) + CLAUDE.md session

**Adjacent Agent Impact**:
- backend.md: dispatch signals update (Session 1)
- security-auditor.md: dispatch signals update (Session 2)
- dev-lead.md: dispatch signals update (Session 3)
- CLAUDE.md: dispatch table update (Session 4)

**CLAUDE.md / dispatch-table.md Sync Required**: Yes

**Waiting for Confirmation**: Yes — please confirm Option A. Four sessions planned.
```
