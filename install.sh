#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: ./install.sh <project-root> [--claude-only|--codex-only]"
}

if [ "${1:-}" = "" ]; then
  usage
  exit 1
fi

ROOT="$1"
MODE="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/plugins/agent-council/skills"

if [ ! -d "$ROOT" ]; then
  echo "Project root does not exist: $ROOT" >&2
  exit 1
fi

if [ ! -d "$SKILLS_SRC" ]; then
  echo "Cannot find skills source: $SKILLS_SRC" >&2
  exit 1
fi

install_claude() {
  mkdir -p "$ROOT/.claude/skills"
  rm -rf "$ROOT/.claude/skills/council-respond"
  for skill in council-open council-review council-apply council-status council-help; do
    rm -rf "$ROOT/.claude/skills/$skill"
    cp -R "$SKILLS_SRC/$skill" "$ROOT/.claude/skills/$skill"
  done
  if [ -e "$ROOT/.claude/skills/council-respond" ]; then
    echo "Deprecated skill still exists after cleanup: $ROOT/.claude/skills/council-respond" >&2
    exit 1
  fi
  echo "Installed Claude Code skills into $ROOT/.claude/skills"
}

install_codex() {
  mkdir -p "$ROOT/.agents/skills"
  rm -rf "$ROOT/.agents/skills/council-respond"
  for skill in council-open council-review council-apply council-status council-help; do
    rm -rf "$ROOT/.agents/skills/$skill"
    cp -R "$SKILLS_SRC/$skill" "$ROOT/.agents/skills/$skill"
  done
  if [ -e "$ROOT/.agents/skills/council-respond" ]; then
    echo "Deprecated skill still exists after cleanup: $ROOT/.agents/skills/council-respond" >&2
    exit 1
  fi
  echo "Installed Codex skills into $ROOT/.agents/skills"
}

case "$MODE" in
  "")
    install_claude
    install_codex
    ;;
  --claude-only)
    install_claude
    ;;
  --codex-only)
    install_codex
    ;;
  *)
    usage
    exit 1
    ;;
esac

echo "Done. Consider adding .agent-council/ to the target project's .gitignore."
