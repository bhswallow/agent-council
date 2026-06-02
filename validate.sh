#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

required=(
  ".claude-plugin/marketplace.json"
  ".agents/plugins/marketplace.json"
  "plugins/agent-council/.claude-plugin/plugin.json"
  "plugins/agent-council/.codex-plugin/plugin.json"
  "README.md"
  "README.zh-CN.md"
)

for f in "${required[@]}"; do
  if [ ! -f "$ROOT/$f" ]; then
    echo "Missing required file: $f" >&2
    exit 1
  fi
done

for skill in council-open council-review council-respond council-apply council-status council-help; do
  if [ ! -f "$ROOT/plugins/agent-council/skills/$skill/SKILL.md" ]; then
    echo "Missing skill: $skill" >&2
    exit 1
  fi
  if [ ! -f "$ROOT/plugins/agent-council/skills/$skill/agents/openai.yaml" ]; then
    echo "Missing Codex metadata for skill: $skill" >&2
    exit 1
  fi
done


echo "Validation passed."
