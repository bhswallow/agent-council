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
    in_range && /council-(claude|peer)-p/ { found = 1 }
    END {
      if (!saw_start || !saw_end || found) {
        exit 1
      }
    }
  ' "$file" || fail "$(basename "$file") must not put peer headless utilities in the Agent Council main flow"
}

assert_codex_implicit_invocation_disabled() {
  awk '
    /^policy:$/ { in_policy = 1; next }
    in_policy && /^[^[:space:]]/ { in_policy = 0 }
    in_policy && /^  allow_implicit_invocation: false$/ { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$1" || fail "Missing policy.allow_implicit_invocation: false in $1"
}

assert_shell_skill_loop_contains() {
  file="$1"
  skill="$2"
  awk -v skill="$skill" '
    $1 == "for" && $2 == "skill" && $3 == "in" {
      for (i = 4; i <= NF; i++) {
        token = $i
        sub(/;$/, "", token)
        if (token == skill) found = 1
      }
    }
    END { exit found ? 0 : 1 }
  ' "$file"
}

assert_peer_headless_skill() {
  skill="$1"
  file="$ROOT/plugins/agent-council/skills/$skill/SKILL.md"

  grep -q 'claude -p' "$file" || fail "$skill skill must document claude -p"
  grep -q 'command -v claude' "$file" || fail "$skill skill must check local claude CLI"
  grep -q 'codex exec' "$file" || fail "$skill skill must document codex exec"
  grep -q 'command -v codex' "$file" || fail "$skill skill must check local codex CLI"
  grep -q 'Determine the host from the current assistant/runtime' "$file" || fail "$skill must detect host from runtime"
  grep -q 'If both `claude` and `codex` are installed' "$file" || fail "$skill must not infer host from PATH"
  grep -q 'not part of the Agent Council review loop' "$file" || fail "$skill must be outside Council loop"
  grep -q 'Agent Council does not install Claude Code or Codex' "$file" || fail "$skill must clarify peer CLI install boundary"
  grep -q 'The user-facing skill command is `council-peer-p` or `council-claude-p`' "$file" || fail "$skill must document peer command alias"
  case "$skill" in
    council-peer-p)
      grep -q 'latest/council-peer-p.md' "$file" || fail "$skill missing neutral topic save path"
      grep -q 'latest/council-claude-p.md' "$file" || fail "$skill missing historical alias topic save path"
      ;;
    council-claude-p)
      grep -q 'latest/council-claude-p.md' "$file" || fail "$skill missing alias topic save path"
      ;;
  esac
  grep -q 'do not write `.agent-council/` paths through `--output`' "$file" || fail "$skill --output must not write Council paths"
  grep -q 'any `Bash(...)` pattern' "$file" || fail "$skill must warn on Bash allowed-tools"
  grep -q 'Council Peer P status: starting' "$file" || fail "$skill must announce starting status"
  grep -q 'Council Peer P status: running' "$file" || fail "$skill must provide running status updates"
  grep -q 'Council Peer P status: completed' "$file" || fail "$skill must announce completed status"
  grep -q 'Council Peer P status: timed out' "$file" || fail "$skill must announce timeout status"
  grep -q '15 to' "$file" || fail "$skill must define status update interval"
  grep -q 'Default timeout: 600 seconds (10 minutes)' "$file" || fail "$skill default timeout must be 600 seconds"
  grep -q 'Timeout: 600s' "$file" || fail "$skill status template must show 600s timeout"
  grep -q 'resume the original user-authorized work' "$file" || fail "$skill must continue the original authorized task after a clean peer check"
  grep -q 'Next action: resume original user-authorized work' "$file" || fail "$skill output must state whether it will continue or stop"
  grep -q '30 seconds' "$file" || fail "$skill diagnose ping should stay short"
  grep -q 'Whitespace-only input and punctuation-only input do not count as a prompt' "$file" || fail "$skill must ignore empty punctuation-only prompts"
  grep -q 'selected visible conversation rounds' "$file" || fail "$skill must use selected visible conversation rounds"
  grep -q 'Visible conversation context means user messages and Codex/Claude Code' "$file" || fail "$skill must define visible conversation context"
  grep -q 'system/developer instructions, tool schemas, hidden chain-of-thought' "$file" || fail "$skill must exclude hidden runtime context"
  grep -q 'bare `-n` or bare `--rounds`' "$file" || fail "$skill must define bare -n/--rounds"
  grep -q -- '--full' "$file" || fail "$skill must support --full"
  grep -q '`--diagnose` ignores `-n`, `--rounds`, `--full`' "$file" || fail "$skill diagnose must ignore round/full flags"
  grep -q 'Do not invent context' "$file" || fail "$skill must not invent missing context"
  grep -q -- '--diagnose' "$file" || fail "$skill must support diagnose mode"
  grep -q 'Council Peer P diagnose' "$file" || fail "$skill must define diagnose output"
  grep -q 'Reply with exactly: council-claude-p-ok' "$file" || fail "$skill diagnose must include claude ping prompt"
  grep -q 'Reply with exactly: council-peer-ok' "$file" || fail "$skill diagnose must include codex ping prompt"
  grep -q -- '--codex-sandbox' "$file" || fail "$skill must document codex sandbox"
  grep -q 'default `--codex-sandbox` is `read-only`' "$file" || fail "$skill codex default sandbox must be read-only"
  grep -q '`--output` and' "$file" || fail "$skill must treat --output as skill-local"
  grep -q 'do not pass them to `claude -p` or' "$file" || fail "$skill must not pass skill-local save options to peer CLI"
  grep -q 'non-zero exit code' "$file" || fail "$skill timeout output must include exit/stderr guidance"
  grep -q 'do not declare `CONSENSUS`' "$file" || fail "$skill must not declare consensus"
  grep -q 'Do not automatically trigger `council-apply`' "$file" || fail "$skill must not trigger council-apply"
}

