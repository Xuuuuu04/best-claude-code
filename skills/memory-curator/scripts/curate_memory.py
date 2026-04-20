#!/usr/bin/env python3
# curate_memory.py — 记忆库健康检查工具（只读分析，不修改文件）
# 检测：重复条目 / 过期条目（>N天）/ 冲突条目
# 用法：
#   python3 curate_memory.py                         # 扫描默认路径
#   python3 curate_memory.py --dir <路径>             # 指定目录
#   python3 curate_memory.py --expire-days 90        # 自定义过期阈值
#   python3 curate_memory.py --json                  # JSON 格式输出
# 退出码：0=健康，1=有建议，2=有冲突

import sys
import re
import json
import argparse
from pathlib import Path
from datetime import datetime, timedelta
from collections import defaultdict

# 默认记忆库路径
DEFAULT_MEMORY_DIR = (
    Path.home() / ".claude" / "projects" / "-Users-mumuxsy-Desktop" / "memory"
)

# 默认过期阈值（天）
DEFAULT_EXPIRE_DAYS = 180

# 中文停用词（用于相似度计算时过滤）
STOP_WORDS = {
    "的", "了", "在", "是", "我", "有", "和", "就", "不", "人", "都", "一",
    "一个", "上", "也", "很", "到", "说", "要", "去", "你", "会", "着", "没有",
    "看", "好", "自己", "这", "那", "但", "还", "用", "或", "与", "及",
}


def extract_date_from_content(content: str) -> datetime | None:
    """从文件内容提取最后更新日期"""
    # 尝试多种日期格式
    patterns = [
        r'最后更新[：:]\s*(\d{4}-\d{2}-\d{2})',
        r'更新时间[：:]\s*(\d{4}-\d{2}-\d{2})',
        r'日期[：:]\s*(\d{4}-\d{2}-\d{2})',
        r'\[(\d{4}-\d{2}-\d{2})\]',
        r'(\d{4}-\d{2}-\d{2})',
    ]
    for pattern in patterns:
        m = re.search(pattern, content)
        if m:
            try:
                return datetime.strptime(m.group(1), '%Y-%m-%d')
            except ValueError:
                continue
    return None


def extract_key_value_pairs(content: str) -> dict:
    """提取文件中的 key-value 对（支持多种格式）"""
    pairs = {}

    # 格式1：**key**：value
    for m in re.finditer(r'\*\*([^*]+)\*\*[：:]\s*(.+?)(?:\n|$)', content):
        pairs[m.group(1).strip()] = m.group(2).strip()

    # 格式2：key: value（简单冒号格式）
    for m in re.finditer(r'^([a-zA-Z\u4e00-\u9fff][^：:\n]{2,30})[：:]\s*(.+?)$', content, re.MULTILINE):
        key = m.group(1).strip()
        # 排除标题和 URL
        if not key.startswith('#') and '/' not in key and len(key) < 30:
            pairs[key] = m.group(2).strip()

    return pairs


def tokenize(text: str) -> set:
    """简单分词：提取中文字符序列和英文词"""
    tokens = set()
    # 中文字符提取（连续 2-4 个字）
    for m in re.finditer(r'[\u4e00-\u9fff]{2,4}', text):
        token = m.group()
        if token not in STOP_WORDS:
            tokens.add(token)
    # 英文词提取
    for m in re.finditer(r'[a-zA-Z]{3,}', text):
        tokens.add(m.group().lower())
    return tokens


def jaccard_similarity(tokens1: set, tokens2: set) -> float:
    """计算 Jaccard 相似度"""
    if not tokens1 or not tokens2:
        return 0.0
    intersection = tokens1 & tokens2
    union = tokens1 | tokens2
    return len(intersection) / len(union)


def load_memory_files(memory_dir: Path) -> list:
    """加载记忆库目录下的所有文件"""
    entries = []

    if not memory_dir.exists():
        return entries

    for filepath in sorted(memory_dir.rglob("*.md")):
        try:
            content = filepath.read_text(encoding='utf-8', errors='ignore')
        except Exception:
            continue

        # 获取文件修改时间作为备用日期
        file_mtime = datetime.fromtimestamp(filepath.stat().st_mtime)

        entry_date = extract_date_from_content(content)
        if not entry_date:
            entry_date = file_mtime

        entries.append({
            "filepath": filepath,
            "content": content,
            "tokens": tokenize(content),
            "kv_pairs": extract_key_value_pairs(content),
            "last_updated": entry_date,
            "file_mtime": file_mtime,
            "line_count": len(content.split('\n')),
        })

    return entries


def detect_duplicates(entries: list, threshold: float = 0.6) -> list:
    """检测高度相似的条目对（Jaccard ≥ threshold 视为重复）"""
    duplicates = []
    n = len(entries)

    for i in range(n):
        for j in range(i + 1, n):
            sim = jaccard_similarity(entries[i]["tokens"], entries[j]["tokens"])
            if sim >= threshold:
                duplicates.append({
                    "file_a": entries[i]["filepath"],
                    "file_b": entries[j]["filepath"],
                    "similarity": sim,
                    "suggestion": "建议合并" if sim < 0.8 else "建议删除其一（高度重复）",
                })

    return duplicates


def detect_expired(entries: list, expire_days: int) -> list:
    """检测过期条目（超过 expire_days 天未更新）"""
    now = datetime.now()
    cutoff = now - timedelta(days=expire_days)
    expired = []

    for entry in entries:
        if entry["last_updated"] < cutoff:
            days_old = (now - entry["last_updated"]).days
            expired.append({
                "filepath": entry["filepath"],
                "last_updated": entry["last_updated"].strftime("%Y-%m-%d"),
                "days_old": days_old,
                "suggestion": f"已 {days_old} 天未更新，建议确认是否仍有效",
            })

    return expired


