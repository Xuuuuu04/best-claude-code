# AI编排大师 — Baseline Scenarios

## Scenario 1: n8n Stripe Webhook → Order Fulfillment (Canonical)

**Input**:
- @pm task: "Implement order fulfillment workflow on n8n: Stripe fires payment.succeeded Webhook, we update order status and send confirmation email. Platform: n8n (already deployed). API contract from @dev-lead: GET /orders/{id}, PATCH /orders/{id}/status, POST /email/send."

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Workflow topology: [Webhook trigger] → [Stripe signature verify] → [Idempotency check (stripe_events table)] → [IF new event] → [GET order] → [PATCH order status to PAID] → [POST confirmation email] → [200 response]
- Idempotency: extract `body.id` (Stripe event ID) → check `stripe_events` table unique constraint → skip if exists, process and record if not
- Error handling table: GET /orders HTTP 5xx → retry 3× (2s/4s/8s) → dead-letter + Slack; PATCH order status → dead-letter + Slack (CRITICAL — no retry, data integrity risk); POST /email → Log warning, continue (non-critical)
- Node count: 9 nodes, 3 external call nodes, 2 conditional nodes
- Platform expression syntax: `{{ $json.amount * 100 }}`, `{{ $env.ORDER_SERVICE_URL }}`
- Credentials: all by name — 'Stripe-Webhook-Secret', 'Order-Service-API-Key', 'Email-Service-Bearer', 'Main-DB'
- Deliverable: `workflows/stripe-payment-fulfillment.json` (valid JSON, importable)
- Prerequisites documented: stripe_events table migration (T-028 must be applied), n8n must have HTTPS endpoint for Stripe Webhook delivery
- Test results: happy path PASS + error paths PASS + idempotency PASS
- Next step: @test-func (test scenarios listed), @devops (HTTPS Webhook endpoint for production)

**Key Decision Points**:
- Idempotency check is the FIRST processing node (before any state-changing operation)
- Error branches designed simultaneously with happy path — not added later
- Email failure is NON-CRITICAL: workflow continues with warning log (email is not order fulfillment)
- DB write failure is CRITICAL: dead-letter + alert (data integrity cannot be degraded)
- No credentials embedded in workflow JSON — all reference credential store by name
- JSON syntax validated before delivery

---

## Scenario 2: BLOCKED — Platform Not Confirmed

**Input**:
- User: "Build an automation workflow that monitors new GitHub issues and uses AI to categorize them and add labels."
- No platform specified.

**Expected Output Structure**:
- Status: BLOCKED — platform selection required before implementation
- Response: "This automation is implementable on multiple platforms (n8n, Dify, Coze, Zapier, custom backend), and the correct choice depends on your existing stack and team familiarity. Platform selection belongs to @ai-navigator. Please dispatch @ai-navigator with this brief:"
  - "Use case: GitHub issue → AI classification → apply label"
  - "Key decision factors: does the team have an existing n8n instance? Is LLM API access already configured somewhere? Is low-code preferred or is a backend integration acceptable?"
  - "Once @ai-navigator provides a recommendation and @dev-lead confirms, dispatch me with the confirmed platform and I will implement."
- Do NOT start implementing on an assumed platform
- Do NOT ask the user to choose without context (that is @ai-navigator's job)

**Key Decision Points**:
- BLOCK fires before any node design or configuration
- Route correctly: @ai-navigator evaluates platforms, @dev-lead confirms decision
- Provide clear routing guidance — not just "I can't do this"
- The brief for @ai-navigator is specific enough to produce a useful recommendation

---

## Scenario 3: Dify RAG Workflow — Customer Support Bot (Complex)

**Input**:
- @pm task: "Build a Dify chatbot for customer support. Queries should search our product knowledge base first (already uploaded to Dify). If retrieval confidence is low, escalate to human support by sending a Slack message. Platform: Dify (deployed)."

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Workflow topology (DSL YAML):
  - Start node → Knowledge Retrieval node (search product_kb, semantic+keyword hybrid, top_k=5, score_threshold=0.65) → IF node (check if `retrieval_results.score > 0.65`)
  - High confidence branch: LLM node (model: gpt-4o-mini, system prompt with retrieved context + user query Jinja2 template `{{#context#}}...{{query}}`) → End node (return LLM response)
  - Low confidence branch: HTTP Request node (POST to Slack webhook, body includes user query + conversation ID) → End node (return fallback message "Your question has been escalated to our support team.")
- Error handling:
  - Knowledge retrieval node failure → fallback to LLM without context (graceful degradation — LLM answers from training data, log that retrieval failed)
  - Slack HTTP Request failure → retry 2× (60s backoff) → log dead-letter + internal alert (critical: human escalation must not be silently dropped)
- Dify DSL YAML structure: `app.mode: chatflow`, `conversation_variables` for session tracking, `environment_variables` for Slack webhook URL (not inline)
- Score threshold decision: 0.65 chosen as starting point; recommend A/B testing after 100 queries to tune
- Deliverable: `workflows/customer-support-dify-dsl.yml` (valid YAML, importable via Dify DSL import)
- Prerequisites: product_kb knowledge base already exists in Dify; Slack webhook URL configured in Dify environment variables as `SLACK_ESCALATION_WEBHOOK`
- Next step: @test-func (test with: common product question → high confidence LLM answer; unusual edge question → Slack escalation fires; Slack service down → retry + alert)

**Key Decision Points**:
- Score threshold is documented as a tunable parameter with tuning recommendation — not hardcoded as "the answer"
- Low confidence escalation failure is CRITICAL (not non-critical like email) — human escalation must not be silently dropped
- Knowledge retrieval failure uses graceful degradation fallback (LLM without context) — NOT full workflow failure
- Slack webhook URL in Dify environment variables — not inline in DSL
- DSL YAML syntax is Dify-specific (Jinja2 `{{#context#}}`, conversation_variables) — not generic
