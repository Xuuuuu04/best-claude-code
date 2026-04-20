---
title: "Prompt Engineer — Domain: Agent Evolution Methodology"
description: "Agent进化方法论：失败驱动进化循环、回归测试用例构造、跨agent边界测试、版本兼容性检查"
source: core.md §Domain 2.3 深度扩展
---

# Domain: Agent Evolution Methodology

## 1. 失败驱动进化循环（Failure-Driven Evolution Loop）

### 1.1 循环定义

**失败驱动进化**是 prompt-engineer 的核心工作方法：将每一次观察到的 agent 失败转化为规格改进，使相同失败模式无法再次发生。

```
        ┌─────────────────────────────────────────┐
        │           观察（Observe）                │
        │  监控系统、用户反馈、agent 输出异常       │
        └──────────────────┬──────────────────────┘
                           │
                           ▼
        ┌─────────────────────────────────────────┐
        │           分类（Classify）               │
        │  Drift Taxonomy: Class 1/2/3            │
        │  记录到漂移实例记录表                     │
        └──────────────────┬──────────────────────┘
                           │
                           ▼
        ┌─────────────────────────────────────────┐
        │           规格变更（Spec Change）         │
        │  添加规则 / 解决冲突 / 任务分解           │
        │  生成变更报告，等待用户确认               │
        └──────────────────┬──────────────────────┘
                           │
                           ▼
        ┌─────────────────────────────────────────┐
        │           部署（Deploy）                 │
        │  执行单一文件变更                        │
        │  更新相关文档（CLAUDE.md 等）            │
        └──────────────────┬──────────────────────┘
                           │
                           ▼
        ┌─────────────────────────────────────────┐
        │           再观察（Re-observe）           │
        │  相同输入是否再次漂移？                   │
        └──────────────────┬──────────────────────┘
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
    ┌─────────────────┐       ┌─────────────────┐
    │   漂移消失       │       │   漂移复发       │
    │   ✓ 修复成功     │       │   ✗ 分类错误     │
    │                  │       │                  │
    │ 结束循环         │       │ 重新分类         │
    │                  │       │ Class 1→2→3?    │
    └─────────────────┘       └────────┬────────┘
                                       │
                                       ▼
                              ┌─────────────────┐
                              │ 如果已确认为     │
                              │ Class 3 仍复发   │
                              │ → 任务分解不足   │
                              │ → 进一步拆分     │
                              └─────────────────┘
```

### 1.2 循环各阶段详细规范

#### 阶段 1: 观察（Observe）

**观察渠道**：

```markdown
1. **用户直接反馈**："XX agent 又做错了"
2. **输出质量监控**：agent 输出与预期偏差
3. **边界测试失败**：自动化边界测试未通过
4. **代码审查发现**：@code-review 发现 agent 产生的代码有问题
5. **安全审计发现**：@security-auditor 发现 agent 遗漏安全问题
6. **测试失败**：@test-func 发现 agent 实现的功能有 bug
```

**观察记录模板**：

```markdown
## Observation Record

**Observation ID**: OBS-[YYYYMMDD]-[NNN]
**Date**: [date]
**Source**: [user-feedback / monitoring / test-failure / review]
**Agent**: [agent-name]
**Severity**: [CRITICAL / HIGH / MEDIUM / LOW]

**Observation Summary**:
[一句话描述观察到的异常]

**Evidence**:
- Input: [具体输入]
- Expected: [期望行为]
- Actual: [实际行为]
- Deviation: [偏差描述]

**Impact Assessment**:
- [ ] 影响生产代码质量
- [ ] 影响安全 posture
- [ ] 影响团队协作效率
- [ ] 影响用户满意度
- [ ] 仅影响单一任务

**Next Step**: [进入分类 / 需要补充证据 / 暂时观察]
```

#### 阶段 2: 分类（Classify）

**分类决策树**：

