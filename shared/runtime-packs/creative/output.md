# 创意策划师 — Output Contract

## 标准输出模板

### 命名任务输出

```
## Creative Delivery: Naming

**Task Type**: Naming — [Product/Feature description]
**Target User**: [Specific description — not "everyone"]
**Positioning Coordinates**:
- Target user: [specific human in specific context]
- Emotional job: [what the brand does emotionally]
- Distinctive space: [what no competitor currently occupies]

### Naming Candidates

| # | Name | Framework | Meaning / Rationale | Risk Assessment | Tone Fit |
|---|------|-----------|--------------------|--------------------|----------|
| 1 | [name] | [Descriptive] | [specific rationale] | [trademark/homophone/domain] | [fit] |
| 2 | [name] | [Evocative] | [specific rationale] | [trademark/homophone/domain] | [fit] |
| 3 | [name] | [Coined] | [specific rationale] | [trademark/homophone/domain] | [fit] |
| 4 | [name] | [Persona] | [specific rationale] | [trademark/homophone/domain] | [fit] |
| 5 | [name] | [Poetic] | [specific rationale] | [trademark/homophone/domain] | [fit] |

**Recommended**: [Name A] + [Name B]
**Rationale**: [Specific behavioral prediction for each — why this user, this context, this outcome]

### Risk Summary
- Trademark: [summary of scan results]
- Homophone: [summary of tone/dialect checks]
- Cultural: [summary of sensitivity checks]
- Domain: [availability summary]

**Archive Path**: docs/creative/[project]-naming-proposal-v[N].md
**Next Step**: @visual-designer for design system / @doc-writer for brand manual
```

### 品牌调性输出

```
## Creative Delivery: Brand Tone + Visual Direction

**Task Type**: Brand Tone + Visual Direction
**Target User**: [Specific description]
**Positioning Coordinates**: [Target user + emotional job + distinctive space]

### 4-Axis Tone Positioning

- **Formal↔Casual**: [position, e.g., 7/10 toward Casual] — [one-sentence rationale tied to user context]
- **Serious↔Playful**: [position] — [rationale]
- **Reserved↔Expressive**: [position] — [rationale]
- **Premium↔Accessible**: [position] — [rationale]

### Reference Brands

1. Like [Product Name]'s [specific quality], but [specific differentiator]
2. Like [Product Name]'s [specific quality], but [specific differentiator]
3. Like [Product Name]'s [specific quality], but [specific differentiator]

### Voice Guidelines

**DO**:
- [Guideline 1] — Example: "[sentence demonstrating the voice]"
- [Guideline 2] — Example: "[sentence demonstrating the voice]"

**DON'T**:
- [Guideline 1] — Counter-example: "[sentence a writer without guidance would write]"
- [Guideline 2] — Counter-example: "[sentence a writer without guidance would write]"

### Visual DNA Keywords (Concept Level)

- **Color family**: [3-5 emotional descriptors, e.g., "warm amber of afternoon light, soft coral energy"]
- **Typography personality**: [register descriptors, e.g., "humanist warmth — rounded, approachable"]
- **Design movement references**: [2-3 specific anchors, e.g., "Monzo's card warmth + Duolingo's rounded illustration"]
- **Interaction character**: [how the brand moves, e.g., "bouncy micro-interactions for positive moments"]

**Archive Path**: docs/brand-mood-board.md
**Next Step**: @visual-designer — translate mood board to design system tokens
```

### Slogan 任务输出

```
## Creative Delivery: Slogan

**Task Type**: Slogan / Tagline
**Target User**: [Specific description]
**Positioning Coordinates**: [Target user + emotional job + distinctive space]

### Slogan Candidates

| # | Slogan | Archetype | Usage Context | Rhythm Test |
|---|--------|-----------|---------------|-------------|
| 1 | [slogan] | [Promise] | [hero headline] | [syllable count + cadence] |
| 2 | [slogan] | [Provocation] | [advertising] | [syllable count + cadence] |
| 3 | [slogan] | [Pride] | [tagline] | [syllable count + cadence] |
| 4 | [slogan] | [Contrast-Elevation] | [onboarding] | [syllable count + cadence] |
| 5 | [slogan] | [Concrete-Image] | [social media] | [syllable count + cadence] |

**Primary Recommendation**: [Slogan] — [rationale: why this works for this user]
**Backup**: [Slogan] — [rationale: when primary doesn't fit]

**Brand Fit Test**: [Could top 3 competitors use this? Why not?]

**Archive Path**: docs/creative/[project]-slogan-proposal-v[N].md
**Next Step**: @doc-writer for brand manual integration / @frontend for UI copy
```

---

## 输出组件详解

### 1. 命名框架覆盖要求

必须覆盖至少 5 个不同框架：

| 框架 | 说明 | 示例 |
|------|------|------|
| Descriptive | 直接描述产品类别 | Runbook, DataSync |
| Evocative | 唤起情感/隐喻 | Anchor, Strand |
| Coined | 发明词，控制音韵 | Lumio, Drydock |
| Compressed | 缩写/首字母 | IBM, AWS (不推荐用于新品牌) |
| Persona | 人名/角色感 | Alexa, Oscar |
| Poetic | 文化/文学/自然 | Quorum, Meridian |
| Geographic | 地名/ heritage | Amazon, Patagonia |

**禁忌**: 5 个候选来自同一框架 = Synonym Shuffle 反模式。

---

### 2. Six-Baseline 过滤器

