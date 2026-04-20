---
title: "Prompt Engineer — Domain: Bar Uniformity Enforcement Depth"
description: "Bar一致性检查深度协议：section计数、行数审计、术语发明检查、配对示例验证、output contract完整性检查、自检模板"
source: core.md §Bar Uniformity Enforcement 深度扩展
---

# Domain: Bar Uniformity Enforcement Depth

## 1. Bar 标准完整定义

**Anthropic Bar** 是 prompt-engineer 对所有 agent 文件（包括自身）执行的结构性质量标准：

| 维度 | 最低要求 | 理想范围 | 检查工具 |
|---|---|---|---|
| Section 数量 | ≥13 | 13-18 | `grep -c '<section id='` |
| 行数 | 400-600 | 450-550 | `wc -l` |
| 自创术语 | 3-5 个 | 4 个 | 人工识别 + 正则匹配 |
| 配对示例 | 必须存在 | ≥3 对 | `grep -c 'BAD:'` + `grep -c 'GOOD:'` |
| Output Contract | 必须填充 | 含完整示例 | 人工检查 |
| 身份声明 | 必须存在 | 200-400 字 | 人工检查 |
| 工作流 | 必须存在 | A/B/C 三类 | 人工检查 |
| 调度信号 | 强信号 ≥5 个 | 8-12 个 | `grep -c 'Strong triggers'` |

## 2. Section 计数检查

### 2.1 检查方法

```bash
# 方法 1: 直接计数
$ grep -c '<section id=' agent-file.md

# 方法 2: 列出所有 section
$ grep -o '<section id="[^"]*"' agent-file.md | sed 's/<section id="//;s/"$//'

# 方法 3: 检查 section 结构完整性
$ grep -A 1 '<section id=' agent-file.md | grep -c '</section>'
# section 开启标签数应等于闭合标签数
```

### 2.2 必需 Section 清单

每个 agent 文件必须包含以下 13 个核心 section：

```markdown
1. <section id="rules"> — 铁律（Primacy Anchor）
2. <section id="identity"> — 身份声明
3. <section id="workflow"> — 工作流（A/B/C）
4. <section id="tooling"> 或 <section id="tooling-etiquette"> — 工具使用规范
5. <section id="in-scope"> — 职责范围
6. <section id="out-of-scope"> — 职责外范围（含路由表）
7. <section id="skill-tree"> — 技能树
8. <section id="methodology"> — 方法论
9. <section id="anti-patterns"> — 反模式
10. <section id="collaboration"> — 协作协议
11. <section id="output-contract"> — 输出契约
12. <section id="dispatch-signals"> — 调度信号
13. <section id="final-reminder"> — 最终提醒（Recency Anchor）
```

**可选 Section**（不计入 13 个核心，但推荐）：

```markdown
14. <section id="self-check"> — 自检清单
15. <section id="version-history"> — 版本历史
16. <section id="runtime-index"> — runtime-pack 索引
```

### 2.3 Section 结构审计脚本

```python
#!/usr/bin/env python3
"""Agent File Section Auditor"""

import re
import sys
from pathlib import Path

REQUIRED_SECTIONS = [
    "rules", "identity", "workflow", "tooling", "in-scope",
    "out-of-scope", "skill-tree", "methodology", "anti-patterns",
    "collaboration", "output-contract", "dispatch-signals", "final-reminder"
]

def audit_sections(file_path: str) -> dict:
    content = Path(file_path).read_text()

    # 提取所有 section
    section_pattern = r'<section\s+id="([^"]+)"'
    found_sections = re.findall(section_pattern, content)

    result = {
        "file": file_path,
        "total_sections": len(found_sections),
        "required_found": [],
        "required_missing": [],
        "optional_found": [],
        "pass": False
    }

    for req in REQUIRED_SECTIONS:
        if req in found_sections:
            result["required_found"].append(req)
        else:
            result["required_missing"].append(req)

    optional = [s for s in found_sections if s not in REQUIRED_SECTIONS]
    result["optional_found"] = optional

    result["pass"] = len(result["required_missing"]) == 0 and result["total_sections"] >= 13

    return result

def print_report(result: dict):
    print(f"=== Section Audit Report: {result['file']} ===")
    print(f"Total sections: {result['total_sections']} (required: ≥13)")
    print(f"Required sections found ({len(result['required_found'])}/13):")
    for s in result["required_found"]:
        print(f"  ✓ {s}")
    if result["required_missing"]:
        print(f"Required sections MISSING ({len(result['required_missing'])}):")
        for s in result["required_missing"]:
            print(f"  ✗ {s}")
    if result["optional_found"]:
        print(f"Optional sections found: {', '.join(result['optional_found'])}")
    print(f"Status: {'PASS' if result['pass'] else 'FAIL'}")

if __name__ == "__main__":
    for f in sys.argv[1:]:
        result = audit_sections(f)
        print_report(result)
        print()
```

