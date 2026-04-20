---
title: "Prompt Engineer — Domain: Dispatch Signal Audit Depth"
description: "调度信号审计深度协议：强信号 vs 弱信号分类、信号重叠检测、边界测试方法、信号语义纯度检查清单"
source: core.md §Domain 2.2 深度扩展
---

# Domain: Dispatch Signal Audit Depth

## 1. 调度信号分类体系

### 1.1 强信号（Strong Triggers）

**定义**：无需额外上下文即可确定路由到特定 agent 的输入特征。强信号具有排他性 —— 一个强信号应只属于一个 agent。

**强信号特征**：

```markdown
1. **词汇特异性**：使用专业术语或特定领域词汇
   - 例："JWT 签名验证" → @security-auditor（强）
   - 反例："检查代码" → 多个 agent 可能适用（弱）

2. **任务类型明确**：输入明确属于某 agent 的核心职责
   - 例："写这个接口的后端实现" → @backend（强）
   - 反例："帮我看看这个" → 不明确（弱）

3. **无歧义路由**：不存在其他 agent 可能合理接收此输入
   - 例："设计数据库表结构" → @database（强）
   - 反例："优化性能" → @backend 或 @database 都可能（弱）
```

**强信号示例库**：

```markdown
| Agent | 强信号示例 | 信号强度 |
|---|---|---|
| @backend | "写这个接口", "后端实现", "POST /api/users" | ★★★ |
| @frontend | "写这个页面", "前端实现", "React 组件" | ★★★ |
| @database | "加表", "改字段", "迁移脚本", "索引优化" | ★★★ |
| @code-review | "审代码", "code review", "检查这个 PR" | ★★★ |
| @security-auditor | "安全审计", "OWASP", "渗透测试" | ★★★ |
| @test-func | "测功能", "走主流程", "验收测试" | ★★★ |
| @dev-lead | "技术方案", "拆分到文件级", "架构设计" | ★★★ |
| @pm | "排期", "需求", "Sprint", "优先级" | ★★★ |
| @prompt-engineer | "改 prompt", "调 agent 规格", "agent 跑偏" | ★★★ |
| @ai-navigator | "AI 框架", "模型选型", "LangChain" | ★★★ |
```

### 1.2 弱信号（Weak Triggers）

**定义**：需要额外上下文或确认才能确定路由的输入特征。弱信号可能适用于多个 agent，需要主进程判断或用户确认。

**弱信号特征**：

```markdown
1. **词汇泛化**：使用通用词汇，多个 agent 都可能涉及
   - 例："优化" → @backend（代码优化）、@database（查询优化）、@dev-lead（流程优化）

2. **任务边界模糊**：输入位于两个 agent 的职责交界
   - 例："API 设计" → @dev-lead（接口设计）或 @backend（API 实现）

3. **需要澄清**：输入缺少关键信息，无法直接路由
   - 例："这个有问题" → 什么问题？代码问题 → @code-review；行为问题 → @test-func
```

**弱信号处理协议**：

```markdown
当弱信号输入到达时：

1. **识别候选 agent**：列出所有可能接收此输入的 agent（≤3 个）
2. **检查上下文**：是否有最近的对话历史可以消除歧义？
3. **默认路由规则**：
   - 如果候选包含 @pm → 路由到 @pm 进行初步分析
   - 如果候选都是技术 agent → 路由到 @dev-lead 进行任务分解
   - 如果无法确定 → 向用户请求澄清，不猜测
4. **记录弱信号**：将弱信号实例记录到 dispatch-table.md 的 "待澄清信号" 列表
```

### 1.3 信号强度评估矩阵

