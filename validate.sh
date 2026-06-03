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

skills=(council-open council-review council-apply council-status council-help council-version council-upgrade)

for skill in "${skills[@]}"; do
  skill_file="$ROOT/plugins/agent-council/skills/$skill/SKILL.md"
  codex_file="$ROOT/plugins/agent-council/skills/$skill/agents/openai.yaml"

  [ -f "$skill_file" ] || fail "Missing skill: $skill"
  [ -f "$codex_file" ] || fail "Missing Codex metadata for skill: $skill"

  first_line="$(sed -n '1p' "$skill_file")"
  [ "$first_line" = "---" ] || fail "SKILL.md frontmatter must start with ---: $skill_file"
  sed -n '2,10p' "$skill_file" | grep -qx -- '---' || \
    fail "SKILL.md frontmatter must close with standalone --- in first 10 lines: $skill_file"

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
  grep -q 'council-version' "$file" || fail "$readme missing council-version guidance"
  grep -q '500 words' "$file" || fail "$readme missing handoff size budget"
  grep -q '2026-06-03-1' "$file" || fail "$readme missing automatic topic id example"
  grep -qi 'human-invoked\|显式唤醒' "$file" || fail "$readme missing manual invocation boundary"
done

grep -q 'lightweight, manual latest-turn bridge' "$ROOT/README.md" || \
  fail "README.md missing lightweight manual bridge positioning"
grep -q 'preserves consensus without polluting project files' "$ROOT/README.md" || \
  fail "README.md missing clean project files positioning"
grep -q 'Agent Council 是 Claude Code 与 Codex 之间的轻量手动交接板' "$ROOT/README.zh-CN.md" || \
  fail "README.zh-CN.md missing lightweight manual bridge positioning"

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
grep -q "Agent Council v$VERSION" "$ROOT/plugins/agent-council/skills/council-version/SKILL.md" || fail "council-version version does not match VERSION"

grep -q -- '--doctor' "$ROOT/plugins/agent-council/skills/council-status/SKILL.md" || fail "council-status missing --doctor"
grep -q 'Side effects' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review missing Side effects"
grep -q 'Verdict: {state}' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review missing compact verdict-first output"
grep -q 'maximum 500 words' "$ROOT/plugins/agent-council/skills/council-open/SKILL.md" || fail "council-open missing handoff size budget"
grep -q 'maximum 500 words' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review missing handoff size budget"
grep -q 'topic id is optional' "$ROOT/plugins/agent-council/skills/council-open/SKILL.md" || fail "council-open missing optional topic-id rule"
grep -q '{YYYY-MM-DD}-{n}' "$ROOT/plugins/agent-council/skills/council-open/SKILL.md" || fail "council-open missing generated topic-id format"
grep -q 'latest/claude.md' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review CONSENSUS must read claude latest"
grep -q 'latest/codex.md' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review CONSENSUS must read codex latest"
grep -q -- '--overwrite' "$ROOT/plugins/agent-council/skills/council-open/SKILL.md" || fail "council-open missing overwrite guard"
grep -q 'USER_DECISION_NEEDED' "$ROOT/plugins/agent-council/skills/council-apply/SKILL.md" || fail "council-apply missing user decision guard"
grep -q 'USER_FORCED_CONSENSUS' "$ROOT/plugins/agent-council/skills/council-apply/SKILL.md" || fail "council-apply missing forced consensus guard"
grep -q 'Must-Preserve Nits' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review missing consensus nits template"
grep -q 'formal_files_modified' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review missing lightweight frontmatter"
grep -q 'canonical lowercase' "$ROOT/plugins/agent-council/skills/council-open/SKILL.md" || fail "council-open missing lowercase agent id rule"
grep -q 'canonical lowercase' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review missing lowercase agent id rule"
grep -q 'Never write paths with' "$ROOT/plugins/agent-council/skills/council-open/SKILL.md" || fail "council-open missing mixed-case path guard"
grep -q 'Never write paths with' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review missing mixed-case path guard"
grep -q 'case-conflict' "$ROOT/plugins/agent-council/skills/council-status/SKILL.md" || fail "council-status doctor missing case-conflict check"
grep -q 'Manual invocation boundary' "$ROOT/plugins/agent-council/skills/council-open/SKILL.md" || fail "council-open missing manual invocation boundary"
grep -q 'Manual invocation boundary' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review missing manual invocation boundary"
grep -q 'Manual invocation boundary' "$ROOT/plugins/agent-council/skills/council-status/SKILL.md" || fail "council-status missing manual invocation boundary"
grep -q 'Manual invocation boundary' "$ROOT/plugins/agent-council/skills/council-apply/SKILL.md" || fail "council-apply missing manual invocation boundary"
grep -q 'automatically stop tasks' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review must not auto-stop tasks"
grep -q 'do not run standalone installation commands' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade plugin guard missing"
grep -q 'chain.*next task' "$ROOT/README.md" || fail "README.md missing no-chaining boundary"
grep -q '自动串联' "$ROOT/README.zh-CN.md" || fail "README.zh-CN.md missing no-chaining boundary"
grep -q 'Default behavior is read-only' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade must be check-only by default"
grep -q 'only when the user includes `--apply`' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade must require --apply for install changes"
grep -q 'Do not treat `--ref` by itself as permission to upgrade' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade must not let --ref imply apply"
grep -q -- '--ref {git_ref}' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade missing --ref guidance"
grep -q -- 'council-upgrade --apply' "$ROOT/plugins/agent-council/skills/council-version/SKILL.md" || fail "council-version must recommend explicit apply upgrade"
grep -q -- 'council-upgrade --apply' "$ROOT/README.md" || fail "README.md missing explicit apply upgrade example"
grep -q -- 'council-upgrade --apply' "$ROOT/README.zh-CN.md" || fail "README.zh-CN.md missing explicit apply upgrade example"
grep -q -- '--ref {git_ref}' "$ROOT/README.md" || fail "README.md missing optional ref guidance"
grep -q -- '--ref {git_ref}' "$ROOT/README.zh-CN.md" || fail "README.zh-CN.md missing optional ref guidance"

if grep -Rqi 'IPTV' "$ROOT/README.md" "$ROOT/README.zh-CN.md" "$ROOT/plugins/agent-council/skills" "$ROOT/docs"; then
  fail "Docs or skills must not contain IPTV"
fi

if grep -R '<\(topic-id\|current-agent\|peer-agent\|peer\|next-number\|number\|agent\|state\|turn\)>' \
  "$ROOT/README.md" "$ROOT/README.zh-CN.md" "$ROOT/plugins/agent-council/skills" "$ROOT/docs"; then
  fail "Use safe placeholders like {topic_id}; do not use raw angle-bracket placeholders"
fi

if grep -R -E '\.agent-council/active//|latest/\.md|turns/--' \
  "$ROOT/README.md" "$ROOT/README.zh-CN.md" "$ROOT/plugins/agent-council/skills" "$ROOT/docs"; then
  fail "Detected collapsed placeholder path such as active//, latest/.md, or turns/--"
fi

echo "Validation passed."