## 3. 行数审计

### 3.1 行数计算方法

```bash
# 总行数（含空行和注释）
$ wc -l < agent-file.md

# 非空行数
$ grep -c '[^[:space:]]' agent-file.md

# 内容行数（去除纯注释和空行）
$ grep -v '^\s*$' agent-file.md | grep -v '^\s*#' | wc -l

# Bar 标准使用总行数（wc -l）
```

### 3.2 行数分布指南

理想行数分布（500 行目标）：

```markdown
Section              目标行数    说明
─────────────────────────────────────────
rules                40-60      铁律，简洁有力
identity             60-80      身份声明，含核心身份句
workflow             80-100     工作流 A/B/C
tooling              30-40      工具使用规范
in-scope             40-50      职责范围
out-of-scope         30-40      职责外范围 + 路由表
skill-tree           60-80      技能树（层级结构）
methodology          60-80      方法论 + BAD→GOOD 示例
anti-patterns        40-60      反模式（命名 + 描述 + 修复）
collaboration        20-30      协作协议
output-contract      40-60      输出契约 + 填充示例
dispatch-signals     30-40      调度信号（强/弱）
final-reminder       30-40      最终提醒（Recency Anchor）
─────────────────────────────────────────
Total                500-680    目标 400-600，允许浮动
```

### 3.3 行数异常检测

```python
def audit_line_count(file_path: str) -> dict:
    content = Path(file_path).read_text()
    lines = content.split('\n')
    total = len(lines)

    # 分析行数分布
    sections = parse_sections(content)
    section_lines = {}
    for sec in sections:
        section_lines[sec.id] = sec.line_count

    result = {
        "total_lines": total,
        "status": "PASS" if 400 <= total <= 600 else "WARNING" if 300 <= total <= 700 else "FAIL",
        "section_distribution": section_lines,
        "recommendations": []
    }

    if total < 400:
        result["recommendations"].append(
            f"文件过短（{total} 行）。建议扩展 identity、methodology 或 skill-tree section。"
        )
    elif total > 600:
        result["recommendations"].append(
            f"文件过长（{total} 行）。建议将内容迁移到 runtime-pack domain 文件，"
            "或精简 methodology 中的示例。"
        )

    # 检查 section 行数异常
    for sec_id, count in section_lines.items():
        if count < 10:
            result["recommendations"].append(
                f"Section '{sec_id}' 仅 {count} 行，可能内容不足。"
            )
        elif count > 100:
            result["recommendations"].append(
                f"Section '{sec_id}' 达 {count} 行，建议拆分到 domain 文件。"
            )

    return result
```

## 4. 术语发明检查

### 4.1 术语识别标准

**自创术语（Coined Terms）** 必须满足：

1. **命名独特性**：不是通用技术词汇（如 "API"、"database" 不算）
2. **概念封装性**：用一个词封装一个复杂概念或方法论
3. **重复使用性**：在 prompt 中多次引用，形成统一概念
4. **首字母大写或加粗**：视觉区分于普通词汇

### 4.2 术语识别正则

```python
def extract_coined_terms(text: str) -> list:
    """提取自创术语"""
    terms = []

    # 模式 1: **Title Case Terms**
    pattern1 = r'\*\*([A-Z][a-zA-Z]*(?:\s+[A-Z][a-zA-Z]*)+)\*\*'
    terms.extend(re.findall(pattern1, text))

    # 模式 2: "Title Case Terms" in quotes
    pattern2 = r'"([A-Z][a-zA-Z]*(?:\s+[A-Z][a-zA-Z]*)+)"'
    terms.extend(re.findall(pattern2, text))

    # 模式 3: 中文术语加粗
    pattern3 = r'\*\*([^*]{2,10}[^\x00-\x7F][^*]*)\*\*'
    terms.extend(re.findall(pattern3, text))

    # 过滤通用词汇
    generic = {"API", "HTTP", "SQL", "JSON", "URL", "REST", "JWT",
               "OAuth", "CI/CD", "UI", "UX", "CSS", "HTML"}
    return [t for t in terms if t not in generic]
```

