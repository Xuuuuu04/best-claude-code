---
title: "Prompt Engineer — Domain 1: Drift Diagnosis Methodology"
source: core.md §Domain 3
cross-ref: domain-drift.md (深度扩展版)
---

# Domain 1: Drift Diagnosis Methodology

## 1.1 Drift Taxonomy

### Class 1: Specification Defect

**Definition**: The prompt does not contain any rule, instruction, or example that covers the input that produced drift. The agent had no guidance for the situation.

**Detection**:
```python
def detect_spec_defect(agent_prompt: str, input_text: str, expected_output: str, actual_output: str) -> bool:
    """
    Check if any section of the prompt governs the input that produced drift.
    """
    # Search for keywords from input in prompt sections
    input_keywords = extract_keywords(input_text)
    prompt_sections = parse_sections(agent_prompt)

    governing_sections = []
    for section in prompt_sections:
        if any(kw in section.content for kw in input_keywords):
            governing_sections.append(section)

    if not governing_sections:
        return True  # No section governs this input = Specification Defect

    # Check if governing section actually covers the behavior
    for section in governing_sections:
        if expected_behavior_in_section(expected_output, section):
            return False  # Section exists and covers expected behavior

    return True  # Section mentions topic but doesn't cover expected behavior
```

**Fix**: Add missing specification to the appropriate section. Be specific — "handle errors" is not a specification; "when file not found, return 404 with JSON body {error: 'File not found'}" is.

### Class 2: Instruction Conflict

**Definition**: Two or more rules in the prompt are mutually contradictory for a specific input class. The agent cannot satisfy all applicable rules simultaneously.

**Detection**:
```python
def detect_instruction_conflict(agent_prompt: str, input_text: str) -> Optional[Tuple[str, str]]:
    """
    Find two rules that cannot be simultaneously satisfied for the input.
    """
    applicable_rules = find_applicable_rules(agent_prompt, input_text)

    for i, rule1 in enumerate(applicable_rules):
        for rule2 in applicable_rules[i+1:]:
            if are_mutually_exclusive(rule1, rule2, input_text):
                return (rule1, rule2)

    return None
```

**Example Conflict**:
- Rule A: "NEVER modify files not in the scheme document"
- Rule B: "ALWAYS fix security vulnerabilities immediately"
- Input: Security vulnerability found in file not in scheme
- Conflict: Cannot both "not modify" and "fix immediately"

**Fix**: Add explicit precedence rule: "Security vulnerabilities override the no-out-of-scope modification rule. If a security vulnerability is found, flag it as CRITICAL and route to @security-auditor."

### Class 3: LLM Capability Boundary

**Definition**: The drift recurs across multiple prompt variations. Adding more precision to the prompt improves performance but does not eliminate the drift. The task exceeds what the LLM can reliably do in a single call.

**Detection**:
```python
def detect_capability_boundary(
    agent_prompt: str,
    input_text: str,
    max_variations: int = 3
) -> bool:
    """
    Test if drift persists across multiple prompt variations.
    """
    drift_count = 0
    for variation in generate_prompt_variations(agent_prompt, n=max_variations):
        output = llm_generate(variation, input_text)
        if is_drift(output, expected_output):
            drift_count += 1

    # If drift persists across >50% of variations, likely capability boundary
    return drift_count / max_variations > 0.5
```

**Fix**: Decompose into simpler subtasks. Do not add more rules — the LLM cannot reliably follow them.

BAD (keeps adding rules):
```
Rule 1: Check for SQL injection
Rule 2: Check for XSS
Rule 3: Check for CSRF
Rule 4: Check for path traversal
Rule 5: Check for insecure deserialization
... (20 more rules)
```

GOOD (decomposes):
```
Step 1: Run security scanner tool (automated)
Step 2: Review scanner output for false positives
Step 3: For each confirmed finding, apply remediation template
```

## 1.2 Drift Diagnosis Template

```
## Drift Diagnosis Report

**Agent**: [name]
**Drift Type**: [Specification Defect / Instruction Conflict / LLM Capability Boundary]

**Evidence Triad**:
- Input: [exact or representative input]
- Expected: [what spec says should happen, cite section]
- Actual: [what agent produced, verbatim or summarized]

**Root Cause Analysis**:
- Failed section: [which prompt section should have governed]
- Why it failed: [specific explanation]
- Drift taxonomy classification: [Class 1/2/3 with justification]

**Remediation Candidates**:
- Candidate A: [description, scope, risk, regression test]
- Candidate B: [description, scope, risk, regression test]
- Candidate C: [description, scope, risk, regression test]

**Recommendation**: [Candidate X — rationale]
```

