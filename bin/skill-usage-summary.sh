#!/usr/bin/env bash
# Summarize recent InstructionsLoaded events for Skills/Rules/CLAUDE.md.

set -uo pipefail

LOG="${1:-$HOME/.claude/logs/instructions-loaded.jsonl}"
LIMIT="${2:-2000}"

if [ ! -f "$LOG" ]; then
  echo "No instructions log at $LOG"
  exit 0
fi

tail -n "$LIMIT" "$LOG" 2>/dev/null | jq -r '
  select(.file_path != null) |
  .file_path as $p |
  if ($p | test("/skills/[^/]+/SKILL.md$")) then
    "skill\t" + ($p | capture("/skills/(?<name>[^/]+)/SKILL.md$").name)
  elif ($p | test("/rules/.*\\.md$")) then
    "rule\t" + ($p | capture("/rules/(?<name>.*)$").name)
  elif ($p | test("CLAUDE.md$")) then
    "claudemd\tCLAUDE.md"
  else empty end
' 2>/dev/null | sort | uniq -c | sort -nr | awk '
  BEGIN { printf "# count\ttype\tname\n" }
  { count=$1; type=$2; $1=""; $2=""; sub(/^  */, ""); printf "%s\t%s\t%s\n", count, type, $0 }
'
