---
title: "AI Navigator — Domain: Prompt Paradigm Evolution"
source: core.md §Domain 3
---

# Domain: Prompt Paradigm Evolution

## 1. The Complete Spectrum

```
Zero-shot → Few-shot → CoT → Self-Consistency → ToT → ReAct → Reflexion → Agent
  (1949)    (2020)   (2022)    (2022)       (2023)  (2023)   (2023)    (2023+)
```

Each paradigm builds upon the previous, adding complexity and capability. The right choice depends on task difficulty, latency requirements, and cost constraints.

---

## 2. Zero-Shot Prompting

**Definition:** Direct instruction without examples. The model relies entirely on its pre-trained knowledge.

**When to use:** Simple, well-defined tasks where the model's base knowledge is sufficient.

**Code template:**
```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(model="gpt-4o")

# Zero-shot prompt
response = llm.invoke("""
Translate the following English text to French:
"Hello, how are you today?"
""")
```

**Best practices [已验证, 2026-04]:**
- Be specific and explicit in instructions
- Use delimiters (```, """, <tag>) to separate input from instruction
- Specify output format when needed
- Avoid ambiguity — the model has no examples to disambiguate

**Limitations:**
- Struggles with complex reasoning tasks
- No way to teach task-specific patterns
- Relies heavily on model's base capabilities

---

## 3. Few-Shot Prompting

**Definition:** Provide a small number of examples (typically 1-5) to teach the model the desired pattern.

**When to use:** Pattern-matching tasks, format conversion, style imitation, classification.

**Code template:**
```python
few_shot_prompt = """
Classify the sentiment of the following reviews:

Review: "This product is amazing! Best purchase ever."
Sentiment: Positive

Review: "Terrible quality, broke after one day."
Sentiment: Negative

Review: "It's okay, nothing special but works fine."
Sentiment: Neutral

Review: "{input_review}"
Sentiment:"""

response = llm.invoke(few_shot_prompt.format(input_review=user_review))
```

**Best practices [已验证, 2026-04]:**
- Use diverse examples covering edge cases
- Order matters: place most relevant examples last
- Keep examples concise — tokens are expensive
- Use consistent format across all examples
- For classification, include all classes in examples

**Limitations:**
- Performance plateaus after ~5-6 examples (context window constraints)
- Sensitive to example selection (coverage bias)
- Does not improve reasoning, only pattern matching

---

## 4. Chain-of-Thought (CoT)

**Definition:** Prompt the model to generate intermediate reasoning steps before the final answer.

**When to use:** Multi-step reasoning tasks (math, logic, complex Q&A).

### 4.1 Zero-Shot CoT

```python
zero_shot_cot = """
Q: A train travels 120 km in 2 hours. How far will it travel in 5 hours at the same speed?
A: Let's think step by step.
"""

response = llm.invoke(zero_shot_cot)
# Model generates: First, find the speed: 120/2 = 60 km/h. Then, distance = 60 * 5 = 300 km.
```

### 4.2 Few-Shot CoT

```python
few_shot_cot = """
Q: Roger has 5 tennis balls. He buys 2 more cans of tennis balls. Each can has 3 balls. How many does he have now?
A: Roger started with 5 balls. 2 cans of 3 balls each is 6 balls. 5 + 6 = 11. The answer is 11.

Q: The cafeteria had 23 apples. If they used 20 to make lunch and bought 6 more, how many do they have?
A: The cafeteria started with 23 apples. They used 20, leaving 3. They bought 6 more, so 3 + 6 = 9. The answer is 9.

Q: {question}
A:"""

response = llm.invoke(few_shot_cot.format(question=user_question))
```

### 4.3 Self-Consistency

**Definition:** Generate multiple CoT reasoning paths and vote on the most common answer.

```python
import collections

def self_consistency_solve(question, n_samples=5):
    """Generate n CoT solutions and return the most common answer."""
    answers = []
    
    for _ in range(n_samples):
        # Use temperature > 0 for diverse reasoning paths
        response = llm.invoke(
            cot_prompt.format(question=question),
            temperature=0.7
        )
        answer = extract_final_answer(response)
        answers.append(answer)
    
    # Vote
    counter = collections.Counter(answers)
    return counter.most_common(1)[0][0]
```

**Best practices [已验证, 2026-04]:**
- Use "Let's think step by step" for zero-shot CoT
- Provide explicit reasoning format in few-shot examples
- Self-consistency: use temperature 0.5-0.7 for diversity
- Extract final answer programmatically for voting

**Cost tradeoff:** CoT increases token usage (2-5x) but improves accuracy significantly on reasoning tasks.

---

## 5. Tree of Thoughts (ToT)

**Definition:** Maintain multiple reasoning paths as a tree, evaluate each path, and explore promising branches.

**When to use:** Complex problems requiring exploration (puzzles, planning, creative writing).

**Code template:**
```python
from typing import List, Optional
import math

class ThoughtNode:
    def __init__(self, thought: str, parent: Optional['ThoughtNode'] = None):
        self.thought = thought
        self.parent = parent
        self.children: List['ThoughtNode'] = []
        self.value: Optional[float] = None
    
    def get_path(self) -> List[str]:
        """Get full reasoning path from root."""
        path = []
        node = self
        while node:
            path.append(node.thought)
            node = node.parent
        return list(reversed(path))

def tot_solve(problem: str, max_depth: int = 3, branching_factor: int = 3):
    """Tree of Thoughts solver."""
    
    # Initialize root
    root = ThoughtNode(f"Problem: {problem}")
    candidates = [root]
    
    for depth in range(max_depth):
        new_candidates = []
        
        for node in candidates[:branching_factor]:  # Explore top candidates
            # Generate possible next thoughts
            prompt = f"""
Given the problem and current thoughts, generate 3 possible next steps:

Problem: {problem}
Thoughts so far:
{'\n'.join(node.get_path())}

Next steps:"""
            
            response = llm.invoke(prompt)
            thoughts = parse_thoughts(response, n=branching_factor)
            
            for thought in thoughts:
                child = ThoughtNode(thought, parent=node)
                node.children.append(child)
                new_candidates.append(child)
        
        # Evaluate candidates
        for node in new_candidates:
            eval_prompt = f"""
Rate the quality of this reasoning path (0-10):
{'\n'.join(node.get_path())}

Rating:"""
            
            eval_response = llm.invoke(eval_prompt)
            node.value = parse_rating(eval_response)
        
        # Keep top candidates
        candidates = sorted(new_candidates, key=lambda x: x.value or 0, reverse=True)
    
    # Return best path
    best = max(candidates, key=lambda x: x.value or 0)
    return best.get_path()
```

**Best practices [已验证, 2026-04]:**
- Keep branching factor small (2-4) to control cost
- Use explicit evaluation criteria
- Prune low-value branches early
- Consider beam search variant for efficiency

**Cost warning:** ToT can be 10-50x more expensive than CoT due to multiple branches and evaluations.

---

## 6. ReAct (Reasoning + Acting)

**Definition:** Interleave reasoning steps with tool/actions. The model thinks, acts, observes, and repeats.

**When to use:** Tasks requiring external tools (search, calculator, APIs, databases).

**Code template:**
```python
from typing import Dict, Any
import json

class ReActAgent:
    def __init__(self, llm, tools: Dict[str, Any]):
        self.llm = llm
        self.tools = tools
    
    def run(self, query: str, max_iterations: int = 10) -> str:
        """Run ReAct loop."""
        thought_history = []
        
        for i in range(max_iterations):
            # Build prompt with history
            prompt = self._build_prompt(query, thought_history)
            
            # Get model response
            response = self.llm.invoke(prompt)
            parsed = self._parse_response(response)
            
            if parsed["type"] == "final_answer":
                return parsed["content"]
            
            elif parsed["type"] == "action":
                # Execute tool
                tool_name = parsed["tool"]
                tool_input = parsed["input"]
                
                if tool_name in self.tools:
                    observation = self.tools[tool_name](tool_input)
                else:
                    observation = f"Error: Tool '{tool_name}' not found."
                
                thought_history.append({
                    "thought": parsed["thought"],
                    "action": f"{tool_name}({tool_input})",
                    "observation": observation
                })
        
        return "Max iterations reached without answer."
    
    def _build_prompt(self, query: str, history: list) -> str:
        prompt = f"""Answer the following question by interleaving thinking and tool use.

Available tools:
{self._format_tools()}

Use this format:
Thought: [your reasoning]
Action: [tool_name]([input])
Observation: [result]
... (repeat as needed)
Thought: [final reasoning]
Final Answer: [your answer]

Question: {query}
"""
        
        for h in history:
            prompt += f"\nThought: {h['thought']}\n"
            prompt += f"Action: {h['action']}\n"
            prompt += f"Observation: {h['observation']}\n"
        
        prompt += "\nThought:"
        return prompt
    
    def _format_tools(self) -> str:
        return "\n".join([f"- {name}: {func.__doc__}" for name, func in self.tools.items()])
    
    def _parse_response(self, response: str) -> Dict[str, Any]:
        """Parse model response into structured format."""
        # Implementation: parse Thought/Action/Final Answer pattern
        pass

# Usage
tools = {
    "search": lambda q: f"Search results for: {q}",  # Replace with real search
    "calculator": lambda expr: str(eval(expr))  # Replace with safe eval
}

agent = ReActAgent(llm, tools)
result = agent.run("What is the population of France divided by the population of Germany?")
```

**Best practices [已验证, 2026-04]:**
- Provide explicit tool descriptions
- Limit max iterations to control cost
- Include error handling in observations
- Use structured output (JSON) for reliable parsing
- Allow "give up" action to prevent infinite loops

**LangChain implementation:**
```python
from langchain.agents import create_react_agent, AgentExecutor
from langchain.tools import Tool

tools = [
    Tool(name="Search", func=search, description="Search the web"),
    Tool(name="Calculator", func=calculator, description="Calculate mathematical expressions")
]

agent = create_react_agent(llm, tools, react_prompt)
executor = AgentExecutor(agent=agent, tools=tools, verbose=True)
result = executor.invoke({"input": "What is 25 * 47?"})
```

---

## 7. Reflexion (Self-Critique)

**Definition:** The model evaluates its own output, identifies errors, and generates improved responses.

**When to use:** High-stakes tasks where accuracy is critical (code generation, math proofs, factual Q&A).

**Code template:**
```python
class ReflexionAgent:
    def __init__(self, llm, max_reflections: int = 3):
        self.llm = llm
        self.max_reflections = max_reflections
    
    def solve(self, task: str) -> Dict[str, Any]:
        """Solve with self-reflection."""
        
        # Initial attempt
        initial_prompt = f"Solve the following task:\n\n{task}\n\nSolution:"
        solution = self.llm.invoke(initial_prompt)
        
        reflections = []
        current_solution = solution
        
        for i in range(self.max_reflections):
            # Reflect on solution
            reflect_prompt = f"""
Review the following solution for errors or improvements:

Task: {task}
Solution: {current_solution}

Identify any:
1. Factual errors
2. Logical flaws
3. Missing steps
4. Better approaches

Reflection:"""
            
            reflection = self.llm.invoke(reflect_prompt)
            
            # Check if satisfactory
            if "no issues" in reflection.lower() or "correct" in reflection.lower():
                break
            
            # Improve solution
            improve_prompt = f"""
Given the task, original solution, and reflection, provide an improved solution:

Task: {task}
Original Solution: {current_solution}
Reflection: {reflection}

Improved Solution:"""
            
            current_solution = self.llm.invoke(improve_prompt)
            reflections.append({
                "reflection": reflection,
                "improved_solution": current_solution
            })
        
        return {
            "final_solution": current_solution,
            "reflections": reflections,
            "num_reflections": len(reflections)
        }

# Usage
agent = ReflexionAgent(llm, max_reflections=2)
result = agent.solve("Write a Python function to check if a number is prime.")
```

**Best practices [已验证, 2026-04]:**
- Limit reflection iterations (cost grows linearly)
- Use specific critique criteria
- Include "stop" condition when no issues found
- Store reflection history for learning

---

## 8. Agent Patterns

### 8.1 Plan-and-Execute

```python
class PlanAndExecuteAgent:
    def __init__(self, llm, tools):
        self.llm = llm
        self.tools = tools
    
    def run(self, task: str) -> str:
        # Step 1: Plan
        plan_prompt = f"""
Create a step-by-step plan to solve:
{task}

Plan (one step per line):
"""
        plan = self.llm.invoke(plan_prompt)
        steps = [s.strip() for s in plan.split("\n") if s.strip()]
        
        # Step 2: Execute
        context = f"Task: {task}\n"
        for i, step in enumerate(steps):
            exec_prompt = f"""
{context}
Current step: {step}
Execute this step using available tools if needed.
"""
            result = self.llm.invoke(exec_prompt)
            context += f"\nStep {i+1}: {step}\nResult: {result}\n"
        
        # Step 3: Synthesize
        final_prompt = f"""
{context}
Provide the final answer to: {task}
"""
        return self.llm.invoke(final_prompt)
```

### 8.2 Multi-Agent Debate

```python
class MultiAgentDebate:
    def __init__(self, llm, num_agents: int = 3, num_rounds: int = 2):
        self.llm = llm
        self.num_agents = num_agents
        self.num_rounds = num_rounds
    
    def debate(self, question: str) -> str:
        """Run multi-agent debate."""
        
        # Initialize agents with different perspectives
        perspectives = [
            "You are a careful, detail-oriented analyst.",
            "You are a creative, big-picture thinker.",
            "You are a skeptical critic who challenges assumptions."
        ]
        
        responses = []
        
        for round_num in range(self.num_rounds):
            round_responses = []
            
            for i, perspective in enumerate(perspectives[:self.num_agents]):
                prompt = f"""
{perspective}

Question: {question}

Other agents' responses:
{self._format_responses(responses)}

Provide your answer and reasoning:"""
                
                response = self.llm.invoke(prompt)
                round_responses.append({
                    "agent": i,
                    "response": response
                })
            
            responses.append(round_responses)
        
        # Final synthesis
        synthesis_prompt = f"""
Based on the following debate, provide a consensus answer:

{self._format_all_responses(responses)}

Consensus:"""
        
        return self.llm.invoke(synthesis_prompt)
    
    def _format_responses(self, responses: list) -> str:
        if not responses:
            return "None yet."
        return "\n\n".join([
            f"Agent {r['agent']}: {r['response']}"
            for round_responses in responses[-1:]
            for r in round_responses
        ])
```

---

## 9. Paradigm Selection Guide

| Paradigm | Task Type | Latency | Cost | Accuracy | Implementation Complexity |
|----------|-----------|---------|------|----------|--------------------------|
| Zero-shot | Simple instruction | Low | Low | Moderate | Trivial |
| Few-shot | Pattern matching | Low | Low | Good | Trivial |
| CoT | Multi-step reasoning | Medium | Medium | Good | Simple |
| Self-Consistency | High-stakes reasoning | High | High | Very Good | Simple |
| ToT | Complex exploration | Very High | Very High | Excellent | Complex |
| ReAct | Tool use | Medium | Medium | Good | Moderate |
| Reflexion | Critical accuracy | High | High | Excellent | Moderate |
| Agent | Autonomous task | Variable | Variable | Variable | Complex |

**Decision tree:**
```
Start: What does your task need?
|
├── Simple, well-defined → Zero-shot
├── Pattern matching → Few-shot
├── Multi-step reasoning → CoT
│   └── High stakes, can afford cost → Self-Consistency
├── Need external tools → ReAct
├── Complex problem space → ToT
├── Must be highly accurate → Reflexion
└── Autonomous execution → Agent (Plan-and-Execute or Multi-Agent)
```

---

## 10. Advanced Techniques

### 10.1 Chain-of-Verification (CoVe)

```python
def chain_of_verification(question: str) -> str:
    """Generate answer, then verify each claim."""
    
    # Step 1: Draft answer
    draft = llm.invoke(f"Answer: {question}")
    
    # Step 2: Extract claims
    claims = llm.invoke(f"Extract factual claims from:\n{draft}\n\nClaims:")
    claim_list = [c.strip() for c in claims.split("\n") if c.strip()]
    
    # Step 3: Verify each claim
    verified_claims = []
    for claim in claim_list:
        verification = llm.invoke(f"Verify: {claim}\nTrue/False/Uncertain:")
        verified_claims.append({"claim": claim, "status": verification})
    
    # Step 4: Revise based on verification
    revision_prompt = f"""
Original answer: {draft}
Verified claims: {verified_claims}

Provide a revised answer correcting any false claims:
"""
    return llm.invoke(revision_prompt)
```

### 10.2 Analogical Reasoning

```python
def analogical_reasoning(problem: str, domain: str) -> str:
    """Solve by finding analogies to known problems."""
    
    # Step 1: Recall analogous problems
    recall_prompt = f"""
What are 3 problems analogous to:
{problem}

For each, explain the analogy and solution approach:
"""
    analogies = llm.invoke(recall_prompt)
    
    # Step 2: Map solution
    solve_prompt = f"""
Given these analogies:
{analogies}

Solve the original problem:
{problem}
"""
    return llm.invoke(solve_prompt)
```

---

## 11. Cost-Accuracy Tradeoff Summary

| Budget | Recommended Paradigm | Expected Accuracy Gain |
|--------|---------------------|----------------------|
| Minimal | Zero-shot / Few-shot | Baseline |
| Moderate | CoT | +15-30% on reasoning |
| Generous | Self-Consistency | +20-35% on reasoning |
| Unlimited | ToT / Reflexion | +25-45% on complex tasks |

**Important [已验证, 2026-04]:**
- Reasoning models (o3, DeepSeek R1) have built-in CoT — adding explicit CoT may not help
- For simple tasks, complex paradigms can hurt performance (overthinking)
- Always benchmark against baseline (zero-shot) before adopting complex paradigms
