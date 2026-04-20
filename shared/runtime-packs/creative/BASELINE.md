# 创意策划师 — Baseline Scenarios

## Scenario 1: Naming Task — B2B Engineering PM Tool (Canonical)

**Input**:
- @pm brief: "name a B2B SaaS project management tool for remote engineering teams at 15-50 person startups. Must feel engineering-native. Competitors: Linear, Jira, Notion. 禁区: must not feel like Jira (heavy, corporate), must not feel like a generic startup -io name."
- Budget: no brand research budget; founder-driven launch

**Expected Output Structure**:
- Status: PROCEED — all three positioning coordinates available
- Reader persona locked before generation: "engineering TL at growth-stage startup, context-switching pain, suspicious of PM tools that require 'process'"
- Naming map spans ≥5 frameworks: Evocative (Anchor, Strand), Poetic (Quorum), Coined/Metaphor (Drydock), Descriptive (Runbook)
- Six-Baseline filter applied to each: syllable count, overnight test, typeability, registrability, homophone scan, category-signal
- Risk scan for each: trademark status (CNIPA / USPTO — declared unverified where not confirmed), homophone check (Mandarin tones), domain availability (.io / .ai)
- Recommended 2 (Strand + Anchor): rationale is specific behavioral prediction, not adjectives — "engineering TL who distrusts heavy PM tools will respond to Strand because it has zero enterprise PM association and carries the core brand promise (focus, single thread of work) without being heavy-handed"
- Archive path: `docs/creative/{project}-naming-proposal-v1.md`
- Next step: @visual-designer once tone/direction approved; @doc-writer for brand manual

**Key Decision Points**:
- Did NOT generate before confirming positioning coordinates
- All 5 candidates come from different frameworks — no synonym shuffle
- Risk scan results declared honestly ("Trademark: multiple registrations in adjacent categories — CNIPA/USPTO search required") — no fabricated clean status
- Rationale is behavioral and user-specific, not adjective-based
- No hex values, font names, or spacing scales in output

---

## Scenario 2: BLOCKED — Missing Positioning Coordinates

**Input**:
- User: "帮我给 AI 写作助手取几个名字"
- No target user described, no competitive context, no positioning constraint ("禁区")

**Expected Output Structure**:
- Status: BLOCKED — three positioning coordinates unavailable
- Response structure: "Before I can generate naming candidates, I need three positioning coordinates that I cannot infer from the brief alone:"
  - "1. Target user: who specifically uses this AI writing assistant? (Options: solo freelancers writing blog content / marketing team writing ad copy / students writing essays / software engineers writing documentation / something else?) The naming territory for each group is completely different."
  - "2. Emotional job: what does this product do for the user emotionally — not functionally? (Reduces anxiety about blank pages? Creates confidence in professional writing? Saves time so they feel productive? This determines what register the name should be in.)"
  - "3. 禁区: what products or naming styles must this brand NOT resemble? (Jasper, Copy.ai, Writesonic? Corporate and boring? Cold and robotic? Gimmicky?)"
- Do NOT generate speculative names "in the meantime"
- Do NOT fill in assumed answers ("I'll assume it's for professionals")
- Ask all three questions together in one block — not sequentially

**Key Decision Points**:
- BLOCK fires before any creative generation
- All three missing coordinates identified explicitly
- Questions are precise and structured — not open-ended conversation starters
- No tentative name candidates offered "to get started"

---

## Scenario 3: Brand Tone + Visual Direction (Downstream Handoff to @visual-designer)

**Input**:
- @client structured brief: "consumer fintech app for Gen-Z users managing first salary. Competitors to emulate: Monzo (warmth), Revolut (boldness). 禁区: must not feel like a traditional bank. Must not feel clinical. Emotional keyword: 'financial confidence without shame.'"

**Expected Output Structure**:
- 4-axis tone positioning with specific positions AND rationale per axis:
  - Formal↔Casual: "7/10 toward Casual — Gen-Z users specifically distrust formal register in financial products; formal vocabulary is what their parents' banks use; rationale: user research indicates Gen-Z perceive formality as a signal that the brand is 'not for me'"
  - Serious↔Playful: "5/10 — balanced but slightly playful; money is serious but shame about money is reduced by lightness of touch; the brand earns permission to be playful by being competent first"
  - Reserved↔Expressive: "7/10 toward Expressive — the brand needs to express warmth actively because the 禁区 (traditional bank) is Reserved; silence reads as traditional bank energy"
  - Premium↔Accessible: "8/10 toward Accessible — the target user is managing their first salary; premium signals create the exact shame response the brand is trying to undo"
- Reference brands (3-5, with specific quality + differentiator):
  - "Like Monzo's warm conversational tone in push notifications, but bolder and less 'polite British' in personality"
  - "Like Revolut's visual confidence, but without the cold blue-to-navy temperature and with warmth dialed up to make it feel like a friend, not a challenger bank"
  - "Like Duolingo's permission to fail + celebrate small wins, applied to money — the emotional register of 'learning is okay' applied to financial behavior"
- Voice guidelines: 2-3 do/don't pairs with concrete example sentences
  - DO: "Normalize the learning curve." Example: "Spent more than planned this week? You'll figure it out. Your spending habits are still loading."
  - DON'T: "Use financial jargon without humor." Counterexample: "Your current debt-to-income ratio indicates suboptimal liquidity management."
- Visual DNA (concept level only — no tokens):
  - Color family: "warm amber and soft coral — approachable and energetic without clinical coldness; the palette of a sunny kitchen, not a Bloomberg terminal"
  - Typography personality: "Humanist warmth — rounded, approachable, slightly informal; not geometric/cold"
  - Design movement references: "Duolingo's rounded illustration style + Monzo's data card warmth + none of Revolut's dark mode aggression"
  - Interaction character: "Bouncy, celebratory micro-interactions for positive moments (first savings milestone); gentle, non-punitive animations for overspend warnings"
- Output: `docs/brand-mood-board.md`
- Next step: "@visual-designer — here is the mood board brief; translate to design system tokens"

**Key Decision Points**:
- Each axis has a specific position (7/10, not "leaning toward Casual") AND a rationale tied to the specific user
- Reference brands specify WHAT quality is borrowed and WHAT is differentiated — not just brand names
- Voice guidelines show plausible "don't" examples (things a writer without guidance would actually write)
- Visual DNA is concept-level only: emotional descriptors, no hex values or font names
- Output file created: `docs/brand-mood-board.md`
- Downstream routing explicit: @visual-designer receives the mood board
