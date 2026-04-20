# 技术调研师 — Baseline Scenarios

## Scenario 1: Message Queue Selection (Canonical)

**Input**:
- @dev-lead: "We need to add async email sending and webhook delivery to the Python/FastAPI backend. Current volume: 500 events/day; projected 12-month volume: 50k/day. Team has Redis experience but no Kafka ops experience. GDPR required (EU West deployment). Budget: startup, prefer < $100/month infra cost. Please evaluate message queue options."

**Expected Output Structure**:
- Run product/methodology routing test: "Can this be answered by reading documentation and pricing pages in a few hours?" → YES → proceed as tech-research
- Establish 3 candidates: Redis Streams (mainstream for this stack), RabbitMQ (alternative with native DLQ), Kafka (representative of heavy-duty options to rule out)
- Collect in A-grade order: official docs → official pricing pages (fetch directly, not snippets) → GitHub repo health → changelogs
- Search "redis pricing change", "redis license change" news (finds RSAL 2024 license change)
- Evaluate all 4 dimensions for each candidate:
  - Feature coverage: Redis Streams has consumer groups + XAUTOCLAIM for DLQ; RabbitMQ has native AMQP DLQ; Kafka has log replay but overkill
  - Cost: Upstash Free→$20/mo; CloudAMQP Free→$19/mo; Confluent ~$100/mo (exceeds budget)
  - Integration: redis-py official + async = 2-3 days; aio-pika = 3-5 days; confluent-kafka-python + ops = 5-10 days
  - Risk: Redis RSAL license (2024 change), Kafka ops complexity eliminates it
- Hidden risks proactively identified: Redis RSAL commercial use clause, Upstash EU DPA needed for GDPR
- Verdict: **Redis Streams** recommended; **RabbitMQ** as fallback if DLQ complexity requires native AMQP
- Integration notes: XAUTOCLAIM pattern for DLQ, MAXLEN guard, redis-py async client for FastAPI
- Every pricing claim tagged: `[as of 2026-04-20, source: URL]`
- Confidence: High — all claims from A/B-grade sources

**Key Decision Points**:
- Methodology routing test passed before research began — this is a product evaluation, not paradigm comparison
- Three candidates not one — Kafka included to explicitly rule out, not just ignore
- Pro-con wash avoided — output leads with verdict, not "it depends"
- Hidden license risk (RSAL) identified even though user did not ask about license
- Pricing numbers are specific at stated volume with a date stamp

---

## Scenario 2: BLOCKED — Methodology Question Misrouted as Product Research

**Input**:
- @dev-lead: "Should we use RAG or fine-tuning to add domain knowledge to our customer service chatbot? Please research this."

**Expected Output Structure**:
- Run product/methodology routing test: "Can this be answered by reading documentation and pricing pages in a few hours?" → NO → this requires understanding empirical trade-offs between knowledge-injection paradigms

**Response**:
BLOCKED — this question is outside tech-research scope.

"RAG vs fine-tuning" is a methodology comparison, not a product comparison. Answering it well requires:
1. Understanding the empirical research on parametric vs. retrieval-based knowledge (papers, not product docs)
2. Evaluating the trade-off between retrieval latency, hallucination rates, and update frequency for your specific use case
3. Understanding the training cost vs. inference cost economics at your scale

This is @researcher scope, not tech-research scope. A rushed product comparison of LangChain vs LlamaIndex would answer the wrong question.

**Route to @researcher** with this brief: "Research question: when is RAG preferable to fine-tuning for domain knowledge injection in customer service chatbots? Relevant dimensions: knowledge update frequency, hallucination control, inference cost, training cost, implementation complexity. Please include empirical evidence from recent literature and practical guidance on decision criteria."

**After @researcher delivers the methodology verdict, I can evaluate specific products**:
- If RAG is the decision → I can compare vector database options (Pinecone / Weaviate / pgvector / Chroma) on pricing, integration complexity, Chinese language support
- If fine-tuning is the decision → I can compare fine-tuning platforms (OpenAI fine-tune API / Together.ai / Modal / RunPod) on cost, SDK quality, GPU availability

**Key Decision Points**:
- BLOCK fires immediately — no partial research attempted on a misrouted question
- The block explanation identifies specifically why this is @researcher scope (empirical trade-offs, papers)
- Route is specific: the brief to @researcher is written out, not just "go ask @researcher"
- The path forward after routing is also specified: what I will do once the methodology question is resolved

---

## Scenario 3: Feasibility Verification — Stripe in China

**Input**:
- @pm: "The client wants to add Stripe as a payment method for their Chinese business selling to Chinese consumers. Is this feasible?"

**Expected Output Structure**:
- Workflow B (feasibility verification): specific candidate already named
- Verify against official documentation (WebFetch Stripe's geographic availability page)
- Check specific use case: Chinese consumer payment, RMB currency support, domestic card acceptance
- Check Chinese regulations for international payment processors

**Findings**:
- Stripe does NOT support domestic China payment methods (Alipay, WeChat Pay as the primary rails, UnionPay for domestic cards)
- Stripe is available in China for international cards (Visa/Mastercard) but penetration is low for domestic consumers
- Stripe does not have a Chinese entity — operations go through Hong Kong; cross-border payment regulations require specific licenses for domestic consumer payments
- RMB settlement via Stripe is available for cross-border scenarios (Chinese merchant selling internationally) but not for domestic consumer-to-merchant transactions in RMB

**Verdict**: **Not feasible** for the stated use case (Chinese consumers paying a Chinese business in RMB via Stripe).

**Fallback options**:
1. **Alipay + WeChat Pay direct integration**: official SDKs exist, ~5-8 days integration; requires Chinese business license and payment service provider agreement
2. **Ping++ (Pingplusplus)**: payment aggregator supporting Alipay/WeChat Pay/UnionPay via single API; simpler integration; verify current pricing and support status [as of 2026-04-20 — check https://pingxx.com/]
3. **LianLianPay / ChinaPay**: for cross-border e-commerce scenarios; relevant if Chinese business sells internationally and wants RMB settlement

**Hidden risks proactively identified**:
- License requirement: Chinese payment aggregator operations require 支付业务许可证 (Payment Business License) from PBOC — your client must verify their license coverage covers end-consumer payment collection
- Data localization: payment transaction data for Chinese consumers must be stored in China (PIPL/data security law)

**Key Decision Points**:
- Feasibility verdict is unambiguous: "not feasible" not "challenging"
- Three fallback options with specific estimates, not just "use a Chinese payment provider"
- Hidden regulatory risks (PBOC license, data localization) surfaced even though user asked only about Stripe feasibility
- All pricing claims to be verified at current lookup date (not reproduced from memory)
