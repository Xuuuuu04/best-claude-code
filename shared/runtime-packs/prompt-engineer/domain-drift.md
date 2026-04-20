---
title: "Prompt Engineer — Domain: Drift Diagnosis Depth"
description: "完整漂移诊断协议：Specification Defect vs Instruction Conflict vs LLM Capability Boundary 的检测方法、证据收集模板、根因分类流程图"
source: core.md §Domain 3 深度扩展
---

# Domain: Drift Diagnosis Depth

## 1. Drift Taxonomy 完整检测协议

### 1.1 Class 1: Specification Defect（规格缺陷）

**定义**：Agent prompt 中没有任何规则、指令或示例覆盖产生漂移的输入。Agent 对该情况完全没有指导。

**检测方法 — 三步验证法**：

```python
def detect_specification_defect(agent_prompt: str, input_text: str,
                                 expected_output: str, actual_output: str) -> dict:
    """
    三步验证法检测规格缺陷
    """
    result = {"is_defect": False, "governing_sections": [],
              "coverage_depth": "none", "recommendation": ""}

    # Step 1: 关键词覆盖检查
    input_keywords = extract_semantic_keywords(input_text)
    prompt_sections = parse_sections(agent_prompt)

    for section in prompt_sections:
        section_keywords = extract_semantic_keywords(section.content)
        overlap = set(input_keywords) & set(section_keywords)
        if overlap:
            result["governing_sections"].append({
                "section_id": section.id,
                "overlap_keywords": list(overlap),
                "coverage_score": len(overlap) / len(input_keywords)
            })

    # Step 2: 行为覆盖检查
    if not result["governing_sections"]:
        result["is_defect"] = True
        result["coverage_depth"] = "none"
        result["recommendation"] = f"添加新 section 覆盖输入关键词: {input_keywords}"
        return result

    # Step 3: 期望行为映射检查
    for gs in result["governing_sections"]:
        section = get_section_by_id(prompt_sections, gs["section_id"])
        if expected_behavior_mapped(expected_output, section):
            gs["behavior_covered"] = True
        else:
            gs["behavior_covered"] = False
            result["is_defect"] = True
            result["coverage_depth"] = "partial"
            result["recommendation"] = (
                f"Section {gs['section_id']} 提及了主题但未覆盖期望行为。"
                f"需要添加具体规则: '{expected_output[:100]}...'"
            )

    return result
```

**区分标准**：

| 检查项 | Specification Defect | Instruction Conflict | Capability Boundary |
|---|---|---|---|
| 相关 section 是否存在 | 否 或 存在但不覆盖行为 | 是，且多个规则同时适用 | 是，规则清晰但执行失败 |
| 规则数量 | 0 或 1 | ≥2 | ≥1 |
| 规则关系 | 无规则 | 规则互相矛盾 | 规则不自相矛盾 |
| 多次 prompt 变体测试 | 修复后消失 | 修复后消失 | 修复后仍复发 |
| 修复方向 | 添加缺失规格 | 添加优先级规则 | 任务分解 |

**BAD → GOOD 对比**：

```markdown
# BAD — 模糊的规格（导致 Specification Defect）
Section "错误处理":
"处理各种错误情况。"

# 结果：Agent 对 "数据库连接超时" 和 "外键约束冲突" 产生相同响应
# 因为规格没有区分不同错误类型的处理方式

# GOOD — 精确的规格
Section "错误处理":
"数据库连接超时 → 返回 503 Service Unavailable，记录 retry_after=30s"
"外键约束冲突 → 返回 409 Conflict，error_code='FK_VIOLATION'"
"唯一约束冲突 → 返回 409 Conflict，error_code='DUPLICATE_ENTRY'"
"查询超时 → 返回 504 Gateway Timeout，记录 slow_query_log"
```

### 1.2 Class 2: Instruction Conflict（指令冲突）

**定义**：Prompt 中两个或多个规则对特定输入类互相矛盾。Agent 无法同时满足所有适用规则。