```python
def evaluate_signal_strength(signal: str, agent_scope: str) -> dict:
    """评估信号强度"""
    result = {
        "signal": signal,
        "strength": "weak",
        "score": 0,
        "factors": []
    }

    # 因素 1: 专业术语密度
    technical_terms = extract_technical_terms(signal)
    if len(technical_terms) >= 2:
        result["score"] += 3
        result["factors"].append("高专业术语密度")
    elif len(technical_terms) == 1:
        result["score"] += 1
        result["factors"].append("低专业术语密度")

    # 因素 2: 任务类型明确性
    if is_explicit_task_type(signal):
        result["score"] += 3
        result["factors"].append("任务类型明确")

    # 因素 3: 范围限定词
    if has_scope_limiter(signal):
        result["score"] += 2
        result["factors"].append("有范围限定")

    # 因素 4: 排除其他 agent
    competing_agents = find_competing_agents(signal)
    if len(competing_agents) == 0:
        result["score"] += 2
        result["factors"].append("无竞争 agent")
    elif len(competing_agents) == 1:
        result["score"] += 1

    # 判定
    if result["score"] >= 7:
        result["strength"] = "strong"
    elif result["score"] >= 4:
        result["strength"] = "medium"

    return result
```

## 2. 信号重叠检测

### 2.1 重叠检测方法

```python
class SignalOverlapDetector:
    """检测调度信号重叠"""

    def __init__(self, agent_files: List[str]):
        self.agents = self._load_agents(agent_files)

    def detect_overlaps(self) -> List[dict]:
        """检测所有信号重叠"""
        overlaps = []

        # 提取所有强信号
        all_signals = defaultdict(list)
        for agent in self.agents:
            for signal in agent.strong_triggers:
                all_signals[signal.lower()].append(agent.name)

        # 查找重复信号
        for signal, agents in all_signals.items():
            if len(agents) > 1:
                overlaps.append({
                    "signal": signal,
                    "agents": agents,
                    "type": "exact_overlap",
                    "severity": "CRITICAL" if len(agents) > 2 else "WARNING"
                })

        # 查找语义重叠（相似信号）
        semantic_overlaps = self._detect_semantic_overlaps()
        overlaps.extend(semantic_overlaps)

        return overlaps

    def _detect_semantic_overlaps(self) -> List[dict]:
        """检测语义相似的信号重叠"""
        overlaps = []

        for i, agent1 in enumerate(self.agents):
            for agent2 in self.agents[i+1:]:
                similar_signals = self._find_similar_signals(
                    agent1.strong_triggers,
                    agent2.strong_triggers
                )
                if similar_signals:
                    overlaps.append({
                        "agents": [agent1.name, agent2.name],
                        "similar_signals": similar_signals,
                        "type": "semantic_overlap",
                        "severity": "WARNING"
                    })

        return overlaps

    def _find_similar_signals(self, signals1: List[str], signals2: List[str]) -> List[dict]:
        """查找语义相似的信号对"""
        similar = []
        for s1 in signals1:
            for s2 in signals2:
                similarity = calculate_semantic_similarity(s1, s2)
                if similarity > 0.7:  # 阈值
                    similar.append({
                        "signal1": s1,
                        "signal2": s2,
                        "similarity": similarity
                    })
        return similar
```

### 2.2 重叠解决策略

```markdown
## 信号重叠解决策略

### 策略 1: 信号细化（Signal Refinement）
将泛化信号细化为更具体的子信号。

**示例**：
- 重叠信号："优化" → @backend 和 @database
- 解决方案：
  - @backend: "代码优化", "算法优化", "性能调优（应用层）"
  - @database: "查询优化", "索引优化", "慢查询优化"

### 策略 2: 范围限定（Scope Qualifier）
为信号添加范围限定词。

**示例**：
- 重叠信号："API" → @dev-lead 和 @backend
- 解决方案：
  - @dev-lead: "API 设计", "接口规范", "API 版本策略"
  - @backend: "API 实现", "写这个接口", "endpoint 实现"

### 策略 3: 上下文路由（Context Routing）
利用对话上下文消除歧义。

**示例**：
- 重叠信号："测试" → @test-func 和 @test-ui
- 解决方案：
  - 如果最近讨论的是功能逻辑 → @test-func
  - 如果最近讨论的是 UI 界面 → @test-ui
  - 如果无上下文 → 询问用户 "功能测试还是界面测试？"

### 策略 4: 信号合并（Signal Merge）
如果两个 agent 的信号高度重叠且无法区分，考虑合并 agent。

**触发条件**：
- 重叠信号 ≥3 个
- 无法通过细化或限定区分
- 两个 agent 的 out-of-scope 表互相引用
```