```
观察记录到达
    │
    ▼
证据三元组完整？
    │
    ├── No ──→ BLOCK，请求补充证据
    │
    └── Yes ──→ 适用规则数量？
                    │
                    ├── 0 条 ──→ Class 1: Specification Defect
                    │
                    ├── 1 条 ──→ 规则是否具体？
                    │               │
                    │               ├── No ──→ Class 1: Specification Defect
                    │               │
                    │               └── Yes ──→ Class 3: Capability Boundary?
                    │                               │
                    │                               └── 变体测试确认
                    │
                    └── ≥2 条 ──→ 规则是否矛盾？
                                    │
                                    ├── Yes ──→ Class 2: Instruction Conflict
                                    │
                                    └── No ──→ Class 3: Capability Boundary?
                                                    │
                                                    └── 变体测试确认
```

#### 阶段 3: 规格变更（Spec Change）

**变更设计原则**：

```markdown
1. **最小有效变更**：只修改解决此漂移所需的最小内容
2. **可追溯性**：每个变更关联一个 Observation ID
3. **可测试性**：变更必须伴随回归测试设计
4. **无副作用**：变更不应引入新的漂移风险
```

**变更报告模板**：

```markdown
## Spec Change Proposal

**Observation ID**: OBS-[ID]
**Change Type**: [Class 1/2/3]
**Target Agent**: [agent-name]
**Target Section**: [section-id]

**Current Spec**:
[当前规则文本]

**Proposed Change**:
[新规则文本]

**Rationale**:
- 漂移原因：[为什么当前规则导致漂移]
- 变更逻辑：[新规则如何解决漂移]
- 预期效果：[变更后的行为预测]

**Regression Test**:
- Input: [测试输入]
- Expected: [期望输出]
- Pass Criterion: [通过标准]

**Risk Assessment**:
- 新漂移风险：[可能引入的新问题]
- 缓解措施：[如何防止新问题]

**Adjacent Impact**:
- [ ] 影响其他 agent 的边界
- [ ] 需要更新 CLAUDE.md
- [ ] 需要更新 dispatch-table.md
```

#### 阶段 4: 部署（Deploy）

**部署检查清单**：

```markdown
## Deployment Checklist

### 变更执行前
- [ ] 变更报告已获用户确认
- [ ] 目标文件已完整读取
- [ ] 相邻 agent 已检查边界影响
- [ ] 备份已创建（如需要）

### 变更执行
- [ ] 仅修改一个 agent 文件
- [ ] 修改方式：Edit（优先）或 Write（>60% 变更）
- [ ] 变更后文件格式正确

### 变更执行后
- [ ] Bar 合规检查通过
- [ ] 相邻 agent 的 dispatch signals 未产生歧义
- [ ] CLAUDE.md 同步更新（如需要）
- [ ] dispatch-table.md 同步更新（如需要）
- [ ] 变更记录到版本历史
```

#### 阶段 5: 再观察（Re-observe）

**验证标准**：

```markdown
1. **时间窗口**：变更后观察 ≥7 天或 ≥10 次相关任务
2. **验证输入**：使用与原始漂移相同的或等价的输入
3. **成功标准**：
   - 漂移完全消失 → 修复成功
   - 漂移频率降低但未消失 → 部分成功，需要补充修复
   - 漂移频率不变 → 分类错误，重新分类
   - 出现新漂移 → 引入副作用，回滚并重新设计
```

### 1.3 进化循环度量指标