assert_longrun_default_yaml() {
  file="$1"
  awk '
    /^## Default Mapping$/ { in_section = 1; next }
    in_section && /^```yaml$/ { in_yaml = 1; next }
    in_yaml && /^```$/ { exit }
    in_yaml {
      if ($0 ~ /^version: 3$/) saw_version = 1
      if ($0 ~ /^subagent_policy:/) saw_subagent = 1
      if ($0 ~ /^combined_assist_policy:/) saw_combined_policy = 1
      if ($0 ~ /^use_peer_p:/) saw_peer = 1
      if ($0 ~ /^use_both:/) saw_both = 1
      if ($0 ~ /^interruption_policy: not_configured_by_council_longrun$/) saw_interruption = 1
      if ($0 ~ /^(use_claude_p|claude_p_policy|human_pause_policy|pause_for_human|git_finalization):/) bad_legacy = 1
    }
    END {
      if (!saw_version || !saw_subagent || !saw_combined_policy || !saw_peer || !saw_both || !saw_interruption || bad_legacy) {
        exit 1
      }
    }
  ' "$file" || fail "council-longrun default YAML must use v3 assistance fields and must not write human pause/git policy"
}

required=(
  ".claude-plugin/marketplace.json"
  ".agents/plugins/marketplace.json"
  "plugins/agent-council/.claude-plugin/plugin.json"
  "plugins/agent-council/.codex-plugin/plugin.json"
  "README.md"
  "README.zh-CN.md"
  "SECURITY.md"
  "CONTRIBUTING.md"
  "CODE_OF_CONDUCT.md"
  ".github/ISSUE_TEMPLATE/bug_report.md"
  ".github/ISSUE_TEMPLATE/feature_request.md"
  ".github/PULL_REQUEST_TEMPLATE.md"
  "docs/RELEASE_AND_DISCOVERY.md"
  "VERSION"
)

for f in "${required[@]}"; do
  require_file "$f"
done

skills=(council council-open council-review council-apply council-status council-help council-version council-upgrade council-uninstall council-peer-p council-claude-p council-longrun)