## 3. 边界测试方法

### 3.1 "给定输入 X，哪个 agent 接收？" 测试

**测试设计原则**：

```markdown
1. **边界输入选择**：选择位于两个 agent 职责边界的输入
2. **预期结果明确**：测试前应确定期望的接收 agent
3. **覆盖所有边界**：每对相邻 agent 至少测试 3 个边界输入
4. **记录实际结果**：记录实际路由结果，与预期对比
```

**边界测试模板**：

```markdown
## 边界测试: [Agent A] vs [Agent B]

### 测试输入 1: [具体输入]
- **预期接收**: [Agent X]
- **实际接收**: [记录]
- **判定**: [PASS / FAIL]
- **如果 FAIL**: [分析原因，是信号问题还是范围问题]

### 测试输入 2: [具体输入]
- **预期接收**: [Agent X]
- **实际接收**: [记录]
- **判定**: [PASS / FAIL]

### 测试输入 3: [具体输入]
- **预期接收**: [Agent X]
- **实际接收**: [记录]
- **判定**: [PASS / FAIL]

### 测试结果汇总
- PASS: [N] / [Total]
- 通过率: [N%]
- 判定: [ACCEPTABLE ≥80% / NEEDS-IMPROVEMENT 60-80% / CRITICAL <60%]
```

### 3.2 边界测试用例库

```markdown
## 预设边界测试用例

### @backend vs @database
| 输入 | 预期 | 说明 |
|---|---|---|
| "用户表加字段" | @database |  Schema 变更 |
| "用户查询接口慢" | @backend | 应用层优化 |
| "用户表加索引" | @database | 数据库层优化 |
| "用户数据验证" | @backend | 应用层校验 |

### @dev-lead vs @architect
| 输入 | 预期 | 说明 |
|---|---|---|
| "这个模块怎么拆" | @dev-lead | 技术方案 |
| "整个系统怎么拆" | @architect | 架构重构 |
| "微服务边界" | @architect | 架构决策 |
| "这个接口怎么设计" | @dev-lead | 技术方案 |

### @code-review vs @security-auditor
| 输入 | 预期 | 说明 |
|---|---|---|
| "审这个 PR" | @code-review | 代码审查 |
| "检查安全漏洞" | @security-auditor | 安全审计 |
| "这个 SQL 有没有注入" | @code-review | 代码级检查 |
| "整体安全评估" | @security-auditor | 全面审计 |

### @test-func vs @test-ui
| 输入 | 预期 | 说明 |
|---|---|---|
| "测登录功能" | @test-func | 功能测试 |
| "看登录界面" | @test-ui | 界面测试 |
| "测支付流程" | @test-func | 功能测试 |
| "截图看样式" | @test-ui | 界面测试 |
```

### 3.3 自动化边界测试脚本

