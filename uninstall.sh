#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: ./uninstall.sh <project-root> [--claude-only|--codex-only]"
}

if [ "${1:-}" = "" ]; then
  usage
  exit 1
fi

ROOT="$1"
MODE="${2:-}"

remove_claude() {
  for skill in council-open council-review council-respond council-apply council-status council-help council-upgrade council-version council-peer-p council-claude-p council-longrun claude-p; do
    rm -rf "$ROOT/.claude/skills/$skill"
  done
  echo "Removed Claude Code skills from $ROOT/.claude/skills"
}

remove_codex() {
  for skill in council-open council-review council-respond council-apply council-status council-help council-upgrade council-version council-peer-p council-claude-p council-longrun claude-p; do
    rm -rf "$ROOT/.agents/skills/$skill"
  done
  echo "Removed Codex skills from $ROOT/.agents/skills"
}

case "$MODE" in
  "")
    remove_claude
    remove_codex
    ;;
  --claude-only)
    remove_claude
    ;;
  --codex-only)
    remove_codex
    ;;
  *)
    usage
    exit 1
    ;;
esac

echo "Done. This does not remove .agent-council/ discussion state."
