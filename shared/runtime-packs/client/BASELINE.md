# 客户沟通师 — Baseline Scenarios

## Scenario 1: Pre-Sales Intake — Semantic Enhancement (Canonical)

**Input**:
- Client message (chat log): "我们想做个类似 LinkedIn 的平台，面向建筑行业的从业者。要有 AI 功能，最好快点上线，预算大概 20 万左右。"
- No further clarification provided

**Expected Output Structure**:
- Status: CONDITIONAL GO (pending clarification items 1–5)
- Client-brief at `docs/client-brief-tradepro-v1.md`
- Project summary: B2B social networking platform for construction professionals, Chinese market
- Core features semantically enhanced:
  - "LinkedIn-like" decomposed: User profiles [CLIENT STATED], Connection/follow system [CLIENT STATED], Content feed [CLIENT STATED]; job postings [PENDING CLARIFICATION: included?], groups [PENDING CLARIFICATION: included?]; DM messaging [PENDING CLARIFICATION]
  - Construction-specific additions [CLIENT STATED via reference to "建筑行业"]: project portfolio showcase, license/certification display — confirmed or inferred?
  - "AI 功能" → [PENDING CLARIFICATION: which capability? content recommendation? semantic search for professionals? job/project matching?]
- Timeline: "快点上线" → [PENDING CLARIFICATION: is there a hard deadline (trade show, investor demo)? What is acceptable to descope?]; feasibility assessment: 3–6 months realistic for MVP scope
- Budget: ¥200k stated → scope consistency: Strained if full LinkedIn-equivalent; realistic for a focused MVP with 3–4 core features
- Out-of-scope anchor: Mobile apps (iOS/Android native) — web-only MVP; payment/transaction features; non-Chinese language support for V1
- Pending clarification items: 5 specific questions (LinkedIn features to include/exclude, AI capability type, hard deadline, which features are V1 must-haves, decision-maker authority)
- Technical feasibility: Conventional for social platform; AI feature requires @tech-research confirmation if includes ML recommendation or semantic search
- Risk register: Budget-scope mismatch; "AI 功能" undefined — could range from simple tagging to ML recommendation (10× cost difference)
- Recommended next step: @pm (after client answers clarification items 1–5)

**Key Decision Points**:
- "类似 LinkedIn" decomposed into specific included/excluded features with PENDING CLARIFICATION tags
- "AI 功能" flagged as technically ambiguous — NOT guessed at, not passed through verbatim
- "快点" resolved as "needs hard deadline confirmation" — NOT answered with optimistic timeline
- ¥200k budget tension with scope noted honestly
- Did NOT add features client didn't mention (gold-plating avoided)

---

## Scenario 2: Post-Delivery Triage — Classification Required

**Input**:
- Client message after delivery: "搜索功能不对，我们的用户说找不到自己，而且上周新加入的供应商也搜不到。另外我们还想把搜索改成支持模糊匹配，现在只能精准匹配。"
- Original brief: keyword search of company name and contact name — confirmed in spec

**Expected Output Structure**:
- Status: CLASSIFIED — two separate issues
- Issue 1 (Bug): "Users can't find themselves and new suppliers can't be found in search"
  - Classification: Bug — this is a deviation from agreed spec (keyword search should return matching users/companies)
  - Reproduction: user reports cannot find their own account; new suppliers added last week are not returning in results
  - Likely cause: search index not updating on new registrations (needs @backend investigation)
  - Commercial consequence: Bug — included in warranty period. Route to @pm for fix Task.
- Issue 2 (Change Request): "Add fuzzy/approximate matching to search"
  - Classification: Change Request — the original spec specified keyword search. Fuzzy matching is a new behavior.
  - Impact: requires implementing fuzzy search algorithm or integrating an external search library (Elasticsearch or similar)
  - Rough scope estimate: 2–5 days @dev-lead evaluation needed before quoting
  - Commercial consequence: Change Request — requires change order. Route to @dev-lead for scope evaluation.
- Draft client response (DRAFT — user reviews before sending): "We've reviewed your feedback and identified two separate items. (1) The search not returning registered users is a bug we'll fix under warranty — our team will investigate and update you within 48 hours. (2) Adding fuzzy matching to search goes beyond the original spec (which specified exact keyword matching) — we'd be happy to scope and price this as an enhancement. Can we schedule a call this week?"

**Key Decision Points**:
- Did NOT conflate the two issues into one "client complaint"
- Did NOT route both to @pm as fix Tasks (Issue 2 is a Change Request, not a Bug)
- Client response is DRAFT — not sent directly
- Commercial consequence stated explicitly for each classification

---

## Scenario 3: Go/No-Go — NO-GO Recommendation

**Input**:
- Client request: "帮我们做个 AI 辅助诊断系统，能根据症状给出初步诊断建议，面向基层诊所，计划 6 周上线，预算 15 万。"

**Expected Output Structure**:
- Status: NO-GO — with detailed reasoning
- Technical feasibility assessment: HIGH RISK / Fundamentally infeasible at stated scope and timeline
  - AI medical diagnosis is a Class II or III medical device in China → requires NMPA (国家药品监督管理局) regulatory approval — not achievable in 6 weeks
  - Clinical validation requirements (AI diagnosis recommendations must be validated on clinical datasets per medical device standards) — not achievable at ¥150k budget
  - Liability exposure: providing "初步诊断建议" without proper regulatory approval creates significant legal liability for both the client and the development team
- Budget-scope assessment: ¥150k is 10–20× below realistic cost for a regulated AI medical device
- Timeline assessment: 6 weeks impossible even for a non-regulated prototype; regulatory approval alone takes 12–24 months
- Recommendation: NO-GO in current form. Two alternative framings if client wants to explore further:
  1. Non-regulated information display: build a symptom-checker that displays general health information (not diagnosis), clearly labeled as informational only, with no AI component — feasible in 6–8 weeks at ¥100k–150k range; does NOT require NMPA approval
  2. Regulated path: engage a specialized medical device software firm; timeline 18–24 months; budget ¥1M+ range; out of scope for this team's capabilities
- Honest disclosure: "The current specification as described cannot be safely delivered by this team within the stated constraints, and attempting to do so would expose the client to regulatory and liability risk."

**Key Decision Points**:
- Did NOT soften the recommendation to win the project
- Specific regulatory and liability risks named (NMPA, medical device classification, liability exposure)
- Alternative framings offered — not just a flat refusal
- Technical capability limits honestly disclosed
- Timeline and budget are specifically stated as infeasible with reasons, not just "it seems challenging"
