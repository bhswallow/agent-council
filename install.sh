#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: ./install.sh <project-root> [--claude-only|--codex-only] [--force]"
}

if [ "${1:-}" = "" ]; then
  usage
  exit 1
fi

ROOT="$1"
shift
MODE=""
FORCE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/plugins/agent-council/skills"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --claude-only|--codex-only)
      if [ -n "$MODE" ]; then
        usage
        exit 1
      fi
      MODE="$1"
      ;;
    --force)
      FORCE=true
      ;;
    *)
      usage
      exit 1
      ;;
  esac
  shift
done

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
  # Always reconcile known Agent Council directories. --force is accepted so
  # council-upgrade can make that cleanup intent explicit.
  rm -rf "$ROOT/.claude/skills/council-respond"
  rm -rf "$ROOT/.claude/skills/claude-p"
  for skill in council-open council-review council-apply council-status council-help council-upgrade council-version council-peer-p council-claude-p council-longrun; do
    rm -rf "$ROOT/.claude/skills/$skill"
    cp -R "$SKILLS_SRC/$skill" "$ROOT/.claude/skills/$skill"
  done
  for skill in council-peer-p council-claude-p council-upgrade council-help; do
    if [ ! -d "$ROOT/.claude/skills/$skill" ]; then
      echo "Required skill missing after install: $ROOT/.claude/skills/$skill" >&2
      exit 1
    fi
  done
  if [ -e "$ROOT/.claude/skills/council-respond" ]; then
    echo "Deprecated skill still exists after cleanup: $ROOT/.claude/skills/council-respond" >&2
    exit 1
  fi
  if [ -e "$ROOT/.claude/skills/claude-p" ]; then
    echo "Deprecated skill still exists after cleanup: $ROOT/.claude/skills/claude-p" >&2
    exit 1
  fi
  echo "Installed Claude Code skills into $ROOT/.claude/skills"
}

install_codex() {
  mkdir -p "$ROOT/.agents/skills"
  # Always reconcile known Agent Council directories. --force is accepted so
  # council-upgrade can make that cleanup intent explicit.
  rm -rf "$ROOT/.agents/skills/council-respond"
  rm -rf "$ROOT/.agents/skills/claude-p"
  for skill in council-open council-review council-apply council-status council-help council-upgrade council-version council-peer-p council-claude-p council-longrun; do
    rm -rf "$ROOT/.agents/skills/$skill"
    cp -R "$SKILLS_SRC/$skill" "$ROOT/.agents/skills/$skill"
  done
  for skill in council-peer-p council-claude-p council-upgrade council-help; do
    if [ ! -d "$ROOT/.agents/skills/$skill" ]; then
      echo "Required skill missing after install: $ROOT/.agents/skills/$skill" >&2
      exit 1
    fi
  done
  if [ -e "$ROOT/.agents/skills/council-respond" ]; then
    echo "Deprecated skill still exists after cleanup: $ROOT/.agents/skills/council-respond" >&2
    exit 1
  fi
  if [ -e "$ROOT/.agents/skills/claude-p" ]; then
    echo "Deprecated skill still exists after cleanup: $ROOT/.agents/skills/claude-p" >&2
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
