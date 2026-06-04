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

skill_frontmatter() {
  awk '
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { exit }
    in_frontmatter { print }
  ' "$1"
}

assert_no_utility_in_range() {
  file="$1"
  start="$2"
  end="$3"
  awk -v start="$start" -v end="$end" '
    $0 ~ start { in_range = 1; saw_start = 1; next }
    in_range && $0 ~ end { saw_end = 1; in_range = 0; next }
    in_range && /council-claude-p/ { found = 1 }
    END {
      if (!saw_start || !saw_end || found) {
        exit 1
      }
    }
  ' "$file" || fail "$(basename "$file") must not put council-claude-p in the Agent Council main flow"
}

assert_codex_implicit_invocation_disabled() {
  awk '
    /^policy:$/ { in_policy = 1; next }
    in_policy && /^[^[:space:]]/ { in_policy = 0 }
    in_policy && /^  allow_implicit_invocation: false$/ { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$1" || fail "Missing policy.allow_implicit_invocation: false in $1"
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

skills=(council-open council-review council-apply council-status council-help council-version council-upgrade council-claude-p)

for skill in "${skills[@]}"; do
  skill_file="$ROOT/plugins/agent-council/skills/$skill/SKILL.md"
  codex_file="$ROOT/plugins/agent-council/skills/$skill/agents/openai.yaml"

  [ -f "$skill_file" ] || fail "Missing skill: $skill"
  [ -f "$codex_file" ] || fail "Missing Codex metadata for skill: $skill"

  first_line="$(sed -n '1p' "$skill_file")"
  [ "$first_line" = "---" ] || fail "SKILL.md frontmatter must start with ---: $skill_file"
  sed -n '2,10p' "$skill_file" | grep -qx -- '---' || \
    fail "SKILL.md frontmatter must close with standalone --- in first 10 lines: $skill_file"

  frontmatter="$(skill_frontmatter "$skill_file")"
  printf '%s\n' "$frontmatter" | grep -qx 'disable-model-invocation: true' || \
    fail "Missing disable-model-invocation: true in SKILL.md frontmatter: $skill_file"

  assert_codex_implicit_invocation_disabled "$codex_file"
done

[ -f "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" ] || \
  fail "Missing council-claude-p utility skill"
[ -f "$ROOT/plugins/agent-council/skills/council-claude-p/agents/openai.yaml" ] || \
  fail "Missing council-claude-p Codex metadata"

if [ -d "$ROOT/plugins/agent-council/skills/claude-p" ]; then
  fail "Deprecated claude-p skill directory must not remain; use council-claude-p"
fi

if [ -d "$ROOT/plugins/agent-council/skills/council-claude" ] || \
   [ -d "$ROOT/plugins/agent-council/skills/council-codex" ]; then
  fail "Do not add ambiguous council-claude or council-codex skills"
fi

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
  grep -qi 'Optional Workflow Reminders\|可选工作流提醒' "$file" || fail "$readme missing optional workflow reminders"
  grep -qi 'council-claude-p.*optional utility\|optional utility.*council-claude-p\|council-claude-p.*可选工具\|可选工具.*council-claude-p\|council-claude-p.*可选 utility\|可选 utility.*council-claude-p' "$file" || \
    fail "$readme must describe council-claude-p as an optional utility"
  grep -qi 'no substantive text\|没有实质文字' "$file" || \
    fail "$readme missing council-claude-p empty prompt fallback"
  grep -q -- '--diagnose' "$file" || \
    fail "$readme missing council-claude-p diagnose guidance"
  grep -q '600 seconds\|600 秒' "$file" || \
    fail "$readme missing council-claude-p 600 second timeout guidance"
done

assert_no_utility_in_range "$ROOT/README.md" '^## Commands$' '^## What It Solves$'
assert_no_utility_in_range "$ROOT/README.md" '^## Basic Workflow$' '^## Topic Ids$'
assert_no_utility_in_range "$ROOT/README.md" '^## Claude Code$' '^## Codex$'
assert_no_utility_in_range "$ROOT/README.md" '^## Codex$' '^## Basic Workflow$'
assert_no_utility_in_range "$ROOT/README.zh-CN.md" '^## 命令$' '^## 解决什么问题$'
assert_no_utility_in_range "$ROOT/README.zh-CN.md" '^## 基本流程$' '^## Topic Id$'
assert_no_utility_in_range "$ROOT/README.zh-CN.md" '^## Claude Code$' '^## Codex$'
assert_no_utility_in_range "$ROOT/README.zh-CN.md" '^## Codex$' '^## 基本流程$'
assert_no_utility_in_range "$ROOT/docs/USAGE.md" '^## Commands$' '^## Optional utility: council-claude-p$'
assert_no_utility_in_range "$ROOT/docs/USAGE.md" '^## Open a topic$' '^## Notes$'
assert_no_utility_in_range "$ROOT/docs/USAGE.zh-CN.md" '^## 命令$' '^## 可选工具：council-claude-p$'
assert_no_utility_in_range "$ROOT/docs/USAGE.zh-CN.md" '^## 开启话题$' '^## 说明$'

grep -q 'claude -p' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p skill must document claude -p"
grep -q 'command -v claude' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p skill must check local claude CLI"
grep -q 'not part of the Agent Council review loop' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p must be outside Council loop"
grep -q 'Agent Council does not install Claude Code' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p must clarify Claude Code install boundary"
grep -q 'The user-facing skill command is `council-claude-p`' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p must document user-facing command"
grep -q 'latest/council-claude-p.md' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p missing topic save path"
grep -q 'do not write `.agent-council/` paths through `--output`' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p --output must not write Council paths"
grep -q 'any `Bash(...)` pattern' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p must warn on Bash allowed-tools"
grep -q 'Council Claude P status: starting' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p must announce starting status"
grep -q 'Council Claude P status: running' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p must provide running status updates"
grep -q 'Council Claude P status: completed' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p must announce completed status"
grep -q 'Council Claude P status: timed out' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p must announce timeout status"
grep -q '15 to' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p must define status update interval"
grep -q 'Default timeout: 600 seconds (10 minutes)' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p default timeout must be 600 seconds"
grep -q 'Timeout: 600s' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p status template must show 600s timeout"
grep -q '30 seconds' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p diagnose ping should stay short"
grep -q 'Whitespace-only input and punctuation-only input do not count as a prompt' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p must ignore empty punctuation-only prompts"
grep -q 'most recent substantive visible chat message' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p must use recent visible chat fallback"
grep -q 'Do not invent context' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p must not invent missing context"
grep -q -- '--diagnose' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p must support diagnose mode"
grep -q 'Council Claude P diagnose' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p must define diagnose output"
grep -q 'Reply with exactly: council-claude-p-ok' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p diagnose must include ping prompt"
grep -q 'non-zero exit code' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p timeout output must include exit/stderr guidance"
grep -q 'do not declare `CONSENSUS`' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p must not declare consensus"
grep -q 'Do not automatically trigger `council-apply`' "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" || fail "council-claude-p must not trigger council-apply"

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
grep -q "Agent Council v$VERSION" "$ROOT/docs/USAGE.md" || fail "docs/USAGE.md version does not match VERSION"
grep -q "Agent Council v$VERSION" "$ROOT/docs/USAGE.zh-CN.md" || fail "docs/USAGE.zh-CN.md version does not match VERSION"
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
grep -q 'current language' "$ROOT/README.md" || fail "README.md missing reminder language matching"
grep -q '当前语种' "$ROOT/README.zh-CN.md" || fail "README.zh-CN.md missing reminder language matching"
grep -q 'must not invoke Council' "$ROOT/docs/PROTOCOL.md" || fail "PROTOCOL.md reminders must not invoke Council"
grep -q '不能调用 Council' "$ROOT/docs/PROTOCOL.zh-CN.md" || fail "PROTOCOL.zh-CN.md reminders must not invoke Council"
grep -q 'Default behavior is read-only' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade must be check-only by default"
grep -q 'only when the user includes `--apply`' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade must require --apply for install changes"
grep -q 'Do not treat `--ref` by itself as permission to upgrade' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade must not let --ref imply apply"
grep -q -- '--ref {git_ref}' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade missing --ref guidance"
grep -q -- 'council-upgrade --apply' "$ROOT/plugins/agent-council/skills/council-version/SKILL.md" || fail "council-version must recommend explicit apply upgrade"
grep -q -- 'council-upgrade --apply' "$ROOT/README.md" || fail "README.md missing explicit apply upgrade example"
grep -q -- 'council-upgrade --apply' "$ROOT/README.zh-CN.md" || fail "README.zh-CN.md missing explicit apply upgrade example"
grep -q -- '--ref {git_ref}' "$ROOT/README.md" || fail "README.md missing optional ref guidance"
grep -q -- '--ref {git_ref}' "$ROOT/README.zh-CN.md" || fail "README.zh-CN.md missing optional ref guidance"

while IFS= read -r repo_file; do
  case "$repo_file" in
    .agent-council/*)
      continue
      ;;
  esac
  [ -f "$ROOT/$repo_file" ] || continue
  if grep -Eqi '[Ii][Pp][Tt][Vv]' "$ROOT/$repo_file"; then
    fail "Repository must not contain the forbidden project-specific acronym"
  fi
done < <(git -C "$ROOT" ls-files -co --exclude-standard)

if grep -R '<\(topic-id\|current-agent\|peer-agent\|peer\|next-number\|number\|agent\|state\|turn\)>' \
  "$ROOT/README.md" "$ROOT/README.zh-CN.md" "$ROOT/plugins/agent-council/skills" "$ROOT/docs"; then
  fail "Use safe placeholders like {topic_id}; do not use raw angle-bracket placeholders"
fi

if grep -R -E '\.agent-council/active//|latest/\.md|turns/--' \
  "$ROOT/README.md" "$ROOT/README.zh-CN.md" "$ROOT/plugins/agent-council/skills" "$ROOT/docs"; then
  fail "Detected collapsed placeholder path such as active//, latest/.md, or turns/--"
fi

echo "Validation passed."