for skill in "${skills[@]}"; do
  skill_file="$ROOT/plugins/agent-council/skills/$skill/SKILL.md"
  codex_file="$ROOT/plugins/agent-council/skills/$skill/agents/openai.yaml"

  [ -f "$skill_file" ] || fail "Missing skill: $skill"
  [ -f "$codex_file" ] || fail "Missing Codex metadata for skill: $skill"
  grep -q "plugins/agent-council/skills/$skill/SKILL.md" "$ROOT/FILES.md" || \
    fail "FILES.md missing SKILL.md entry for skill: $skill"
  grep -q "plugins/agent-council/skills/$skill/agents/openai.yaml" "$ROOT/FILES.md" || \
    fail "FILES.md missing Codex metadata entry for skill: $skill"
  assert_shell_skill_loop_contains "$ROOT/install.sh" "$skill" || \
    fail "install.sh does not install skill: $skill"
  assert_shell_skill_loop_contains "$ROOT/uninstall.sh" "$skill" || \
    fail "uninstall.sh does not remove skill: $skill"

  first_line="$(sed -n '1p' "$skill_file")"
  [ "$first_line" = "---" ] || fail "SKILL.md frontmatter must start with ---: $skill_file"
  sed -n '2,10p' "$skill_file" | grep -qx -- '---' || \
    fail "SKILL.md frontmatter must close with standalone --- in first 10 lines: $skill_file"

  frontmatter="$(skill_frontmatter "$skill_file")"
  ! printf '%s\n' "$frontmatter" | grep -qx 'disable-model-invocation: true' || \
    fail "Do not set disable-model-invocation: true; explicit skill invocation must remain visible: $skill_file"

  assert_codex_implicit_invocation_disabled "$codex_file"
done

[ -f "$ROOT/plugins/agent-council/skills/council-claude-p/SKILL.md" ] || \
  fail "Missing council-claude-p utility skill"
[ -f "$ROOT/plugins/agent-council/skills/council-claude-p/agents/openai.yaml" ] || \
  fail "Missing council-claude-p Codex metadata"
[ -f "$ROOT/plugins/agent-council/skills/council-peer-p/SKILL.md" ] || \
  fail "Missing council-peer-p utility skill"
[ -f "$ROOT/plugins/agent-council/skills/council-peer-p/agents/openai.yaml" ] || \
  fail "Missing council-peer-p Codex metadata"
[ -f "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" ] || \
  fail "Missing council-longrun skill"
[ -f "$ROOT/plugins/agent-council/skills/council-longrun/agents/openai.yaml" ] || \
  fail "Missing council-longrun Codex metadata"
[ -f "$ROOT/plugins/agent-council/skills/council-uninstall/SKILL.md" ] || \
  fail "Missing council-uninstall skill"
[ -f "$ROOT/plugins/agent-council/skills/council-uninstall/agents/openai.yaml" ] || \
  fail "Missing council-uninstall Codex metadata"

if [ -d "$ROOT/plugins/agent-council/skills/claude-p" ]; then
  fail "Deprecated claude-p skill directory must not remain; use council-peer-p or council-claude-p"
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
  grep -q 'allow_implicit_invocation: false' "$file" || fail "$readme missing implicit invocation guard explanation"
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
  grep -qi 'council-peer-p.*optional utility\|optional utility.*council-peer-p\|council-peer-p.*可选工具\|可选工具.*council-peer-p' "$file" || \
    fail "$readme must describe council-peer-p as an optional utility"
  grep -qi 'council-claude-p.*alias\|alias.*council-claude-p\|council-claude-p.*别名\|别名.*council-claude-p' "$file" || \
    fail "$readme must describe council-claude-p as a compatibility alias"
  grep -q 'council-peer-p' "$file" || \
    fail "$readme missing council-peer-p guidance"
  grep -qi 'no substantive text\|没有实质文字' "$file" || \
    fail "$readme missing peer-headless empty prompt fallback"
  grep -q 'conversation round' "$file" || \
    fail "$readme missing conversation round definition"
  grep -q -- '--rounds' "$file" || \
    fail "$readme missing --rounds guidance"
  grep -q -- '--full' "$file" || \
    fail "$readme missing --full guidance"
  grep -q 'latest/council-peer-p.md' "$file" || \
    fail "$readme missing council-peer-p topic save path"
  grep -q 'latest/council-claude-p.md' "$file" || \
    fail "$readme missing council-claude-p compatibility save path"
  grep -q -- '--diagnose' "$file" || \
    fail "$readme missing peer-headless diagnose guidance"
  grep -q '600 seconds\|600 秒' "$file" || \
    fail "$readme missing peer-headless 600 second timeout guidance"
  grep -q 'council-longrun' "$file" || \
    fail "$readme missing council-longrun guidance"
  grep -q '.agent-council/longrun/rules.md' "$file" || \
    fail "$readme missing longrun rules path"