```python
#!/usr/bin/env python3
"""Agent Boundary Test Runner"""

import json
from typing import List, Dict

class BoundaryTestRunner:
    def __init__(self, dispatch_table_path: str):
        with open(dispatch_table_path) as f:
            self.dispatch_table = json.load(f)

    def run_test(self, input_text: str, expected_agent: str) -> dict:
        """运行单个边界测试"""
        # 模拟路由决策
        routed_agent = self._route_input(input_text)

        return {
            "input": input_text,
            "expected": expected_agent,
            "actual": routed_agent,
            "pass": routed_agent == expected_agent,
            "confidence": self._calculate_routing_confidence(input_text)
        }

    def run_test_suite(self, tests: List[Dict]) -> dict:
        """运行测试套件"""
        results = []
        for test in tests:
            result = self.run_test(test["input"], test["expected"])
            results.append(result)

        pass_count = sum(1 for r in results if r["pass"])
        total = len(results)
        pass_rate = pass_count / total if total > 0 else 0

        return {
            "results": results,
            "pass_count": pass_count,
            "total": total,
            "pass_rate": pass_rate,
            "status": "PASS" if pass_rate >= 0.8 else "WARNING" if pass_rate >= 0.6 else "FAIL"
        }

    def generate_report(self, suite_result: dict) -> str:
        """生成测试报告"""
        lines = [
            "# Agent Boundary Test Report",
            f"\nPass Rate: {suite_result['pass_rate']:.1%} ({suite_result['pass_count']}/{suite_result['total']})",
            f"Status: {suite_result['status']}",
            "\n## Detailed Results"
        ]

        for r in suite_result["results"]:
            status = "✓ PASS" if r["pass"] else "✗ FAIL"
            lines.append(f"\n{status}: '{r['input']}'")
            lines.append(f"  Expected: {r['expected']} | Actual: {r['actual']}")
            lines.append(f"  Confidence: {r['confidence']:.1%}")

        return "\n".join(lines)

# 预设测试套件
DEFAULT_TEST_SUITE = [
    # backend vs database
    {"input": "用户表加字段", "expected": "database"},
    {"input": "用户查询接口慢", "expected": "backend"},
    {"input": "用户表加索引", "expected": "database"},

    # dev-lead vs architect
    {"input": "这个模块怎么拆", "expected": "dev-lead"},
    {"input": "整个系统怎么拆", "expected": "architect"},

    # code-review vs security-auditor
    {"input": "审这个 PR", "expected": "code-review"},
    {"input": "整体安全评估", "expected": "security-auditor"},

    # test-func vs test-ui
    {"input": "测登录功能", "expected": "test-func"},
    {"input": "看登录界面", "expected": "test-ui"},
]

if __name__ == "__main__":
    runner = BoundaryTestRunner("~/.claude/shared/guides/dispatch-table.json")
    result = runner.run_test_suite(DEFAULT_TEST_SUITE)
    print(runner.generate_report(result))
```

## 4. 信号语义纯度检查清单

### 4.1 语义纯度定义

**信号语义纯度**：一个强信号的语义空间（所有可能的解释）完全包含在单一 agent 的职责范围内，不存在跨 agent 的语义泄漏。

### 4.2 纯度检查清单

```markdown
## Signal Semantic Purity Checklist

### 对每个强信号执行：

- [ ] **独占性检查**：此信号是否只属于一个 agent？
  - 方法：在 dispatch-table.md 中搜索相同或相似信号
  - 通过标准：0 个其他 agent 有相同信号

- [ ] **语义封闭性检查**：此信号的所有合理解释是否都在该 agent 范围内？
  - 方法：列出信号的 3 种可能解释
  - 通过标准：所有解释都落在同一 agent 的职责范围内

- [ ] **无泛化检查**：信号是否过于泛化？
  - 方法：信号是否可被用于非预期的任务？
  - 通过标准：信号的专业术语密度 ≥2

- [ ] **上下文独立性检查**：信号是否需要上下文才能正确路由？
  - 方法：单独看信号，能否确定接收 agent？
  - 通过标准：无需上下文即可确定

- [ ] **稳定性检查**：信号的含义是否随时间稳定？
  - 方法：信号是否在技术演进中含义可能改变？
  - 通过标准：信号基于稳定的领域概念

### 信号纯度评级

| 评级 | 标准 | 行动 |
|---|---|---|
| PURE | 5/5 检查通过 | 保持 |
| MOSTLY-PURE | 4/5 通过 | 优化未通过项 |
| IMPURE | 3/5 通过 | 必须修改信号 |
| CONFLICTED | ≤2/5 通过 | 立即解决重叠 |
```

### 4.3 语义纯度审计报告模板

