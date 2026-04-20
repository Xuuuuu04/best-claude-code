# 提示词工程师 — Baseline Scenarios

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