```python
class EvolutionMetrics:
    """失败驱动进化循环的度量指标"""

    def __init__(self):
        self.observations = []
        self.changes = []
        self.reobservations = []

    def calculate_mttr(self) -> float:
        """Mean Time To Repair: 从观察到修复的平均时间"""
        repair_times = []
        for obs in self.observations:
            if obs.resolved_at:
                repair_times.append(
                    (obs.resolved_at - obs.observed_at).total_seconds()
                )
        return sum(repair_times) / len(repair_times) if repair_times else 0

    def calculate_drift_recurrence_rate(self) -> float:
        """漂移复发率：修复后再次漂移的比例"""
        resolved = [o for o in self.observations if o.resolved_at]
        recurrent = [o for o in resolved if o.recurred]
        return len(recurrent) / len(resolved) if resolved else 0

    def calculate_false_classification_rate(self) -> float:
        """误分类率：修复后漂移未改善的比例"""
        classified = [o for o in self.observations if o.classification]
        misclassified = [o for o in classified
                        if o.classification != o.true_classification]
        return len(misclassified) / len(classified) if classified else 0

    def calculate_spec_improvement_rate(self) -> float:
        """规格改进率：成功修复的漂移占总观察的比例"""
        resolved = [o for o in self.observations
                   if o.status == "RESOLVED"]
        return len(resolved) / len(self.observations) if self.observations else 0
```

## 2. 回归测试用例构造

### 2.1 回归测试设计原则

```markdown
1. **针对性**：每个测试针对一个具体的漂移模式
2. **可复现**：相同输入必须产生相同输出
3. **边界覆盖**：测试应覆盖正常、边界和异常输入
4. **自动化友好**：测试可以被脚本自动执行和验证
```

### 2.2 回归测试模板

```markdown
## Regression Test Case

**Test ID**: REG-[agent]-[NNN]
**Target Agent**: [agent-name]
**Related Observation**: OBS-[ID]
**Drift Type**: [Class 1/2/3]

### Test Objective
验证 [具体规则] 在 [具体场景] 下是否被正确执行。

### Test Input
```
[具体的输入文本，应能触发原始漂移]
```

### Expected Behavior
根据 [section-id] 的规则，agent 应该：
1. [具体行为 1]
2. [具体行为 2]
3. [具体行为 3]

### Pass Criteria
- [ ] 行为 1 正确执行
- [ ] 行为 2 正确执行
- [ ] 行为 3 正确执行
- [ ] 无额外副作用

### Failure Criteria
- [ ] 行为 1/2/3 任一未执行
- [ ] 产生与原始漂移相同的错误
- [ ] 产生新的未预期行为

### Test Environment
- Agent File: [path]
- Model: [model-version]
- Temperature: [temp]
- Tools Available: [list]
```

### 2.3 回归测试套件结构

```markdown
## Agent Regression Test Suite

### Level 1: 单元测试（规则级）
测试单个规则的执行

| Test ID | Target Rule | Input | Expected | Status |
|---------|-------------|-------|----------|--------|
| REG-backend-001 | "NEVER implement beyond spec" | scheme + 额外需求 | BLOCK | PASS |
| REG-backend-002 | "Run security baseline" | 正常代码 | 5 checks | PASS |
| REG-backend-003 | "NEVER swallow exception" | empty catch | Finding | PASS |

### Level 2: 集成测试（工作流级）
测试完整工作流的执行

| Test ID | Workflow | Input | Expected Output | Status |
|---------|----------|-------|-----------------|--------|
| REG-backend-010 | A: New feature | scheme + code | Implementation report | PASS |
| REG-backend-011 | B: Bug fix | bug report + code | Fix report | PASS |

### Level 3: 系统测试（边界级）
测试跨 agent 边界行为

| Test ID | Boundary | Input | Expected Router | Status |
|---------|----------|-------|-----------------|--------|
| REG-boundary-001 | backend vs database | "加字段" | database | PASS |
| REG-boundary-002 | dev-lead vs architect | "系统重构" | architect | PASS |
```

### 2.4 自动化回归测试框架