```markdown
## Signal Semantic Purity Audit Report

### Agent: [agent-name]
### Audit Date: [date]
### Auditor: [name]

#### Strong Triggers Analysis

| # | Signal | Exclusivity | Semantic Closure | No Generalization | Context Independence | Stability | Rating |
|---|--------|-------------|------------------|-------------------|----------------------|-----------|--------|
| 1 | [signal] | ✓/✗ | ✓/✗ | ✓/✗ | ✓/✗ | ✓/✗ | [rating] |
| 2 | [signal] | ✓/✗ | ✓/✗ | ✓/✗ | ✓/✗ | ✓/✗ | [rating] |
| 3 | [signal] | ✓/✗ | ✓/✗ | ✓/✗ | ✓/✗ | ✓/✗ | [rating] |

#### Issues Found

1. **[Signal]**: [问题描述]
   - 影响：与其他 agent 的重叠/泛化/不稳定
   - 建议：[修改方案]

#### Overall Rating
- PURE signals: [N]
- MOSTLY-PURE: [N]
- IMPURE: [N]
- CONFLICTED: [N]

#### Recommendations
- [具体修改建议]
```

## 5. 信号维护规范

### 5.1 信号变更流程

```markdown
## Dispatch Signal Change Workflow

### 触发条件
1. 新增 agent → 需要分配信号
2. 修改 agent 范围 → 可能需要调整信号
3. 发现信号重叠 → 需要解决冲突
4. 用户反馈派错 agent → 需要优化信号

### 变更流程
1. **评估影响**：
   - 此变更影响哪些 agent 的信号？
   - 是否会产生新的重叠？
   - 是否需要更新 dispatch-table.md？

2. **制定方案**：
   - 方案 A：修改信号词汇
   - 方案 B：添加范围限定
   - 方案 C：合并/拆分 agent

3. **边界测试**：
   - 对变更后的信号运行边界测试
   - 确保通过率 ≥80%

4. **同步更新**：
   - 更新 agent 文件中的 dispatch-signals section
   - 更新 CLAUDE.md 调度表
   - 更新 dispatch-table.md

5. **回归验证**：
   - 运行完整边界测试套件
   - 确认无新的信号重叠
```

### 5.2 信号版本控制

```markdown
## Signal Version History

| 日期 | Agent | 变更类型 | 旧信号 | 新信号 | 原因 | 影响评估 |
|------|-------|----------|--------|--------|------|----------|
| 2026-04-15 | backend | 新增 | — | "写这个接口" | 新 agent | 无重叠 |
| 2026-04-18 | database | 修改 | "优化" | "查询优化" | 与 backend 重叠 | 解决重叠 |
| 2026-04-20 | test-ui | 删除 | "测试" | — | 与 test-func 重叠 | 合并信号 |
```

## 6. 调度信号完整性检查

### 6.1 覆盖完整性

```python
def check_signal_coverage(agent_files: List[str], task_categories: List[str]) -> dict:
    """检查调度信号是否覆盖所有任务类别"""
    all_signals = set()
    for file in agent_files:
        signals = extract_signals(file)
        all_signals.update(signals)

    uncovered = []
    for category in task_categories:
        if not any(is_covered(category, signal) for signal in all_signals):
            uncovered.append(category)

    return {
        "total_categories": len(task_categories),
        "covered": len(task_categories) - len(uncovered),
        "uncovered": uncovered,
        "coverage_rate": (len(task_categories) - len(uncovered)) / len(task_categories)
    }
```

### 6.2 完整性检查清单

```markdown
## Signal Coverage Checklist

### 任务类别覆盖
- [ ] 所有业务任务有对应的 agent 信号
- [ ] 所有技术任务有对应的 agent 信号
- [ ] 所有管理任务有对应的 agent 信号
- [ ] 无任务类别被遗漏

### Agent 覆盖
- [ ] 每个 agent 有 ≥3 个强信号
- [ ] 每个 agent 有弱信号说明
- [ ] 每个 agent 有 "Do NOT dispatch" 说明

### 文档同步
- [ ] agent 文件中的信号与 CLAUDE.md 一致
- [ ] CLAUDE.md 与 dispatch-table.md 一致
- [ ] 信号变更已记录到版本历史
```