### 4.3 术语质量评估

```markdown
## 术语质量检查清单

### 每个术语必须通过以下检查：

- [ ] **定义明确**：术语首次出现时是否有定义或解释？
- [ ] **概念独立**：术语是否封装了一个独立的概念（而非同义词替换）？
- [ ] **重复使用**：术语在 prompt 中是否出现 ≥3 次？
- [ ] **行为关联**：术语是否与具体行为规则相关联？
- [ ] **可测试性**：术语描述的概念是否可以被验证？

### BAD → GOOD 对比

# BAD — 弱术语（伪自创）
"**Good Code**" — 只是 "好代码" 的英文翻译，无新概念封装
"**Best Practice**" — 通用词汇，无特定含义

# GOOD — 强术语（有效自创）
"**Specification Quality Audit**" — 封装了四维度评估方法论
"**Drift Taxonomy**" — 封装了三类根因分类体系
"**Agent Proliferation Cost**" — 封装了新增 agent 的量化成本模型
"**Ghost Failure**" — 封装了静默异常处理的特定反模式
"**Skeleton Commit**" — 封装了空函数体提交的特定反模式
```

### 4.4 术语数量检查

```python
def audit_coined_terms(file_path: str) -> dict:
    content = Path(file_path).read_text()
    terms = extract_coined_terms(content)

    # 去重
    unique_terms = list(set(terms))

    result = {
        "total_mentions": len(terms),
        "unique_terms": unique_terms,
        "unique_count": len(unique_terms),
        "status": "PASS" if 3 <= len(unique_terms) <= 5 else "WARNING",
        "recommendations": []
    }

    if len(unique_terms) < 3:
        result["recommendations"].append(
            f"术语数量不足（{len(unique_terms)} 个）。建议增加 3-5 个自创术语。"
        )
    elif len(unique_terms) > 5:
        result["recommendations"].append(
            f"术语数量过多（{len(unique_terms)} 个）。建议精简到 3-5 个核心术语。"
        )

    return result
```

## 5. 配对示例验证

### 5.1 配对示例结构标准

每个配对示例必须包含：

```markdown
1. **反模式名称** — 命名并定义问题
2. **BAD 示例** — 具体代码/配置/文本展示错误做法
3. **问题解释** — 为什么这是错误的（后果分析）
4. **GOOD 示例** — 具体代码/配置/文本展示正确做法
5. **修复说明** — 为什么 GOOD 解决了问题
```

### 5.2 配对示例验证脚本

```python
def audit_paired_examples(file_path: str) -> dict:
    content = Path(file_path).read_text()

    # 查找 BAD/GOOD 标记
    bad_count = len(re.findall(r'\bBAD\b[:：]', content))
    good_count = len(re.findall(r'\bGOOD\b[:：]', content))

    # 查找配对模式
    pair_pattern = r'BAD.*?GOOD'
    pairs = re.findall(pair_pattern, content, re.DOTALL)

    result = {
        "bad_markers": bad_count,
        "good_markers": good_count,
        "paired_count": len(pairs),
        "status": "PASS" if len(pairs) >= 3 else "WARNING" if len(pairs) >= 1 else "FAIL",
        "recommendations": []
    }

    if len(pairs) < 3:
        result["recommendations"].append(
            f"配对示例不足（{len(pairs)} 对）。建议至少 3 对 BAD→GOOD 示例。"
        )

    if bad_count != good_count:
        result["recommendations"].append(
            f"BAD ({bad_count}) 与 GOOD ({good_count}) 数量不匹配。"
        )

    return result
```

### 5.3 配对示例质量检查

```markdown
## 配对示例质量检查清单

### 每个配对示例必须通过：

- [ ] **具体性**：BAD 和 GOOD 都是具体代码/文本，不是抽象描述
- [ ] **对比性**：GOOD 直接解决 BAD 中的问题，不是无关的好做法
- [ ] **上下文**：示例有明确的场景说明（"在 X 情况下..."）
- [ ] **后果说明**：解释了 BAD 为什么会导致问题
- [ ] **可执行性**：GOOD 示例可以直接执行或应用

### BAD → GOOD 对比（示例本身的质量）

# BAD — 低质量配对示例
BAD: "不要写太长的函数"
GOOD: "函数应该短一些"
# 问题：抽象描述，无具体代码，无对比性

# GOOD — 高质量配对示例
BAD:
```python
def process():
    # 200 行代码，做 10 件事
    ...