```python
#!/usr/bin/env python3
"""Agent Regression Test Framework"""

import json
from dataclasses import dataclass
from typing import List, Optional

@dataclass
class RegressionTest:
    test_id: str
    agent: str
    input_text: str
    expected_behavior: str
    pass_criteria: List[str]
    related_observation: Optional[str] = None

@dataclass
class TestResult:
    test_id: str
    passed: bool
    actual_behavior: str
    deviations: List[str]
    timestamp: str

class RegressionTestRunner:
    def __init__(self, agent_file_path: str):
        self.agent_file = agent_file_path
        self.tests: List[RegressionTest] = []
        self.results: List[TestResult] = []

    def load_tests(self, test_suite_path: str):
        """从 JSON 文件加载测试套件"""
        with open(test_suite_path) as f:
            data = json.load(f)
        for t in data["tests"]:
            self.tests.append(RegressionTest(**t))

    def run_test(self, test: RegressionTest) -> TestResult:
        """运行单个回归测试"""
        # 模拟 agent 执行
        actual = self._simulate_agent(test.input_text)

        # 检查通过标准
        deviations = []
        for criterion in test.pass_criteria:
            if not self._check_criterion(actual, criterion):
                deviations.append(f"Failed: {criterion}")

        return TestResult(
            test_id=test.test_id,
            passed=len(deviations) == 0,
            actual_behavior=actual,
            deviations=deviations,
            timestamp=datetime.now().isoformat()
        )

    def run_suite(self) -> dict:
        """运行完整测试套件"""
        for test in self.tests:
            result = self.run_test(test)
            self.results.append(result)

        passed = sum(1 for r in self.results if r.passed)
        total = len(self.results)

        return {
            "total": total,
            "passed": passed,
            "failed": total - passed,
            "pass_rate": passed / total if total > 0 else 0,
            "results": self.results
        }

    def generate_report(self, suite_result: dict) -> str:
        """生成测试报告"""
        lines = [
            "# Agent Regression Test Report",
            f"\nAgent: {self.agent_file}",
            f"Total Tests: {suite_result['total']}",
            f"Passed: {suite_result['passed']}",
            f"Failed: {suite_result['failed']}",
            f"Pass Rate: {suite_result['pass_rate']:.1%}",
            "\n## Failed Tests"
        ]

        for r in suite_result["results"]:
            if not r.passed:
                lines.append(f"\n### {r.test_id}")
                lines.append(f"Actual: {r.actual_behavior}")
                lines.append("Deviations:")
                for d in r.deviations:
                    lines.append(f"  - {d}")

        return "\n".join(lines)
```

## 3. 跨 Agent 边界测试

### 3.1 边界测试设计

**测试目标**：验证两个相邻 agent 的边界是否清晰、无重叠、无遗漏。

**测试类型**：

```markdown
1. **归属测试（Ownership Test）**：
   输入明确属于 agent A 的范围，验证不会被路由到 agent B

2. **排斥测试（Rejection Test）**：
   输入明确不属于 agent A 的范围，验证 agent A 会拒绝或路由到正确 agent

3. **移交测试（Handoff Test）**：
   agent A 完成工作后，验证是否正确推荐下一个 agent

4. **冲突测试（Conflict Test）**：
   输入同时涉及 agent A 和 B 的范围，验证是否有明确的优先级规则
```

### 3.2 边界测试用例模板

```markdown
## Cross-Agent Boundary Test

### Test Pair: [Agent A] vs [Agent B]

#### Test 1: 归属测试
**Input**: [明确属于 Agent A 的输入]
**Expected**:
- Agent A 接受并处理
- Agent B 不介入
**Verification**: [如何验证]

#### Test 2: 排斥测试
**Input**: [明确不属于 Agent A 的输入]
**Expected**:
- Agent A 拒绝或路由到 Agent B
- Agent B 接受并处理
**Verification**: [如何验证]

#### Test 3: 移交测试
**Input**: [Agent A 完成后的状态]
**Expected**:
- Agent A 的输出包含对 Agent B 的推荐
- Agent B 能从 Agent A 的输出中正确接续
**Verification**: [如何验证]

#### Test 4: 冲突测试（如适用）
**Input**: [同时涉及 A 和 B 的输入]
**Expected**:
- 有明确的优先级规则
- 或主进程能正确分解任务
**Verification**: [如何验证]
```

### 3.3 常见边界测试矩阵