## 1.3 Bar Uniformity Enforcement Checklist

### Section Count Check
```python
def check_section_count(agent_prompt: str) -> int:
    """Count sections in agent prompt. Target: >= 13."""
    sections = re.findall(r'<section id="[^"]+">', agent_prompt)
    return len(sections)
```

### Line Count Check
```python
def check_line_count(agent_prompt: str) -> int:
    """Count lines in agent prompt. Target: 400-600."""
    return len(agent_prompt.split('\n'))
```

### Coined Terms Check
```python
def check_coined_terms(agent_prompt: str) -> List[str]:
    """Find coined mental-model terms. Target: 3-5."""
    # Look for terms in **bold** or "Title Case" that appear to be coined
    bold_terms = re.findall(r'\*\*([^*]+)\*\*', agent_prompt)
    title_terms = re.findall(r'"([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)"', agent_prompt)
    return bold_terms + title_terms
```

### Paired Examples Check
```python
def check_paired_examples(agent_prompt: str) -> bool:
    """Verify BAD→GOOD paired examples exist in methodology."""
    has_bad = 'BAD:' in agent_prompt or 'bad' in agent_prompt.lower()
    has_good = 'GOOD:' in agent_prompt or 'good' in agent_prompt.lower()
    return has_bad and has_good
```

### Output Contract Check
```python
def check_output_contract(agent_prompt: str) -> bool:
    """Verify output contract has filled example."""
    return 'Filled Example' in agent_prompt or 'Example' in agent_prompt
```

## 1.4 Agent Proliferation Cost Analysis

```python
class ProliferationCostCalculator:
    """Quantify the cost of adding a new agent."""

    def __init__(self, existing_agents: List[str]):
        self.existing_agents = existing_agents
        self.n = len(existing_agents)

    def calculate(self, new_agent_scope: str) -> Dict[str, any]:
        """
        Calculate proliferation cost.

        Returns:
            boundary_ambiguities: Number of new boundary clarification problems
            routing_complexity: Additional dispatch table rows
            maintenance_overhead: Estimated additional maintenance burden
            compound_failure_modes: Number of new 2-agent failure combinations
        """
        return {
            "boundary_ambiguities": self.n,  # One with each existing agent
            "routing_complexity": 1,  # New row in dispatch table
            "maintenance_overhead": f"{self.n + 1} files to sync on spec changes",
            "compound_failure_modes": self.n * (self.n - 1) // 2,
            "total_cost_score": self.n * 2 + 1
        }

    def is_justified(self, specialization_value: int, cost_score: int) -> bool:
        """Determine if specialization value exceeds proliferation cost."""
        return specialization_value > cost_score
```

## 1.5 Dispatch Signal Audit Template

```python
class DispatchSignalAuditor:
    """Audit dispatch signals for semantic purity and conflicts."""

    def __init__(self, agent_files: List[str]):
        self.agents = self._load_agents(agent_files)

    def audit(self) -> List[Dict]:
        """Find dispatch signal conflicts."""
        conflicts = []
        signals = defaultdict(list)

        for agent in self.agents:
            for signal in agent.strong_triggers:
                signals[signal].append(agent.name)

        for signal, agents in signals.items():
            if len(agents) > 1:
                conflicts.append({
                    "signal": signal,
                    "agents": agents,
                    "severity": "CRITICAL" if len(agents) > 2 else "WARNING",
                    "recommendation": f"Disambiguate: add qualifier or assign to one agent with weak trigger on others"
                })

        return conflicts

    def check_coverage(self, task_categories: List[str]) -> List[str]:
        """Find task categories with no owning agent."""
        covered = set()
        for agent in self.agents:
            covered.update(agent.scope_keywords)

        gaps = [cat for cat in task_categories if cat not in covered]
        return gaps
```

---

> **Note**: 本文件为 Domain 1 的概要版本。完整的漂移诊断深度协议、证据收集模板、根因分类流程图参见 `domain-drift.md`。
> Bar 一致性检查的完整检查清单、审计脚本、自检模板参见 `domain-bar.md`。
> 调度信号审计的完整分类、重叠检测、边界测试方法参见 `domain-signal.md`。
> Agent 进化方法论的完整循环、回归测试、版本兼容性检查参见 `domain-evolution.md`。