```
问题：单一函数承担过多职责，难以测试和维护。修改一个功能可能影响其他功能。

GOOD:
```python
def validate_input(data): ...
def transform_data(data): ...
def save_to_db(data): ...
def send_notification(data): ...

def process():
    data = validate_input(raw_data)
    transformed = transform_data(data)
    save_to_db(transformed)
    send_notification(transformed)
```
修复：每个函数单一职责，可独立测试，变更隔离。
```

## 6. Output Contract 完整性检查

### 6.1 Output Contract 必需元素

```markdown
## Output Contract 完整性检查清单

### 结构检查
- [ ] 有明确的输出标题（如 "## Backend Implementation Output"）
- [ ] 有状态字段（READY-FOR-NEXT / BLOCKED / FAILED 等）
- [ ] 有变更文件列表
- [ ] 有自检结果
- [ ] 有推荐的下一步

### 填充示例检查
- [ ] 有至少一个完整的填充示例
- [ ] 示例包含真实数据（不是占位符）
- [ ] 示例展示了成功场景
- [ ] 示例展示了失败/BLOCKED 场景（如适用）

### 可路由性检查
- [ ] 主进程能从输出中提取状态
- [ ] 主进程能从输出中提取下一步推荐
- [ ] 输出格式一致（相同任务类型使用相同结构）
```

### 6.2 Output Contract 验证脚本

```python
def audit_output_contract(file_path: str) -> dict:
    content = Path(file_path).read_text()

    result = {
        "has_contract_section": False,
        "has_template": False,
        "has_filled_example": False,
        "has_status_field": False,
        "has_next_step": False,
        "status": "FAIL",
        "recommendations": []
    }

    # 检查 output-contract section
    result["has_contract_section"] = '<section id="output-contract">' in content or \
                                      '## Output Contract' in content

    # 检查模板结构
    result["has_template"] = '**Status**' in content and '**Task**' in content

    # 检查填充示例
    result["has_filled_example"] = 'Filled Example' in content or \
                                    '**Example**' in content

    # 检查状态字段
    result["has_status_field"] = any(s in content for s in
        ['READY-FOR-NEXT', 'BLOCKED', 'FAILED', 'CHANGES-REQUESTED'])

    # 检查下一步
    result["has_next_step"] = 'Recommended Next Step' in content or \
                               'Next step' in content

    # 综合判定
    checks = [
        result["has_contract_section"],
        result["has_template"],
        result["has_filled_example"],
        result["has_status_field"],
        result["has_next_step"]
    ]
    pass_count = sum(checks)

    if pass_count == 5:
        result["status"] = "PASS"
    elif pass_count >= 3:
        result["status"] = "WARNING"

    if not result["has_filled_example"]:
        result["recommendations"].append(
            "缺少填充示例。添加一个完整的输入→输出示例。"
        )

    return result
```

## 7. 完整自检模板

### 7.1 Bar 自检清单（Agent 文件审查用）

```markdown
# Bar Uniformity Self-Check

## 文件信息
- **Agent 名称**：
- **文件路径**：
- **审查日期**：
- **审查人**：

## Section 检查
- [ ] Section 数量 ≥13（当前：___）
- [ ] 包含 rules section
- [ ] 包含 identity section
- [ ] 包含 workflow section
- [ ] 包含 tooling section
- [ ] 包含 in-scope section
- [ ] 包含 out-of-scope section（含路由表）
- [ ] 包含 skill-tree section
- [ ] 包含 methodology section
- [ ] 包含 anti-patterns section
- [ ] 包含 collaboration section
- [ ] 包含 output-contract section
- [ ] 包含 dispatch-signals section
- [ ] 包含 final-reminder section

## 行数检查
- [ ] 总行数 400-600（当前：___）
- [ ] 无 section 行数 <10
- [ ] 无 section 行数 >100（除非有充分理由）

## 术语检查
- [ ] 自创术语 3-5 个（当前：___）
- [ ] 每个术语有明确定义
- [ ] 每个术语出现 ≥3 次
- [ ] 术语列表：
  1. ___
  2. ___
  3. ___
  4. ___
  5. ___

## 配对示例检查
- [ ] BAD→GOOD 配对 ≥3 对（当前：___）
- [ ] 每个配对有具体代码/文本
- [ ] 每个配对有问题解释
- [ ] 每个配对有修复说明

## Output Contract 检查
- [ ] 有输出模板
- [ ] 有填充示例
- [ ] 有状态字段
- [ ] 有下一步推荐
- [ ] 示例包含成功场景
- [ ] 示例包含失败/BLOCKED 场景（如适用）

## 调度信号检查
- [ ] 强信号 ≥5 个
- [ ] 弱信号有明确区分
- [ ] 有 "Do NOT dispatch" 说明

## 综合判定
- [ ] 全部通过 → PASS
- [ ] 1-2 项警告 → WARNING（列出）
- [ ] ≥3 项失败 → FAIL（必须修复）

## 审查备注
___
```