每个候选必须通过以下 6 项测试：

| 基线 | 测试方法 | 通过标准 |
|------|----------|----------|
| Readable | 朗读测试 | 中文 ≤4 音节，英文 ≤3 音节 |
| Memorable | 隔夜测试 | 12 小时后无提示能回忆 |
| Typeable | 键盘输入测试 | 无易混淆字符，无歧义拼音 |
| Registerable | 初步商标搜索 | 无 obvious 冲突 |
| Unambiguous | 多语言/方言检查 | 无不良谐音/歧义 |
| Category-signal | 类别信号测试 | 能暗示产品领域（或故意颠覆） |

---

### 3. 风险扫描输出格式

```
### Risk Scan: [Name]

**Trademark**:
- CNIPA: [unverified / preliminary search shows conflict in Class 9 / clean initial scan]
- USPTO: [unverified / conflict found / clean]
- EUIPO: [unverified / conflict found / clean]
- 建议: [正式查询建议]

**Homophone**:
- 普通话: [是否有不良谐音？]
- 主要方言: [粤语/上海话/闽南语 是否有歧义？]
- 英语: [是否有 phonemic misreading？]

**Cultural**:
- 宗教敏感性: [有/无]
- 政治敏感性: [有/无]
- 历史关联: [有/无]
- 已知品牌碰撞: [有/无]

**Domain**:
- .com: [taken / available / unverified]
- .io: [taken / available / unverified]
- .ai: [taken / available / unverified]
- 建议: [域名策略]
```

---

### 4. 4-Axis 品牌坐标规范

每个轴必须包含：
- **具体位置**: 0-10 的数字，不是 "偏 Casual"
- **一句话理由**: 绑定到具体用户和场景
- **竞争定位**: 与竞品的差异

```
Formal↔Casual: 7/10 toward Casual
- 理由: Gen-Z 用户特别不信任金融产品中的正式语体；正式词汇是他们父母银行用的
- 竞争差异: Monzo (6/10) 更 casual，Revolut (4/10) 更 formal，我们取中间偏 casual

Serious↔Playful: 5/10 — 平衡但略 playful
- 理由: 钱是严肃的，但关于钱的羞耻感需要通过轻松来化解
- 竞争差异: 传统银行 (2/10) 太严肃，Gamified fintech (8/10) 太轻浮
```

---

### 5. 视觉 DNA 关键词库

#### 色彩家族关键词

| 情感方向 | 关键词示例 |
|----------|-----------|
| 信任/专业 | 深海蓝、钢铁灰、 slate、 midnight |
| 温暖/亲和 | 午后琥珀、柔珊瑚、奶油色、蜜桃 |
| 活力/创新 | 电光蓝、荧光绿、日落橙 |
| 高端/奢华 | 香槟金、象牙白、炭黑、勃艮第红 |
| 自然/健康 | 森林绿、天空蓝、大地棕、薄荷 |
| 科技/未来 | 霓虹紫、赛博蓝、钛白、石墨 |

#### 字体性格关键词

| 字体类型 | 性格描述 | 适用场景 |
|----------|----------|----------|
| Geometric Sans | 现代、严谨、略冷 | 科技 SaaS、金融 |
| Humanist Sans | 亲和、温暖、人文 | 教育、健康、消费 |
| Transitional Serif | 权威、 heritage、 established | 法律、金融、出版 |
| Slab Serif | 自信、直接、耐用 | 工业、户外、工具 |
| Display/Expressive | 个性驱动、 memorable | 时尚、娱乐、DTC |
| Monospace | 技术、精确、复古 | 开发者工具、数据 |

#### 设计运动参考

| 运动 | 特征 | 品牌信号 |
|------|------|----------|
| Swiss/International Style | 网格主导、功能优先 | 专业、理性、 timeless |
| Skeuomorphism | 材质模仿、高认知熟悉度 | 温暖、实体感、保守 |
| Flat Design | 抽象、清晰、可扩展 | 现代、简洁、数字原生 |
| Neumorphism | 柔和 3D、微妙深度 | 触觉、柔和、实验性 |
| Glassmorphism | 半透明、分层深度 | 高端数字感、未来 |
| Neo-Brutalism | 原始结构、反 polish | 真实、反主流、年轻 |
| Art Deco | 几何装饰、奢华 | 高端、复古、戏剧 |
| Minimalism | 极少元素、留白 | 精致、专注、高端 |

---

## 存档路径规范

- 命名提案: `docs/creative/[project]-naming-proposal-v[N].md`
- 品牌调性: `docs/brand-mood-board.md`
- Slogan 提案: `docs/creative/[project]-slogan-proposal-v[N].md`
- 文案方向: `docs/creative/[project]-copy-direction-v[N].md`

---

## 质量检查清单

交付前逐项确认：

- [ ] 至少 5 个命名候选，来自不同框架
- [ ] 每个候选有具体的行为理由，不是通用形容词
- [ ] 视觉方向在概念层（无 hex、font-stack、spacing）
- [ ] 商标/域名状态诚实声明（未验证 = 明确说未验证）
- [ ] 生成前已确认三个定位坐标
- [ ] Slogan 通过竞品测试（"前 3 名竞品能用吗？"）
- [ ] 语调轴位置具体（7/10，不是"偏 Casual"）
- [ ] 参考品牌对比精确（借用了什么品质 + 差异化什么）
- [ ] 下一步推荐明确（@visual-designer / @doc-writer / @frontend）
- [ ] 所有输出有存档路径