done

assert_no_utility_in_range "$ROOT/README.md" '^## Commands$' '^## What It Solves$'
assert_no_utility_in_range "$ROOT/README.md" '^## Basic Workflow$' '^## Topic Ids$'
assert_no_utility_in_range "$ROOT/README.md" '^## Claude Code$' '^## Codex$'
assert_no_utility_in_range "$ROOT/README.md" '^## Codex$' '^## Basic Workflow$'
assert_no_utility_in_range "$ROOT/README.zh-CN.md" '^## 命令$' '^## 解决什么问题$'
assert_no_utility_in_range "$ROOT/README.zh-CN.md" '^## 基本流程$' '^## Topic Id$'
assert_no_utility_in_range "$ROOT/README.zh-CN.md" '^## Claude Code$' '^## Codex$'
assert_no_utility_in_range "$ROOT/README.zh-CN.md" '^## Codex$' '^## 基本流程$'
assert_no_utility_in_range "$ROOT/docs/USAGE.md" '^## Commands$' '^## Optional utility: council-peer-p$'
assert_no_utility_in_range "$ROOT/docs/USAGE.md" '^## Open a topic$' '^## Notes$'
assert_no_utility_in_range "$ROOT/docs/USAGE.zh-CN.md" '^## 命令$' '^## 可选工具：council-peer-p$'
assert_no_utility_in_range "$ROOT/docs/USAGE.zh-CN.md" '^## 开启话题$' '^## 说明$'

assert_peer_headless_skill council-claude-p
assert_peer_headless_skill council-peer-p
grep -q 'at most three short multiple-choice questions' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must use short choices"
grep -q 'Each option' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun options must explain behavior"
grep -q 'Use the user'"'"'s current language' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must localize option explanations"
grep -q 'Question Presentation Templates' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must include localized prompt templates"
grep -q 'three clearly separated groups' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must present grouped choices"
grep -q 'Markdown tables with options `A`' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must use A/B/C grouped tables"
grep -q 'Do not require a blocking modal' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must allow chat-based choice"
grep -q 'Subagents 辅助判断' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must label Chinese subagent strategy clearly"
grep -q 'Peer review / council-peer-p 辅助判断' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must label Chinese peer strategy clearly"
grep -q 'Combined assistance / subagents + council-peer-p' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must label combined assistance clearly"
grep -q 'Subagents assisted judgment' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must label English subagent strategy clearly"
grep -q 'Peer review / council-peer-p assisted judgment' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must label English peer strategy clearly"
grep -q '.agent-council/longrun/rules.md' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must write rules.md"
grep -q 'use subagents' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must define subagent use"
grep -q 'council-peer-p' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must define peer-p use"
grep -q 'use_both:' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must define combined assistance"
grep -q 'combined_assist_policy: high_risk' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun default must use high_risk combined assistance"
grep -q 'interruption_policy: not_configured_by_council_longrun' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must not configure interruption policy"
grep -q '^use_peer_p:' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun v2 schema must use use_peer_p"
! grep -q '^use_claude_p:' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun v2 schema must not write use_claude_p"
! grep -q '^human_pause_policy:' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must not write human_pause_policy"
! grep -q '^pause_for_human:' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must not write pause_for_human"
! grep -q '^git_finalization:' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must not write git_finalization"
grep -q 'does not configure when to interrupt the user' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must not own interruption timing"
grep -q 'continue execution' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must continue after clear assisted judgment"
grep -q 'version: 3' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun rules schema must be version 3"
grep -q 'Do not start long-run mode automatically' "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md" || fail "council-longrun must preserve manual boundary"
assert_longrun_default_yaml "$ROOT/plugins/agent-council/skills/council-longrun/SKILL.md"
grep -q 'default mix is `balanced` subagents, `strategic` peer' "$ROOT/docs/USAGE.md" || fail "docs/USAGE.md must explain longrun defaults"
grep -q '默认组合是 `balanced` subagents、`strategic`' "$ROOT/docs/USAGE.zh-CN.md" || fail "docs/USAGE.zh-CN.md must explain longrun defaults"
! grep -q 'irreversible operations' "$ROOT/README.md" || fail "README.md must not use vague irreversible operations wording"

