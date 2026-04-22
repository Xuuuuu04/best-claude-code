---
name: client-intake
description: Customer requirement semantics, ambiguity resolution, Go/No-Go evaluation, and post-delivery issue classification. Loaded by @client via skills: frontmatter.
---

# Client Intake Skill

## 1. Semantic Enhancement Protocol

### Ambiguity Taxonomy
- **Scope-ambiguous**: "简单做一下", "基本功能" → must resolve to 3-5 concrete functions
- **Reference-dependent**: "有点像 xxx" → decompose into feature matrix: included / excluded / modified
- **Category-vague**: "加个 AI 功能" → specify: chatbot / recommendation / classification / generation
- **Priority-implicit**: "我们可能需要" → classify as Must/Should/Could/Won't
- **Timeline-relative**: "尽快", "ASAP" → confirm hard deadline and descope strategy

### Source Labeling
Every brief item MUST carry one of:
- **CLIENT STATED**: client explicitly said this
- **INFERRED**: derived from context (must flag for validation)
- **PENDING CLARIFICATION**: required but cannot be determined

### Out-of-Scope Anchor (mandatory ≥2 items)
Format: `Feature — reason — future phase if applicable`

## 2. Pre-Sales Workflow Detail

### Step 3: Resolve Semantic Ambiguity
Transform vague expressions into concrete requirements:

| Vague Expression | Resolution Target |
|---|---|
| "简单做一下" | 3-5 core functions, primary user roles |
| "有点像 xxx" | Feature matrix: included / excluded / modified |
| "要有 AI 功能" | Specific capability + data source + output format |
| "做个 APP" | Platform list (iOS/Android/Mini Program/H5) |
| "能不能快点" | Hard deadline + acceptable descope strategy |

### Step 4: Technical Feasibility Assessment
- **Conventional**: standard patterns, no novel technology risk
- **Needs pre-research**: AI/ML, unusual hardware, specialized compliance → route to @researcher
- **Fundamentally infeasible**: beyond current technology or constraints → NO-GO

### Step 5: Size and Risk Estimation
- Small: <¥50k / <1 person-month / 1-3 features
- Medium: ¥50k-300k / 2-6 months / 4-10 features
- Large: >¥300k / 6+ months / >10 features, complex integrations

Risk multipliers: ambiguity count, technical uncertainty, timeline-scope mismatch, client decision clarity

### Step 6: Go/No-Go Matrix

| Dimension | Weight | Scoring |
|---|---|---|
| Technical feasibility | 25% | 1-5 |
| Commercial viability | 25% | 1-5 |
| Execution fit | 25% | 1-5 |
| Relationship quality | 25% | 1-5 |

- 4.0-5.0: GO
- 3.0-3.9: CONDITIONAL GO (pending X)
- 1.0-2.9: NO-GO

## 3. Post-Delivery Issue Classification

### Classification Criteria

| Type | Criteria | Commercial Consequence |
|---|---|---|
| **Bug** | Reproducible deviation from agreed behavior | Warranty (usually included) |
| **Change Request** | Modification to existing functionality | Change order |
| **Usage Question** | Client doesn't know how to use existing functionality | Training |
| **Out-of-Scope Addition** | Functionality never in original contract | New engagement |

### Classification Flow
1. Is there an agreed spec for this behavior?
   - NO → Out-of-Scope Addition
   - YES → continue
2. Does current implementation match the spec?
   - YES → Change Request (client expectations differ)
   - NO → Bug
3. Is the issue about how to use existing functionality?
   - YES → Usage Question

## 4. Client Communication Craft

### Bad News Delivery
1. Acknowledge
2. Explain cause (not blame)
3. State what is being done
4. New timeline as range
5. Offer decision point

### Technical-to-Business Translation
Example: "third-party payment API deprecated webhook" → "payment notification system needs update — X days, recommend before next billing cycle"

### Tone Calibration
- Formal/technical: legal/contractual matters
- Professional/direct: scope/timeline matters
- Warm/supportive: user confusion/training matters

## 5. Anti-Patterns (with Corrections)

### Verbatim Pass-Through
Forwarding client's raw message without semantic enhancement. Correction: every brief must pass through semantic enhancement protocol.

### Silent Ambiguity
Receiving ambiguous requirement and not flagging it. Correction: every requirement forcing @dev-lead or @backend to make a behavioral choice gets `[PENDING CLARIFICATION]`.

### Feature Gold-Plating
Adding scope client didn't request. Correction: every item traces back to CLIENT STATED or INFERRED+confirmed.

### Category Collapse
Treating bugs, change requests, usage questions, out-of-scope as single category. Correction: classify first, always.

### Single-Point Timeline Commitment
Giving precise delivery date. Correction: all estimates are ranges with lower/upper bounds and assumptions.

## 6. Domain Vocabulary Translation

| Business Term | Translation |
|---|---|
| CRM | contact + pipeline + activities + reporting |
| ERP | procurement + inventory + finance + HR |
| OA | approval + calendar + document |
| 中台 | ask: data platform or business capability platform? |
| 大数据 | reporting vs warehouse vs real-time? |
| 云服务 | hosting vs cloud-native? |

## 7. Archive Paths

- Client brief: `docs/client-brief-[project]-v[N].md`
- Issue report: `docs/issue-reports/[project]-issue-[ID]-[date].md`
- Proposal: `docs/proposals/[project]-proposal-v[N].md`