**检测方法 — 冲突矩阵法**：

```python
def detect_instruction_conflict(agent_prompt: str, input_text: str) -> dict:
    """
    冲突矩阵法检测指令冲突
    """
    result = {"has_conflict": False, "conflicting_rules": [],
              "conflict_type": "", "resolution": ""}

    # 提取所有适用规则
    applicable_rules = find_applicable_rules(agent_prompt, input_text)

    # 构建冲突矩阵
    for i, rule1 in enumerate(applicable_rules):
        for rule2 in applicable_rules[i+1:]:
            conflict_type = classify_conflict(rule1, rule2, input_text)
            if conflict_type:
                result["has_conflict"] = True
                result["conflicting_rules"].append({
                    "rule1": rule1.id,
                    "rule2": rule2.id,
                    "rule1_text": rule1.text[:100],
                    "rule2_text": rule2.text[:100],
                    "conflict_type": conflict_type
                })

    return result

def classify_conflict(rule1, rule2, input_text) -> str:
    """分类冲突类型"""
    # Type A: 行为冲突 — 两个规则要求相反的行为
    if is_behavioral_opposite(rule1, rule2):
        return "behavioral_opposite"

    # Type B: 范围冲突 — 一个规则要求做 X，另一个规则禁止在 Y 情况下做 X
    if is_scope_overlap(rule1, rule2, input_text):
        return "scope_overlap"

    # Type C: 优先级冲突 — 两个规则都适用但无优先级说明
    if is_priority_ambiguous(rule1, rule2):
        return "priority_ambiguous"

    return ""
```

**常见冲突模式**：

```markdown
## 冲突模式库

### Pattern 1: 安全 vs 范围
- Rule A: "NEVER 修改 scheme 文档之外的文件"
- Rule B: "ALWAYS 立即修复安全漏洞"
- 输入：在 scheme 之外的文件中发现了 SQL 注入
- 冲突：不能同时"不修改"和"立即修复"
- 解决：添加优先级规则 "安全漏洞覆盖不修改范围规则。发现安全漏洞 → 标记为 CRITICAL → 路由到 @security-auditor"

### Pattern 2: 速度 vs 质量
- Rule A: "尽快完成任务"
- Rule B: "必须运行完整测试套件才能提交"
- 输入：紧急修复请求
- 冲突："尽快"与"完整测试"可能矛盾
- 解决：添加条件规则 "紧急修复允许最小回归测试（受影响模块），但必须在 24h 内补全测试"

### Pattern 3: 详细 vs 简洁
- Rule A: "输出必须包含所有细节"
- Rule B: "输出不超过 500 字"
- 输入：复杂架构评审
- 冲突：无法同时满足
- 解决：添加分层输出规则 "概要 ≤200 字 + 详细附录不限字数"

### Pattern 4: 自主 vs 请示
- Rule A: "遇到不确定时立即 BLOCK 并请示"
- Rule B: "保持工作流连续性，不要频繁中断"
- 输入：边界模糊的任务
- 冲突：不确定时该继续还是该 BLOCK
- 解决：定义明确的 BLOCK 条件清单，清单外的情况继续执行
```

**BAD → GOOD 对比**：

```markdown
# BAD — 无优先级规则
Section "rules":
1. NEVER 修改范围外的文件
2. ALWAYS 修复安全漏洞
3. NEVER 跳过测试
4. 紧急情况下可以跳过测试

# 结果：Agent 在紧急安全修复时行为不可预测

# GOOD — 明确的优先级层级
Section "rules":
1. 安全漏洞 > 范围限制（发现安全漏洞 → 标记 CRITICAL → 路由 security-auditor）
2. 范围限制 > 速度要求（不能为赶进度突破范围）
3. 测试要求：正常情况下必须完整测试；P0 事故允许最小回归测试 + 24h 内补全
4. 所有例外必须显式记录并通知 PM
```

### 1.3 Class 3: LLM Capability Boundary（能力边界）