grep -q 'lightweight, manual recent-round bridge' "$ROOT/README.md" || \
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
grep -q '60 Second Demo' "$ROOT/README.md" || fail "README.md missing 60 second demo"
grep -q '60 秒演示' "$ROOT/README.zh-CN.md" || fail "README.zh-CN.md missing 60 second demo"
grep -q 'Security Model' "$ROOT/README.md" || fail "README.md missing security model"
grep -q '安全模型' "$ROOT/README.zh-CN.md" || fail "README.zh-CN.md missing security model"
grep -q 'does not collect tokens' "$ROOT/SECURITY.md" || fail "SECURITY.md missing token boundary"
grep -q 'does not upload code' "$ROOT/SECURITY.md" || fail "SECURITY.md missing upload boundary"
grep -q 'does not automatically call Claude Code, Codex' "$ROOT/SECURITY.md" || fail "SECURITY.md missing auto-call boundary"
grep -q 'council-peer-p' "$ROOT/SECURITY.md" || fail "SECURITY.md missing optional peer utility boundary"
grep -q 'manual bridge' "$ROOT/CONTRIBUTING.md" || fail "CONTRIBUTING.md missing project scope"
grep -q 'Expected Behavior' "$ROOT/CODE_OF_CONDUCT.md" || fail "CODE_OF_CONDUCT.md missing expected behavior"
grep -q 'Manual Boundary' "$ROOT/.github/PULL_REQUEST_TEMPLATE.md" || fail "PR template missing manual boundary checklist"
grep -q 'GitHub Topics' "$ROOT/docs/RELEASE_AND_DISCOVERY.md" || fail "Release checklist missing GitHub topics"
grep -q 'Claude Plugin Directory Submission' "$ROOT/docs/RELEASE_AND_DISCOVERY.md" || fail "Release checklist missing Claude directory guidance"
grep -q 'Codex Marketplace And Community' "$ROOT/docs/RELEASE_AND_DISCOVERY.md" || fail "Release checklist missing Codex community guidance"
grep -q "Agent Council v$VERSION" "$ROOT/docs/USAGE.md" || fail "docs/USAGE.md version does not match VERSION"
grep -q "Agent Council v$VERSION" "$ROOT/docs/USAGE.zh-CN.md" || fail "docs/USAGE.zh-CN.md version does not match VERSION"
grep -q "Agent Council v$VERSION" "$ROOT/plugins/agent-council/skills/council-help/SKILL.md" || fail "council-help version does not match VERSION"
grep -q "Agent Council v$VERSION" "$ROOT/plugins/agent-council/skills/council-version/SKILL.md" || fail "council-version version does not match VERSION"

