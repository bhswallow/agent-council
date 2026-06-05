---
name: council-longrun
description: Configure explicit long-run self-review rules for Agent Council guardrails.
disable-model-invocation: true
---

# Council Longrun

Arguments:
`[--show|--reset]`

Examples:
- `$council-longrun`
- `/council-longrun`
- `$council-longrun --show`

## Purpose

`council-longrun` configures a user-approved long-run rule set. It tells future
work when to continue by self-judgment, when to use subagents, when to use
`council-peer-p` / `council-claude-p`, when to use both, and when to pause for a human decision.

This skill does not run the long task by itself. It only records the rules the
user chose and returns a compact summary. Future work may follow those rules
until the user runs `council-longrun` again to redefine them.

Manual invocation boundary:

- Run only when the user explicitly invokes `council-longrun`.
- Do not start long-run mode automatically.
- Do not invoke `council-peer-p` or `council-claude-p` while configuring rules.
- Do not spawn subagents while configuring rules.
- Do not modify formal project files.
- Do not commit, push, merge, deploy, or enter the next workflow stage.

## Storage

Write the active rules to:

```text
.agent-council/longrun/rules.md
```

Also append a compact history entry to:

```text
.agent-council/longrun/history.md
```

Do not create a normal Council topic. Do not write under
`.agent-council/active/` unless the user separately invokes `council-open`.

Use the user's current language for prompts and summaries when clear.

## Interaction

If the user passes `--show`, read and summarize the current rules. If no rules
exist, say none are configured.

If the user passes `--reset`, remove or mark the current rules disabled if tool
access allows. If deletion is unavailable, overwrite `rules.md` with:

```yaml
enabled: false
```

For normal invocation, ask at most three short multiple-choice questions.
Prefer recommended defaults. Keep the questions short.

### Question 1: Longrun Mode

Recommended default: `balanced`.

Choices:

- `balanced`: self-judge Green work; use subagents for Yellow; use both
  subagents and `council-peer-p` for important Red; pause for human gates.
- `fast`: self-judge Green and most Yellow; use subagents only for clear Red;
  pause mostly for irreversible operations.
- `strict`: use subagents for Yellow; use both for most Red; pause more often.

### Question 2: Peer-p Use

Recommended default: `strategic`.

Choices:

- `strategic`: use `council-peer-p` for design, plan, release readiness,
  security boundary, and major tradeoff checks.
- `implementation`: also use `council-peer-p` for cross-module
  implementation risk, complex diffs, and weak test coverage.
- `manual`: do not automatically use `council-peer-p`; only use it when the
  user explicitly asks. `council-claude-p` remains accepted as a compatibility alias.

### Question 3: Human Pause

Recommended default: `irreversible`.

Choices:

- `irreversible`: pause for commit, push, merge, deploy, deleting data,
  permission/security changes, accepting blockers, expanding scope, or other
  irreversible risk.
- `product`: also pause for product tradeoffs, UX direction, or option A/B
  decisions.
- `strict`: pause for any Red tripwire or uncertain requirement.

## Default Mapping

After choices are made, write a rules file with this shape:

```yaml
enabled: true
version: 1
configured_at: {iso8601_utc_timestamp}
mode: balanced|fast|strict
claude_p_policy: strategic|implementation|manual
human_pause_policy: irreversible|product|strict
applies_until: redefined_by_council_longrun
self_continue:
  - green_tasks_within_approved_plan
  - local_refactors_with_tests
  - docs_or_tests_with_low_risk
use_subagents:
  - yellow_tasks
  - cross_file_changes
  - unclear_test_coverage
  - implementation_risk
use_claude_p:
  - design_to_plan
  - plan_to_implementation
  - release_readiness
  - security_or_permission_boundary
  - major_tradeoff
use_both:
  - high_risk_architecture
  - blocker_resolution
  - broad_scope_change
  - pre_release_review
pause_for_human:
  - commit
  - push
  - merge
  - deploy
  - data_loss_risk
  - security_boundary_change
  - accept_blocker
  - expand_scope
```

Adapt the lists to the selected choices:

- For `fast`, move mild Yellow tasks to `self_continue` and keep
  `use_claude_p` narrower.
- For `strict`, move more Yellow and Red items into `use_subagents`,
  `use_both`, and `pause_for_human`.
- For `claude_p_policy: manual`, keep `use_claude_p` and `use_both` empty
  unless the user explicitly asks.
- For `claude_p_policy: implementation`, add cross-module implementation risk,
  complex diff review, and weak-test-coverage review to `use_claude_p`.
- For `human_pause_policy: product`, add product tradeoffs, UX direction, and
  option selection to `pause_for_human`.
- For `human_pause_policy: strict`, add any Red tripwire and uncertain
  requirements to `pause_for_human`.

## User-Facing Response

Keep the final response short:

```text
Longrun rules configured.

Mode: balanced
Claude-p: strategic / high-risk only
Human pause: irreversible gates

Saved:
- .agent-council/longrun/rules.md
- .agent-council/longrun/history.md

Side effects:
- Council files modified: longrun rules only
- Formal project files modified: none
```

Do not say that Council will automatically start tasks. Say these rules apply
only when the user has already authorized ongoing work.