**定义**：漂移在多个 prompt 变体中反复出现。增加 prompt 精度可以提升表现但无法消除漂移。任务超出了 LLM 在单次调用中可靠完成的能力。

**检测方法 — 变体压力测试**：

```python
def detect_capability_boundary(agent_prompt: str, input_text: str,
                                expected_output: str, max_variations: int = 5) -> dict:
    """
    变体压力测试检测能力边界
    """
    result = {
        "is_boundary": False,
        "drift_rate": 0.0,
        "variations_tested": 0,
        "improvement_ceiling": False,
        "recommendation": ""
    }

    drift_count = 0
    variations = generate_prompt_variations(agent_prompt, n=max_variations)

    for variation in variations:
        output = llm_generate(variation, input_text)
        if is_drift(output, expected_output):
            drift_count += 1
        result["variations_tested"] += 1

    drift_rate = drift_count / len(variations)
    result["drift_rate"] = drift_rate

    # 判定标准
    if drift_rate > 0.6:
        result["is_boundary"] = True
        result["improvement_ceiling"] = True
        result["recommendation"] = (
            "能力边界确认。停止添加规则，改为任务分解。"
            "将复杂任务拆分为 2-4 个简单子任务，每个子任务有明确的输入输出契约。"
        )
    elif drift_rate > 0.3:
        result["is_boundary"] = "suspected"
        result["recommendation"] = (
            "疑似能力边界。尝试进一步简化 prompt 规则，"
            "如果简化后漂移率仍 >30%，确认为能力边界。"
        )
    else:
        result["recommendation"] = "非能力边界。继续优化 prompt 规格。"

    return result
```

**能力边界判定流程图**：

```
开始
  │
  ▼
收集漂移证据（≥3 次独立实例）
  │
  ▼
生成 3-5 个 prompt 变体（简化/重组/强调不同规则）
  │
  ▼
对每个变体运行相同测试输入
  │
  ▼
计算漂移率
  │
  ├─── 漂移率 < 30% ───→ 非能力边界 → 优化规格
  │
  ├─── 漂移率 30-60% ──→ 疑似能力边界 → 进一步简化测试
  │
  └─── 漂移率 > 60% ───→ 确认能力边界 → 任务分解
                              │
                              ▼
                    设计子任务拆分方案
                              │
                              ▼
                    每个子任务：单一职责、明确输入输出、可独立验证
                              │
                              ▼
                    验证子任务组合是否覆盖原任务
                              │
                              ▼
                    结束
```

**BAD → GOOD 对比**：

```markdown
# BAD — 持续添加规则（能力边界错误处理）
Section "安全检查":
1. 检查 SQL 注入
2. 检查 XSS
3. 检查 CSRF
4. 检查路径遍历
5. 检查不安全的反序列化
6. 检查 SSRF
7. 检查命令注入
8. 检查 LDAP 注入
9. 检查 XML 外部实体
10. 检查不安全的加密算法
... (20+ 条规则)

# 结果：规则越多，Agent 遗漏率越高。LLM 无法可靠跟踪 20+ 条检查规则。

# GOOD — 任务分解
Step 1: 运行安全扫描工具（自动化）
  - 输入：代码 diff
  - 输出：扫描报告（潜在漏洞列表）
  - 工具：semgrep / bandit / trivy

Step 2: 审查扫描输出中的误报
  - 输入：扫描报告 + 代码上下文
  - 输出：确认漏洞列表（去除误报）
  - 判断标准：是否有实际利用路径

Step 3: 对每个确认漏洞应用修复模板
  - 输入：确认漏洞 + 漏洞类型
  - 输出：修复建议
  - 模板库：SQL 注入模板、XSS 模板、CSRF 模板...
```

## 2. 证据收集模板

### 2.1 完整证据三元组模板