### 7.2 批量审查脚本

```python
#!/usr/bin/env python3
"""Batch Agent File Bar Auditor"""

import glob
import sys
from pathlib import Path

def audit_agent_file(file_path: str) -> dict:
    """对单个 agent 文件执行完整 Bar 审查"""
    content = Path(file_path).read_text()

    result = {
        "file": file_path,
        "section_count": len(re.findall(r'<section\s+id=', content)),
        "line_count": len(content.split('\n')),
        "coined_terms": len(set(extract_coined_terms(content))),
        "paired_examples": len(re.findall(r'BAD.*?GOOD', content, re.DOTALL)),
        "has_output_contract": '## Output Contract' in content,
        "has_filled_example": 'Filled Example' in content,
        "has_dispatch_signals": 'Strong triggers' in content,
        "score": 0,
        "status": "",
        "issues": []
    }

    # 计分
    score = 0
    if result["section_count"] >= 13: score += 2
    elif result["section_count"] >= 10: score += 1
    else: result["issues"].append(f"Section 不足: {result['section_count']}")

    if 400 <= result["line_count"] <= 600: score += 2
    elif 300 <= result["line_count"] <= 700: score += 1
    else: result["issues"].append(f"行数异常: {result['line_count']}")

    if 3 <= result["coined_terms"] <= 5: score += 2
    elif result["coined_terms"] >= 1: score += 1
    else: result["issues"].append(f"术语不足: {result['coined_terms']}")

    if result["paired_examples"] >= 3: score += 2
    elif result["paired_examples"] >= 1: score += 1
    else: result["issues"].append(f"配对示例不足: {result['paired_examples']}")

    if result["has_output_contract"]: score += 1
    else: result["issues"].append("缺少 Output Contract")

    if result["has_filled_example"]: score += 1
    else: result["issues"].append("缺少填充示例")

    result["score"] = score

    if score >= 9: result["status"] = "EXCELLENT"
    elif score >= 7: result["status"] = "PASS"
    elif score >= 5: result["status"] = "WARNING"
    else: result["status"] = "FAIL"

    return result

def main():
    files = glob.glob("~/.claude/agents/*.md")
    results = [audit_agent_file(f) for f in files]

    print("=" * 80)
    print("Batch Agent Bar Audit Report")
    print("=" * 80)

    for r in results:
        print(f"\n{r['file']}")
        print(f"  Score: {r['score']}/10 | Status: {r['status']}")
        print(f"  Sections: {r['section_count']} | Lines: {r['line_count']}")
        print(f"  Terms: {r['coined_terms']} | Pairs: {r['paired_examples']}")
        if r["issues"]:
            print(f"  Issues: {', '.join(r['issues'])}")

    # 汇总
    statuses = {"EXCELLENT": 0, "PASS": 0, "WARNING": 0, "FAIL": 0}
    for r in results:
        statuses[r["status"]] += 1

    print("\n" + "=" * 80)
    print("Summary:")
    for status, count in statuses.items():
        print(f"  {status}: {count}")

if __name__ == "__main__":
    main()
```

## 8. Bar 审查决策矩阵

| 检查项 | 通过标准 | 警告标准 | 失败标准 | 权重 |
|---|---|---|---|---|
| Section 数量 | ≥13 | 10-12 | <10 | 2 |
| 行数 | 400-600 | 300-700 | <300 或 >700 | 2 |
| 自创术语 | 3-5 个 | 1-2 个 | 0 个 | 2 |
| 配对示例 | ≥3 对 | 1-2 对 | 0 对 | 2 |
| Output Contract | 完整 | 有模板无示例 | 缺失 | 1 |
| 填充示例 | 存在 | — | 缺失 | 1 |

**评分标准**：
- 9-10 分：EXCELLENT — 可作为团队标杆
- 7-8 分：PASS — 符合标准，可接受
- 5-6 分：WARNING — 需要改进，但不阻塞
- 0-4 分：FAIL — 必须修复后才能提交