grep -q -- '--doctor' "$ROOT/plugins/agent-council/skills/council-status/SKILL.md" || fail "council-status missing --doctor"
grep -q 'Side effects' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review missing Side effects"
grep -q 'Verdict: {state}' "$ROOT/plugins/agent-council/skills/council-review/SKILL.md" || fail "council-review missing compact verdict-first output"
grep -q 'maximum 500 words' "$ROOT/plugins/agent-council/skills/council-open/SKILL.md" || fail "council-open missing handoff size budget"
grep -q 'bare `-n` or bare `--rounds`' "$ROOT/plugins/agent-council/skills/council-open/SKILL.md" || fail "council-open must define bare -n/--rounds"
grep -q 'system/developer instructions, tool schemas, hidden chain-of-thought' "$ROOT/plugins/agent-council/skills/council-open/SKILL.md" || fail "council-open must exclude hidden runtime context"
grep -q -- '--full' "$ROOT/plugins/agent-council/skills/council-open/SKILL.md" || fail "council-open must support --full"
grep -q 'open-full-context.md' "$ROOT/plugins/agent-council/skills/council-open/SKILL.md" || fail "council-open --full must write a full-context attachment"
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
grep -q 'council-longrun' "$ROOT/docs/PROTOCOL.md" || fail "PROTOCOL.md missing council-longrun boundary"
grep -q '.agent-council/longrun/rules.md' "$ROOT/docs/PROTOCOL.md" || fail "PROTOCOL.md missing longrun rules path"
grep -q 'council-longrun' "$ROOT/docs/PROTOCOL.zh-CN.md" || fail "PROTOCOL.zh-CN.md missing council-longrun boundary"
grep -q '.agent-council/longrun/rules.md' "$ROOT/docs/PROTOCOL.zh-CN.md" || fail "PROTOCOL.zh-CN.md missing longrun rules path"
grep -q 'Default behavior is read-only' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade must be check-only by default"
grep -q 'only when the user includes `--apply`' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade must require --apply for install changes"
grep -q 'Do not treat `--ref` by itself as permission to upgrade' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade must not let --ref imply apply"
grep -q 'Do not treat `--force` by itself as permission to upgrade' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade must not let --force imply apply"
grep -q -- '--ref {git_ref}' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade missing --ref guidance"
grep -q -- '--apply --force' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade missing force apply guidance"
grep -q 'claude-p' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade must mention deprecated claude-p cleanup"
grep -q 'council-peer-p` and the compatibility' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade must explain claude-p replacement"
grep -q 'dirty installs' "$ROOT/plugins/agent-council/skills/council-upgrade/SKILL.md" || fail "council-upgrade must define force dirty install cleanup"
grep -q -- '--force' "$ROOT/install.sh" || fail "install.sh missing --force support"
grep -q 'Required skill missing after install' "$ROOT/install.sh" || fail "install.sh must verify required replacement skills"
grep -q 'council-peer-p council-claude-p' "$ROOT/install.sh" || fail "install.sh must verify peer replacement skills"
grep -q -- 'council-upgrade --apply' "$ROOT/plugins/agent-council/skills/council-version/SKILL.md" || fail "council-version must recommend explicit apply upgrade"
grep -q -- 'council-upgrade --apply' "$ROOT/README.md" || fail "README.md missing explicit apply upgrade example"
grep -q -- 'council-upgrade --apply' "$ROOT/README.zh-CN.md" || fail "README.zh-CN.md missing explicit apply upgrade example"
grep -q -- 'council-upgrade --apply --force' "$ROOT/README.md" || fail "README.md missing force apply upgrade example"
grep -q -- 'council-upgrade --apply --force' "$ROOT/README.zh-CN.md" || fail "README.zh-CN.md missing force apply upgrade example"
grep -q -- '--ref {git_ref}' "$ROOT/README.md" || fail "README.md missing optional ref guidance"
grep -q -- '--ref {git_ref}' "$ROOT/README.zh-CN.md" || fail "README.zh-CN.md missing optional ref guidance"
grep -q 'Default behavior is read-only' "$ROOT/plugins/agent-council/skills/council-uninstall/SKILL.md" || fail "council-uninstall must be check-only by default"
grep -q 'only when the user includes `--apply`' "$ROOT/plugins/agent-council/skills/council-uninstall/SKILL.md" || fail "council-uninstall must require --apply for deletion"
grep -q 'codex plugin remove agent-council@agent-council-marketplace' "$ROOT/plugins/agent-council/skills/council-uninstall/SKILL.md" || fail "council-uninstall missing Codex plugin remove guidance"
grep -q -- '--remove-state' "$ROOT/plugins/agent-council/skills/council-uninstall/SKILL.md" || fail "council-uninstall missing state removal guard"
grep -q -- '--apply' "$ROOT/uninstall.sh" || fail "uninstall.sh missing --apply support"
grep -q 'Dry run done' "$ROOT/uninstall.sh" || fail "uninstall.sh must be dry-run by default"
grep -q -- 'council-uninstall --check' "$ROOT/README.md" || fail "README.md missing uninstall check example"
grep -q -- 'council-uninstall --check' "$ROOT/README.zh-CN.md" || fail "README.zh-CN.md missing uninstall check example"

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