```markdown
## 预设边界测试矩阵

### @backend vs @database
| 测试类型 | 输入 | Agent A 预期 | Agent B 预期 |
|----------|------|--------------|--------------|
| 归属测试 | "写用户查询接口" | backend 接受 | database 不介入 |
| 排斥测试 | "用户表加字段" | backend 拒绝 | database 接受 |
| 移交测试 | backend 完成接口实现 | 推荐 code-review | — |
| 冲突测试 | "接口慢，需要优化" | backend 检查应用层 | database 检查查询 |

### @dev-lead vs @architect
| 测试类型 | 输入 | Agent A 预期 | Agent B 预期 |
|----------|------|--------------|--------------|
| 归属测试 | "这个接口怎么设计" | dev-lead 接受 | architect 不介入 |
| 排斥测试 | "系统整体架构" | dev-lead 拒绝 | architect 接受 |
| 移交测试 | dev-lead 完成方案 | 推荐 backend | — |
| 冲突测试 | "模块边界划分" | dev-lead（技术方案） | architect（架构决策） |

### @code-review vs @security-auditor
| 测试类型 | 输入 | Agent A 预期 | Agent B 预期 |
|----------|------|--------------|--------------|
| 归属测试 | "审这个 PR" | code-review 接受 | security-auditor 不介入 |
| 排斥测试 | "整体安全评估" | code-review 拒绝 | security-auditor 接受 |
| 移交测试 | code-review 发现安全问题 | 推荐 security-auditor | — |
| 冲突测试 | "代码有 SQL 注入" | code-review 发现 | security-auditor 深度分析 |
```

## 4. 版本兼容性检查

### 4.1 版本管理规范

```markdown
## Agent File Versioning

### 版本号格式: MAJOR.MINOR.PATCH
- MAJOR: 结构性变更（section 增删、工作流变更）
- MINOR: 内容扩展（新增规则、扩展示例）
- PATCH: 修复（规则修正、示例更新）

### 版本记录位置
在 agent 文件的 frontmatter 中：
```yaml
---
version: "2.1.3"
last_updated: "2026-04-21"
changelog:
  - "2.1.3: 修复 SQL 注入检测规则"
  - "2.1.2: 添加 call-chain 追踪示例"
  - "2.1.0: 新增 Workflow C"
  - "2.0.0: 重构 section 结构"
---
```
```

### 4.2 兼容性检查清单

```markdown
## Version Compatibility Checklist

### 当更新 agent 文件时：

- [ ] **MAJOR 变更检查**：
  - [ ] 是否删除了 section？
  - [ ] 是否改变了工作流结构？
  - [ ] 是否修改了输出契约格式？
  - [ ] 如果是，所有引用此 agent 的文档是否需要更新？

- [ ] **MINOR 变更检查**：
  - [ ] 新增的规则是否与现有规则冲突？
  - [ ] 新增的示例是否符合格式规范？
  - [ ] 技能树扩展是否完整？

- [ ] **PATCH 变更检查**：
  - [ ] 修复是否引入了新的副作用？
  - [ ] 示例更新是否与规则一致？

- [ ] **跨文件兼容性**：
  - [ ] CLAUDE.md 中的调度信号是否需要同步？
  - [ ] dispatch-table.md 是否需要更新？
  - [ ] 相邻 agent 的边界是否需要调整？
  - [ ] output-style 是否需要更新？

- [ ] **回归测试**：
  - [ ] 变更前测试是否通过？
  - [ ] 变更后测试是否通过？
  - [ ] 是否有测试需要更新？
```

### 4.3 版本兼容性矩阵

