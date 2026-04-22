---
name: quality-verdict
description: Final quality verdict methodology for the Harness team. Covers three-evidence synthesis (functional report + UI screenshots + security audit), five-layer UI assessment, three-tier verdict evaluation (PASS / CONDITIONAL PASS / BLOCKED), severity classification, conditional pass design with independently fixable follow-up Tasks, and cross-task quality pattern detection. Loaded by @test-lead via skills: frontmatter.
type: skill
---

# Quality Verdict Skill

## 1. Evidence Triad

Three required evidence streams for standard delivery gate:

| Stream | Source | Artifact | Gate |
|---|---|---|---|
| Functional correctness | @test-func | Structured test report | Required |
| Visual integrity | @test-ui | Screenshot set + interaction-check.md | Required |
| Security posture | @security-auditor | Security audit report | Required for pre-launch/milestone |

Missing any required stream → BLOCKED immediately. Do not proceed with partial evidence.

## 2. Evidence-First Protocol

Every claim in the verdict must tie to a specific artifact and finding:

BAD: "Test-func reports all tests passed. UI team says screenshots look fine."
GOOD: "Read test report at `tests/reports/T-047-v2.md`: 34 cases, 32 PASS, 2 FAIL (TC-019, TC-026). Read screenshot set: 5-state coverage confirmed except checkout error state. Read security audit: 1 High finding SA-003 unresolved. Verdict: BLOCKED."

Never base verdict on summary descriptions — always read the actual artifact files.

## 3. Functional Test Report Audit

Evaluate:
- **Coverage matrix**: all eight dimensions covered? Any uncovered dimension without documented reason → flag
- **Failed test cases**: each FAIL has reproduction path + actual response + business impact?
- **Pass rate**: supports delivery?
- **Expected value source integrity**: expected behavior traces back to documented business requirement, not implementation

## 4. Five-Layer UI Assessment

| Layer | Assessment Criteria |
|---|---|
| Layout | Visual hierarchy, alignment (consistent grid), spacing (8px base), whitespace balance |
| Visual | Color accuracy against design tokens, contrast ratios (WCAG AA), typography hierarchy |
| Interaction | Button click affordance, state feedback visibility, error message clarity |
| Content | Text truncation handling, placeholder copy quality, data format consistency |
| Holistic | Mobile viewport (375px), no half-finished components, overall professionalism |

Flag absence of any five UI states: initial / empty / loading / success / error.

## 5. Security Audit Evaluation

- Tally Critical and High findings: any unresolved → unconditional BLOCKED
- Verify OWASP coverage for pre-launch audits
- Verify dependency scan was actually executed (not just asserted)
- Auditor's ratings stand — unresolved High is a veto regardless of own security opinion

## 6. Three-Tier Verdict Evaluation

Evaluate all three tiers before selecting one:

**Tier 1 — Can PASS be justified?**
- All Critical/High resolved
- No core-path functional failures
- UI assessment passes
- Security clean

**Tier 2 — Can CONDITIONAL PASS be justified?**
- Core functionality correct end-to-end
- All Critical/High resolved
- Remaining issues medium/low
- Issues are independently fixable (fixing doesn't modify core flow, can deploy separately)
- Each expressible as standalone Task with concrete acceptance criterion

**Tier 3 — Must BLOCKED be issued?**
- Any unresolved Critical/High finding
- Core-path test failure
- Incomplete evidence stream
- UI state broken in user-blocking way

## 7. Severity Classification

| Severity | Definition |
|---|---|
| **Critical** | Any security Critical/High finding; complete core flow failure; data integrity risk; auth bypass or privilege escalation |
| **High** | Non-core feature completely non-functional; UI unusable for significant user portion; High security finding; P99 > 10× SLA |
| **Medium** | Non-core defect with documented workaround; UI cosmetic; Low security with no realistic exploit |
| **Low** | Text copy errors, minor visual misalignment, edge-case failures in low-frequency flows |

## 8. Conditional Pass Design

Every CONDITIONAL PASS follow-up item must pass the independence test:
- Fixing it doesn't modify core flow code
- Can be deployed in a separate deployment
- Doesn't create user-blocking problem

Failing independence test → reclassify as BLOCKED.

Follow-up Task specification:
- Description: what defect
- Acceptance criterion: what "fixed" looks like
- Target agent
- Priority (P1/P2/P3)

Risk declaration: "By issuing CONDITIONAL PASS, this team accepts that [specific defect] will reach production in its current state. Follow-up Tasks are not optional."

## 9. Cross-Task Quality Pattern Detection

- Same defect category in 3+ consecutive Tasks → escalate to @pm for root cause investigation
- @test-func consistently missing same dimension → flag to @pm for test protocol update
- Task through 3+ BLOCKED verdicts without resolution → flag to @pm for scheme or architecture review

## 10. Verdict Report Structure

```markdown
## Quality Verdict: [Task ID] — Round [N]

**Verdict Date**: [YYYY-MM-DD]
**Verdict Type**: [PASS / CONDITIONAL PASS / BLOCKED]

### Evidence Inventory
| Stream | Source Agent | Artifact Path | Status |

### Functional Test Assessment
**Coverage matrix**: [N/8 dimensions covered]
**Test case results**: [N PASS, N FAIL, N BLOCKED]
**Functional judgment**: [PASS / FAIL]

### UI Assessment (Five Layers)
**Layout/Visual/Interaction/Content/Holistic**: [PASS / Issue]
**UI state coverage**: [5/5 confirmed / Missing: states]
**UI judgment**: [PASS / FAIL]

### Security Assessment
**Critical findings**: [0 / N — status]
**High findings**: [0 / N — status]
**Security judgment**: [PASS / BLOCKED on [finding IDs]]

### Three-Tier Evaluation
- PASS justified? [Yes / No — reason]
- CONDITIONAL PASS justified? [Yes / No — reason]
- BLOCKED required? [Yes / No — reason]

### Final Verdict
**[PASS / CONDITIONAL PASS / BLOCKED]**
[Rationale — specific evidence references]

[If CONDITIONAL PASS]:
**Follow-up Tasks**: [description | Agent | Priority | Acceptance criterion]
**Risk Declaration**: By issuing CONDITIONAL PASS, the team accepts that [defect] will be present in production.

[If BLOCKED]:
**Blocking items**: [Finding ID] | [description] | Fix: [action] | Route to: @[agent]
```

## 11. Anti-Patterns

| Name | Symptom | Correction |
|---|---|---|
| **Evidence Laundering** | Verdict based on summary/verbal assertion rather than artifact files | Always read actual test report, screenshot directory, security audit document |
| **Green-Wash Verdict** | PASS on narrow criteria while ignoring quality problems | Evaluate evidence quality, not just evidence count |
| **Iteration Sympathy** | Lowering quality bar due to team effort or rework count | Iteration count is a signal to escalate, not to sympathize |
| **Verdict Shortcutting** | Jumping directly to verdict without evaluating all three tiers | Read all three evidence streams, evaluate all three tiers, then select |
| **Vague Rejection** | BLOCKED without specifying what to fix, who fixes it, and what "fixed" looks like | Every BLOCKED item: specific finding, failure description, corrective action, target agent |
