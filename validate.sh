#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"

fail() {
  echo "$1" >&2
  exit 1
}

require_file() {
  [ -f "$ROOT/$1" ] || fail "Missing required file: $1"
}

required=(
  ".claude-plugin/marketplace.json"
  ".agents/plugins/marketplace.json"
  "plugins/agent-council/.claude-plugin/plugin.json"
  "plugins/agent-council/.codex-plugin/plugin.json"
  "README.md"
  "README.zh-CN.md"
  "VERSION"
)

for f in "${required[@]}"; do
  require_file "$f"
done

skills=(council-open council-review council-apply council-status council-help council-upgrade)

for skill in "${skills[@]}"; do
  skill_file="$ROOT/plugins/agent-council/skills/$skill/SKILL.md"
  codex_file="$ROOT/plugins/agent-council/skills/$skill/agents/openai.yaml"

  [ -f "$skill_file" ] || fail "Missing skill: $skill"
  [ -f "$codex_file" ] || fail "Missing Codex metadata for skill: $skill"

  grep -q '^disable-model-invocation: true$' "$skill_file" || \
    fail "Missing disable-model-invocation: true in $skill_file"

  grep -q 'allow_implicit_invocation: false' "$codex_file" || \
    fail "Missing allow_implicit_invocation: false in $codex_file"
done

if [ -d "$ROOT/plugins/agent-council/skills/council-respond" ]; then
  respond_file="$ROOT/plugins/agent-council/skills/council-respond/SKILL.md"
  grep -Eiq 'alias|deprecated' "$respond_file" || \
    fail "council-respond exists but is not marked alias/deprecated"
  ! grep -Eq '^\s*[/\$](agent-council:)?council-respond' "$ROOT/README.md" "$ROOT/README.zh-CN.md" || \
    fail "README must not recommend council-respond in the main flow"
fi

for readme in README.md README.zh-CN.md; do
  file="$ROOT/$readme"
  for state in CONSENSUS CONSENSUS_WITH_NITS USER_FORCED_CONSENSUS NEEDS_DISCUSSION USER_DECISION_NEEDED BLOCKED APPLIED CLOSED ABANDONED; do
    grep -q "$state" "$file" || fail "$readme missing state documentation: $state"
  done
  grep -q 'disable-model-invocation' "$file" || fail "$readme missing disable-model-invocation explanation"
  grep -q 'Next action' "$file" || fail "$readme missing Next action explanation"
  grep -q 'Side effects' "$file" || fail "$readme missing Side effects explanation"
  grep -q 'latest/claude.md' "$file" || fail "$readme missing lowercase claude path guidance"
  grep -q 'latest/codex.md' "$file" || fail "$readme missing lowercase codex path guidance"
  grep -q -- '--doctor' "$file" || fail "$readme missing doctor guidance"
done

python3 - "$ROOT" "$VERSION" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
version = sys.argv[2]

checks = [
    (root / ".claude-plugin/marketplace.json", ["version"]),
    (root / ".claude-plugin/marketplace.json", ["plugins", 0, "version"]),
    (root / ".agents/plugins/marketplace.json", ["version"]),
    (root / ".agents/plugins/marketplace.json", ["plugins", 0, "version"]),
    (root / "plugins/agent-council/.claude-plugin/plugin.json", ["version"]),
    (root / "plugins/agent-council/.codex-plugin/plugin.json", ["version"]),
]

for path, key_path in checks:
    data = json.loads(path.read_text())
    value = data
    for key in key_path:
        value = value[key]
    if value != version:
        dotted = ".".join(str(k) for k in key_path)
        raise SystemExit(
            f"Version mismatch in {path.relative_to(root)}:{dotted}: {value} != {version}"
        )
PY

grep -q "Current version: $VERSION" "$ROOT/README.md" || fail "README.md version does not match VERSION"
grep -q "当前版本：$VERSION" "$ROOT/README.zh-CN.md" || fail "README.zh-CN.md version does not match VERSION"
grep -q "Agent Council v$VERSION" "$ROOT/plugins/agent-council/skills/council-help/SKILL.md" || fail "council-help version does not match VERSION"

grep -q -- '--doctor' "$ROOT/plugins/agent-council/skills/council-status/SKILL.md" || fail "council-status missing --doctor"
grep -q 'Side effects' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review missing Side effects"
grep -q 'Must-Preserve Nits' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review missing consensus nits template"
grep -q 'formal_files_modified' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review missing lightweight frontmatter"
grep -q 'canonical lowercase' "$ROOT/plugins/agent-council/skills/council-open/SKILL.md" || fail "council-open missing lowercase agent id rule"
grep -q 'canonical lowercase' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review missing lowercase agent id rule"
grep -q 'Never write paths with' "$ROOT/plugins/agent-council/skills/council-open/SKILL.md" || fail "council-open missing mixed-case path guard"
grep -q 'Never write paths with' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review missing mixed-case path guard"
grep -q 'case-conflict' "$ROOT/plugins/agent-council/skills/council-status/SKILL.md" || fail "council-status doctor missing case-conflict check"

if grep -Rqi 'IPTV' "$ROOT/README.md" "$ROOT/README.zh-CN.md" "$ROOT/plugins/agent-council/skills" "$ROOT/docs"; then
  fail "Docs or skills must not contain IPTV"
fi

echo "Validation passed."