```markdown
## Agent Version Compatibility Matrix

| Agent | Current Version | Compatible With | Breaking Changes |
|-------|----------------|-----------------|------------------|
| backend | 2.1.3 | code-review 1.5+, database 1.2+ | None |
| frontend | 1.8.2 | backend 2.0+, test-ui 1.0+ | None |
| code-review | 1.5.1 | backend 2.0+, frontend 1.5+ | Security baseline format |
| database | 1.2.0 | backend 2.0+, dev-lead 1.0+ | None |
| dev-lead | 1.3.0 | architect 2.0+, backend 2.0+ | Workflow B structure |
| architect | 2.0.0 | dev-lead 1.3+, pm 1.0+ | Major refactor |
```

### 4.4 版本升级流程

```markdown
## Agent Version Upgrade Workflow

### 触发条件
1. 累积了 ≥3 个 PATCH 变更 → 考虑 MINOR 升级
2. 结构性变更需求 → MAJOR 升级
3. 与其他 agent 的兼容性问题 → 相应升级

### 升级流程
1. **影响评估**：
   - 列出所有受影响的文件和 agent
   - 评估 breaking changes
   - 制定迁移计划

2. **版本更新**：
   - 更新 agent 文件的 version 字段
   - 更新 changelog
   - 更新兼容性矩阵

3. **依赖更新**：
   - 更新相邻 agent 的兼容性声明
   - 更新 CLAUDE.md
   - 更新 dispatch-table.md

4. **回归验证**：
   - 运行完整回归测试套件
   - 验证跨 agent 边界测试
   - 确认无兼容性问题

5. **文档更新**：
   - 更新版本历史
   - 更新迁移指南（如需要）
   - 通知相关方
```

## 5. 进化健康度评估

### 5.1 健康度指标

```python
class EvolutionHealthMetrics:
    """评估 agent 进化健康度"""

    def __init__(self, agent_name: str):
        self.agent = agent_name
        self.observations = []
        self.changes = []

    def calculate_health_score(self) -> dict:
        """计算综合健康度评分"""
        metrics = {
            "stability": self._stability_score(),
            "responsiveness": self._responsiveness_score(),
            "accuracy": self._accuracy_score(),
            "coverage": self._coverage_score()
        }

        # 综合评分 (0-100)
        total = sum(metrics.values())
        metrics["overall"] = total / 4

        return metrics

    def _stability_score(self) -> float:
        """稳定性：漂移复发率低 = 高稳定性"""
        recurrence_rate = self.calculate_drift_recurrence_rate()
        return (1 - recurrence_rate) * 100

    def _responsiveness_score(self) -> float:
        """响应性：修复时间短 = 高响应性"""
        mttr = self.calculate_mttr()
        # MTTR < 1天 = 100分, > 7天 = 0分
        return max(0, 100 - (mttr / 86400) * (100/7))

    def _accuracy_score(self) -> float:
        """准确性：误分类率低 = 高准确性"""
        false_rate = self.calculate_false_classification_rate()
        return (1 - false_rate) * 100

    def _coverage_score(self) -> float:
        """覆盖率：规则覆盖场景的比例"""
        # 基于边界测试通过率
        boundary_tests = self.run_boundary_tests()
        pass_rate = boundary_tests["pass_rate"]
        return pass_rate * 100
```

### 5.2 健康度报告模板

```markdown
## Agent Evolution Health Report

### Agent: [agent-name]
### Period: [start] - [end]

#### 关键指标
| 指标 | 值 | 目标 | 状态 |
|------|-----|------|------|
| 稳定性 | [N]% | ≥90% | [✓/✗] |
| 响应性 | [N]分 | ≥80分 | [✓/✗] |
| 准确性 | [N]% | ≥85% | [✓/✗] |
| 覆盖率 | [N]% | ≥80% | [✓/✗] |
| **综合健康度** | **[N]分** | **≥80分** | **[✓/✗]** |

#### 观察统计
- 总观察数: [N]
- 已解决: [N] ([N]%)
- 复发: [N] ([N]%)
- 误分类: [N] ([N]%)

#### 改进趋势
- 本月修复: [N]
- 平均修复时间: [N] 小时
- 新引入规则: [N]
- 规则失效: [N]

#### 建议
- [基于数据的改进建议]
```