```markdown
## Drift Evidence Triad

### Input（输入）
- **原始请求**：[用户发送给 agent 的完整请求文本]
- **上下文状态**：[agent 开始时的项目状态，相关文件列表]
- **环境参数**：[模型版本、温度设置、工具可用性]

### Expected（期望输出）
- **引用规格**：[agent prompt 中应该管辖此行为的 section ID 和具体文本]
- **期望行为**：[根据规格，agent 应该产生的具体输出]
- **成功标准**：[可验证的通过条件]

### Actual（实际输出）
- **实际输出**：[agent 实际产生的完整输出或关键摘要]
- **偏差描述**：[实际与期望的具体差异点]
- **影响评估**：[此偏差对项目/流程的影响程度]

### 证据质量评级
- [ ] 输入可复现（相同输入能否再次产生相同结果？）
- [ ] 期望有规格依据（期望行为是否来自明确的 prompt 规则？）
- [ ] 实际输出完整（是否有截断或省略关键部分？）
- [ ] 三者同时满足 → 证据有效，可进入诊断
- [ ] 任一缺失 → 证据不足，BLOCK 并要求补充
```

### 2.2 漂移实例记录表

```markdown
| 实例 ID | 时间 | Agent | 输入摘要 | 漂移类型 | 根因分类 | 修复状态 | 回归测试 |
|---------|------|-------|----------|----------|----------|----------|----------|
| DRIFT-001 | 2026-04-15 | backend | 紧急修复 + 跳过测试 | 行为漂移 | Class 2: 冲突 | 已修复 | 通过 |
| DRIFT-002 | 2026-04-18 | code-review | 辅助函数 SQL 注入未检出 | 行为漂移 | Class 1: 缺陷 | 已修复 | 通过 |
| DRIFT-003 | 2026-04-20 | frontend | 复杂组件状态管理 | 行为漂移 | Class 3: 边界 | 任务分解 | 待验证 |
```

### 2.3 根因分析深度检查清单

```markdown
## Root Cause Analysis Checklist

### 规格缺陷检查（Class 1）
- [ ] 输入中的每个关键词是否在 prompt 中有对应覆盖？
- [ ] 覆盖的 section 是否包含具体的行为指令（而非模糊描述）？
- [ ] 期望输出是否可以从 prompt 规则中逻辑推导出来？
- [ ] 如果添加一个新手阅读此 prompt，能否正确预测期望行为？

### 指令冲突检查（Class 2）
- [ ] 列出所有适用于此输入的规则（≥2 条？）
- [ ] 这些规则是否要求矛盾的行为？
- [ ] 是否有明确的优先级规则解决冲突？
- [ ] 如果没有优先级规则，添加后是否能消除漂移？

### 能力边界检查（Class 3）
- [ ] 漂移是否在简化 prompt 后仍然出现？
- [ ] 漂移是否在 3+ 个 prompt 变体中出现？
- [ ] 增加更多规则是否边际改善递减？
- [ ] 任务是否可以分解为更简单的子任务？
- [ ] 子任务组合是否能覆盖原任务的全部要求？

### 误诊防护
- [ ] 是否排除了用户输入本身模糊的可能性？
- [ ] 是否排除了环境/工具层的问题？
- [ ] 是否确认了漂移不是偶发的（≥2 次独立实例）？
```

## 3. 根因分类流程图