def detect_conflicts(entries: list) -> list:
    """检测相同 key 下不同 value 的冲突"""
    conflicts = []

    # 收集所有 key-value 对（跨文件）
    key_to_values = defaultdict(list)
    for entry in entries:
        for key, value in entry["kv_pairs"].items():
            key_to_values[key].append({
                "filepath": entry["filepath"],
                "value": value,
            })

    # 找出同一 key 下有多个不同 value 的情况
    for key, value_list in key_to_values.items():
        unique_values = list({v["value"] for v in value_list})
        if len(unique_values) > 1:
            conflicts.append({
                "key": key,
                "conflicting_entries": value_list,
                "unique_values": unique_values,
                "suggestion": f"同一概念 '{key}' 在多处有不同描述，需人工确认哪个版本正确",
            })

    return conflicts


def format_text_output(
    entries: list,
    duplicates: list,
    expired: list,
    conflicts: list,
    expire_days: int,
    memory_dir: Path,
) -> str:
    lines = []
    lines.append("=" * 60)
    lines.append(" 记忆库健康检查")
    lines.append("=" * 60)
    lines.append(f" 扫描路径：{memory_dir}")
    lines.append(f" 过期阈值：{expire_days} 天")
    lines.append(f" 总条目数：{len(entries)} 个文件")
    lines.append("=" * 60)
    lines.append("")

    # 重复检测
    lines.append(f"## 重复条目（{len(duplicates)} 对）")
    lines.append("")
    if duplicates:
        for dup in duplicates:
            sim_pct = f"{dup['similarity']:.0%}"
            lines.append(f"[{dup['suggestion']}]")
            lines.append(f"  文件 A：{dup['file_a'].name}")
            lines.append(f"  文件 B：{dup['file_b'].name}")
            lines.append(f"  相似度：{sim_pct}")
            lines.append("")
    else:
        lines.append("  未检测到重复条目 ✓")
        lines.append("")

    # 过期检测
    lines.append(f"## 过期条目（{len(expired)} 个，超过 {expire_days} 天）")
    lines.append("")
    if expired:
        for exp in expired:
            lines.append(f"[建议确认] {exp['filepath'].name}")
            lines.append(f"  最后更新：{exp['last_updated']}（已 {exp['days_old']} 天）")
            lines.append(f"  建议：{exp['suggestion']}")
            lines.append("")
    else:
        lines.append(f"  未检测到超过 {expire_days} 天的过期条目 ✓")
        lines.append("")

    # 冲突检测
    lines.append(f"## 冲突条目（{len(conflicts)} 个 key 存在冲突）")
    lines.append("")
    if conflicts:
        for conf in conflicts:
            lines.append(f"[建议确认] Key: '{conf['key']}'")
            for entry in conf["conflicting_entries"]:
                lines.append(f"  - {entry['filepath'].name}: {entry['value'][:50]}")
            lines.append(f"  建议：{conf['suggestion']}")
            lines.append("")
    else:
        lines.append("  未检测到 key-value 冲突 ✓")
        lines.append("")

    lines.append("=" * 60)
    lines.append(" 注意：本工具只提供建议，不会自动修改或删除任何记忆文件")
    lines.append("=" * 60)

    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description="记忆库健康检查工具（只读）")
    parser.add_argument("--dir", default=str(DEFAULT_MEMORY_DIR), help="记忆库目录路径")
    parser.add_argument("--expire-days", type=int, default=DEFAULT_EXPIRE_DAYS, help="过期阈值（天数，默认 180）")
    parser.add_argument("--json", action="store_true", help="JSON 格式输出")
    args = parser.parse_args()

    memory_dir = Path(args.dir)

    if not memory_dir.exists():
        print(f"[WARN]  记忆库目录不存在: {memory_dir}")
        print(f"        尝试路径: {DEFAULT_MEMORY_DIR}")
        sys.exit(1)

    entries = load_memory_files(memory_dir)
    if not entries:
        print(f"[INFO]  记忆库目录为空或无 .md 文件: {memory_dir}")
        sys.exit(0)

    duplicates = detect_duplicates(entries)
    expired = detect_expired(entries, args.expire_days)
    conflicts = detect_conflicts(entries)

    if args.json:
        def serialize_path(p):
            return str(p)

        output = {
            "total_entries": len(entries),
            "duplicates": [
                {
                    "file_a": serialize_path(d["file_a"]),
                    "file_b": serialize_path(d["file_b"]),
                    "similarity": round(d["similarity"], 3),
                    "suggestion": d["suggestion"],
                }
                for d in duplicates
            ],
            "expired": [
                {
                    "filepath": serialize_path(e["filepath"]),
                    "last_updated": e["last_updated"],
                    "days_old": e["days_old"],
                    "suggestion": e["suggestion"],
                }
                for e in expired
            ],
            "conflicts": [
                {
                    "key": c["key"],
                    "conflicting_files": [serialize_path(e["filepath"]) for e in c["conflicting_entries"]],
                    "unique_values": c["unique_values"],
                    "suggestion": c["suggestion"],
                }
                for c in conflicts
            ],
        }
        print(json.dumps(output, ensure_ascii=False, indent=2))
    else:
        print(format_text_output(entries, duplicates, expired, conflicts, args.expire_days, memory_dir))

    has_conflict = len(conflicts) > 0
    has_suggestions = len(duplicates) > 0 or len(expired) > 0

    if has_conflict:
        sys.exit(2)
    elif has_suggestions:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
