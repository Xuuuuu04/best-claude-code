---
name: memory-curator
description: "记忆库整理工具：扫描 ~/.claude/projects/-Users-mumuxsy-Desktop/memory/*.md，检测重复条目、过期条目（>180天未更新）、冲突条目，只出建议不自动删除。TRIGGER when: MEMORY.md 超过 180 行; or user asks '整理记忆' / '记忆太多了' / 'memory 清理' / '清理一下记忆库' / '记忆库有冲突吗'. DO NOT TRIGGER when: user wants to save new memory (that's handled by auto-memory mechanism), or user asks about project content."
---

# Memory Curator Skill

## 概述

本 skill 对记忆库进行健康检查，识别需要人工介入的三类问题：

1. **重复**：两个条目描述相同事实（基于关键词相似度检测）
2. **过期**：180 天以上未更新的条目（可能信息已失效）
3. **冲突**：相同 key 或主题下存在不同 value 的条目

**重要约束**：本 skill 只读取、分析、生成建议——不自动修改或删除任何记忆条目。

## 使用方式

```bash
# 扫描默认记忆库路径
python3 ~/.claude/skills/memory-curator/scripts/curate_memory.py

# 指定记忆库目录
python3 ~/.claude/skills/memory-curator/scripts/curate_memory.py --dir /path/to/memory/

# 设置过期天数阈值（默认 180）
python3 ~/.claude/skills/memory-curator/scripts/curate_memory.py --expire-days 90

# JSON 格式输出（供主进程解读）
python3 ~/.claude/skills/memory-curator/scripts/curate_memory.py --json
```

## 输出说明

脚本输出三类建议：
- `[建议删除]`：高度重复或明确过期的条目
- `[建议合并]`：内容部分重复可以合并的条目对
- `[建议确认]`：检测到潜在冲突，需人工判断的条目

## 依赖

- Python 3.8+（标准库，无需额外安装）
- 记忆库路径：`~/.claude/projects/-Users-mumuxsy-Desktop/memory/`