```
┌─────────────────────────────────────────────────────────────────┐
│                        Drift Reported                          │
│                    (用户报告或监控系统发现)                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 1: 证据收集                                                │
│ - 获取输入（Input）                                              │
│ - 获取期望输出（Expected）                                       │
│ - 获取实际输出（Actual）                                         │
│ - 验证三元组完整性                                              │
└────────────────────────────┬────────────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
    ┌─────────────────┐           ┌─────────────────┐
    │  三元组完整？    │           │  三元组不完整？  │
    │      Yes        │           │       No        │
    └────────┬────────┘           └────────┬────────┘
             │                             │
             ▼                             ▼
    ┌─────────────────┐           ┌─────────────────┐
    │ 进入 Step 2     │           │ BLOCK           │
    │ 根因分类        │           │ 请求补充证据    │
    └────────┬────────┘           └─────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 2: 检查适用规则数量                                         │
│ - 解析 prompt 中所有适用规则                                     │
│ - 计数：0 条 / 1 条 / ≥2 条                                      │
└────────────────────────────┬────────────────────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
    ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
    │   0 条规则      │ │   1 条规则      │ │   ≥2 条规则     │
    │   覆盖输入      │ │   覆盖输入      │ │   覆盖输入      │
    └────────┬────────┘ └────────┬────────┘ └────────┬────────┘
             │                   │                   │
             ▼                   ▼                   ▼
    ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
    │ Class 1:        │ │ 检查规则是否    │ │ 检查规则是否    │
    │ Specification   │ │ 足够具体        │ │ 互相矛盾        │
    │ Defect          │ │                 │ │                 │
    │                 │ │                 │ │                 │
    │ 修复：添加      │ │ 否 → Class 1    │ │ 是 → Class 2    │
    │ 缺失规格        │ │ 是 → 进入       │ │ 否 → 进入       │
    │                 │ │ Class 3 检查    │ │ Class 3 检查    │
    └─────────────────┘ └─────────────────┘ └─────────────────┘
                             │                   │
                             └─────────┬─────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 3: LLM Capability Boundary 检查                             │
│ - 生成 3-5 个 prompt 变体                                        │
│ - 运行相同测试输入                                               │
│ - 计算漂移率                                                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
    ┌─────────────────┐           ┌─────────────────┐
    │  漂移率 > 60%   │           │  漂移率 ≤ 60%   │
    │                 │           │                 │
    │ Class 3:        │           │ 重新分类：      │
    │ Capability      │           │ - 如果是 0 条   │
    │ Boundary        │           │   → Class 1     │
    │                 │           │ - 如果是 ≥2 条  │
    │ 修复：任务分解  │           │   且不矛盾      │
    │                 │           │   → 规格不够    │
    │                 │           │   具体，Class 1 │
    └─────────────────┘           └─────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ Step 4: 生成诊断报告                                             │
│ - 根因分类（Class 1/2/3）                                        │
│ - 证据链（哪个 section 失败 + 为什么）                           │
│ - 3 个修复候选方案                                               │
│ - 推荐方案 + 理由                                                │
│ - 回归测试设计                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## 4. 修复策略矩阵

| 根因分类 | 修复策略 | 禁止做法 | 验证方法 |
|---|---|---|---|
| Class 1: Specification Defect | 添加缺失的规格，精确到输入→行为映射 | 使用模糊描述（"适当处理"） | 新规格能否让新手正确预测行为？ |
| Class 2: Instruction Conflict | 添加优先级规则或条件分支 | 删除其中一个规则（可能丢失重要约束） | 冲突输入是否产生确定行为？ |
| Class 3: Capability Boundary | 任务分解为简单子任务 | 继续添加更多规则 | 子任务是否各自漂移率 < 30%？ |

## 5. 常见误诊与防护

### 误诊 1: 将 Class 3 误判为 Class 1

**场景**：复杂任务持续漂移，prompt-engineer 不断添加规则，漂移率不降反升。

**防护**：设置规则数量上限（15 条/section）。超过上限仍未解决 → 强制进入 Class 3 检测流程。

### 误诊 2: 将用户输入模糊误判为 Class 1

**场景**：用户输入本身有歧义，agent 的"漂移"实际上是输入多义性的合理反映。

**防护**：在诊断前，先验证输入是否可被多个 agent 合理解释。如果是 → 问题在调度层，不在 agent 规格层。

### 误诊 3: 将偶发错误误判为系统性漂移

**场景**：单次异常输出被当作漂移模式处理。

**防护**：要求 ≥2 次独立实例（不同时间或不同输入但相同模式）才能启动诊断流程。

### 误诊 4: 环境/工具层问题误判为 prompt 问题

**场景**：工具调用失败、网络超时、模型版本变更导致的行为变化。

**防护**：诊断前检查环境日志，排除工具层故障。
