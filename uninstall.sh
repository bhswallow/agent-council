#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: ./uninstall.sh <project-root> [--claude-only|--codex-only] [--dry-run|--apply] [--remove-state]"
}

if [ "${1:-}" = "" ]; then
  usage
  exit 1
fi

ROOT="$1"
shift
MODE=""
APPLY=false
REMOVE_STATE=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --claude-only|--codex-only)
      if [ -n "$MODE" ]; then
        usage
        exit 1
      fi
      MODE="$1"
      ;;
    --dry-run)
      APPLY=false
      ;;
    --apply)
      APPLY=true
      ;;
    --remove-state)
      REMOVE_STATE=true
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

remove_path() {
  path="$1"
  if [ -e "$path" ]; then
    if [ "$APPLY" = true ]; then
      rm -rf "$path"
      echo "Removed $path"
    else
      echo "Would remove $path"
    fi
  fi
}

remove_claude() {
  for skill in council council-open council-review council-respond council-apply council-status council-help council-upgrade council-uninstall council-version council-peer-p council-claude-p council-longrun claude-p; do
    remove_path "$ROOT/.claude/skills/$skill"
  done
  if [ "$APPLY" = true ]; then
    echo "Removed Agent Council Claude Code skills from $ROOT/.claude/skills"
  else
    echo "Dry run: no Claude Code skills were removed from $ROOT/.claude/skills"
  fi
}

remove_codex() {
  for skill in council council-open council-review council-respond council-apply council-status council-help council-upgrade council-uninstall council-version council-peer-p council-claude-p council-longrun claude-p; do
    remove_path "$ROOT/.agents/skills/$skill"
  done
  if [ "$APPLY" = true ]; then
    echo "Removed Agent Council Codex skills from $ROOT/.agents/skills"
  else
    echo "Dry run: no Codex skills were removed from $ROOT/.agents/skills"
  fi
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

if [ "$REMOVE_STATE" = true ]; then
  remove_path "$ROOT/.agent-council"
else
  echo "Kept .agent-council/ discussion state."
fi

if [ "$APPLY" = true ]; then
  echo "Done."
else
  echo "Dry run done. Re-run with --apply to remove files."
fi
