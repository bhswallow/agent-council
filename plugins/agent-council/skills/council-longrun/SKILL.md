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
`council-peer-p` (or its compatibility alias `council-claude-p`), when to use
both peer review and subagents, and exactly which human checkpoints should stop
execution.

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
Prefer recommended defaults. Use the user's current language for the questions,
option labels, option explanations, and final summary when clear.

Do not present bare tokens such as only `balanced / fast / strict`. Do not label
Question 2 as "Claude-p usage" or `Claude-p 使用策略`; label it as peer review
or `council-peer-p` strategy. Each option must say what it controls in concrete
terms:

- what future work may continue without asking again;
- when subagents are used;
- when `council-peer-p` is used;
- when execution pauses for the user;
- whether normal git finalization can proceed.

Accept the exact option value, the option number, or a localized default reply
such as `default` / `默认`.

### Question Presentation Templates

Use the user's current language. The exact wording can be shorter, but it must
explain the behavior of every option.

Chinese template:

```text
我会按 `council-longrun` 配置规则。请选择 3 项；如果接受默认，回复“默认”即可。

1. Longrun Mode / 复审强度（控制后续任务能多自主、何时用 subagents；不控制 git 收尾）
推荐：balanced
1) balanced（推荐）：低风险的已授权工作可继续；中等不确定、跨文件、覆盖不清时用 subagents；高风险架构、发布、安全/权限边界或 blocker 解决时同时用 subagents + council-peer-p。
2) fast：更自主；低/中风险已授权工作在检查通过后继续；只有明显高风险或很不清楚时才用 subagents，较少用 council-peer-p。
3) strict：更谨慎；多数非平凡改动都先用 subagents，高风险多用 council-peer-p；需求、风险、owner、测试覆盖不清时更容易停下来问你。

2. Peer review / council-peer-p 使用策略（控制是否主动跑对方 headless review；不会启动任务或改文件）
推荐：strategic
1) strategic（推荐）：只在设计、计划、发布前、安全/权限边界、重大取舍时用 council-peer-p。
2) implementation：除 strategic 场景外，跨模块实现风险、复杂 diff、测试覆盖弱、并发/数据安全、较大重构也会用 council-peer-p。
3) manual：不会自动用 council-peer-p；只有你明确要求时才用。

3. Human pause / Git 收尾策略（控制什么时候必须停下来等你；也控制普通 add/commit/push 是否会卡住）
推荐：git_safe
1) git_safe（推荐）：如果你已经要求 git 收尾且检查通过，可继续精确 add 目标文件、commit、push 到目标 branch/remote；force-push、merge/rebase、release/deploy、删除数据/分支、宽泛 git add .、权限/安全变更、未解决 blocker、扩大 scope、branch/remote 不清楚、未授权 git 操作仍会暂停。
2) product：包含 git_safe；另外产品取舍、UX 方向、影响业务行为、A/B 选项也会暂停问你。
3) strict：任何高风险或需求不清都暂停；commit/push 也会问，除非本轮请求已经明确授权了对应 git 操作。
```

English template:

```text
I will configure `council-longrun` rules. Pick 3 options; reply `default` to accept the defaults.

1. Longrun Mode / Review intensity (controls autonomy and subagent use; does not control git finalization)
Recommended: balanced
1) balanced (recommended): continue low-risk approved work; use subagents for moderate ambiguity, cross-file changes, or unclear coverage; use subagents + council-peer-p for high-risk architecture, release, security/permission boundaries, or blocker resolution.
2) fast: more autonomous; continue low/medium-risk approved work after checks pass; use subagents only for clearly high-risk or unclear work, and use council-peer-p rarely.
3) strict: more cautious; use subagents for most non-trivial changes, use council-peer-p for high-risk work, and pause more often when requirements, risk, ownership, or test coverage are unclear.

2. Peer review / council-peer-p strategy (controls whether to run the peer headless review; does not start tasks or edit files)
Recommended: strategic
1) strategic (recommended): use council-peer-p only for design, plan, pre-release, security/permission boundary, or major tradeoff checks.
2) implementation: also use council-peer-p for cross-module implementation risk, complex diffs, weak coverage, concurrency/data safety, or broad refactors.
3) manual: never use council-peer-p automatically; use it only when the user explicitly asks.

3. Human pause / Git finalization (controls when execution must stop for the user; also controls whether normal add/commit/push gets stuck)
Recommended: git_safe
1) git_safe (recommended): if the user requested git finalization and checks passed, continue with precise add of intended files, commit, and push to the intended branch/remote; pause for force-push, merge/rebase, release/deploy, deleting data/branches, broad git add ., permission/security changes, unresolved blockers, scope expansion, unclear branch/remote, or unauthorized git operations.
2) product: includes git_safe; also pause for product tradeoffs, UX direction, business-impacting behavior, or A/B choices.
3) strict: pause for any high-risk or unclear requirement; also ask before commit/push unless this turn explicitly authorized the exact git operation.
```

### Question 1: Longrun Mode / Review Intensity

Recommended default: `balanced`.

This question controls review intensity. It does not by itself authorize new
scope, formal project changes outside the requested work, or git finalization;
git finalization is controlled by Question 3.

Choices:

- `balanced`: default. Continue low-risk work inside the approved task, such as
  small docs/tests/local refactors after checks pass. Use subagents for
  moderate ambiguity, cross-file changes, or unclear test coverage. Use both
  subagents and `council-peer-p` for high-risk architecture, release readiness,
  security/privacy boundaries, or blocker resolution.
- `fast`: more autonomous. Continue low- and medium-risk approved work after
  checks pass. Use subagents only for clearly high-risk or unclear work. Use
  `council-peer-p` rarely. This saves time but relies more on self-judgment.
- `strict`: more checkpoints. Use subagents for most non-trivial work. Use
  `council-peer-p` for most high-risk work. Pause more often when requirements,
  risk, ownership, or test coverage are unclear.

### Question 2: Peer Review Strategy

Recommended default: `strategic`.

This question controls when the optional peer-headless utility runs. It does
not start tasks and does not modify formal project files.

Choices:

- `strategic`: use `council-peer-p` for design, plan, release readiness,
  security/privacy/permission boundary, and major tradeoff checks. Do not use
  it for ordinary small code, docs, or test edits.
- `implementation`: also use `council-peer-p` for cross-module
  implementation risk, complex diffs, weak test coverage, concurrency/data
  safety, or broad refactors.
- `manual`: do not automatically use `council-peer-p`; only use it when the
  user explicitly asks. `council-claude-p` remains accepted as a compatibility alias.

### Question 3: Human Pause / Git Finalization

Recommended default: `git_safe`.

This question controls when to stop and ask the user. The recommended default
is designed so normal requested git finishing does not get stuck.

Choices:

- `git_safe`: normal user-authorized git finalization may continue after checks
  pass: precise `git add` of intended files, `git commit`, and `git push` to
  the intended branch/remote. Pause for force-push, merge, rebase, release,
  deploy, deleting data, deleting branches, broad `git add .`, secrets,
  permission/security changes, accepting unresolved blockers, expanding scope,
  unclear branch/remote, or any operation the user did not authorize.
- `product`: same as `git_safe`, and also pause for product tradeoffs, UX
  direction, business-impacting behavior changes, or option A/B decisions.
- `strict`: pause for any high-risk tripwire or uncertain requirement. Also ask
  before commit or push unless the user explicitly authorized that exact git
  operation in the current request.

## Default Mapping

After choices are made, write a rules file with this shape:

```yaml
enabled: true
version: 2
configured_at: {iso8601_utc_timestamp}
mode: balanced|fast|strict
peer_review_policy: strategic|implementation|manual
human_pause_policy: git_safe|product|strict
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
use_peer_p:
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
git_finalization:
  normal_commit_push: allowed_when_user_requested_and_checks_pass
  allowed:
    - precise_git_add_of_intended_files
    - commit_after_checks_pass
    - push_to_intended_branch_after_commit
  pause_for:
    - force_push
    - merge
    - rebase
    - release
    - deploy
    - delete_branch
    - broad_git_add_dot
    - unclear_branch_or_remote
pause_for_human:
  - data_loss_risk
  - security_boundary_change
  - accept_blocker
  - expand_scope
```

Adapt the lists to the selected choices:

- For `fast`, move mild Yellow tasks to `self_continue` and keep `use_peer_p`
  narrower.
- For `strict`, move more Yellow and Red items into `use_subagents`,
  `use_both`, and `pause_for_human`.
- For `peer_review_policy: manual`, keep `use_peer_p` and `use_both` empty
  unless the user explicitly asks.
- For `peer_review_policy: implementation`, add cross-module implementation risk,
  complex diff review, and weak-test-coverage review to `use_peer_p`.
- For `human_pause_policy: product`, add product tradeoffs, UX direction, and
  option selection to `pause_for_human`.
- For `human_pause_policy: strict`, add any Red tripwire and uncertain
  requirements to `pause_for_human`; set `git_finalization.normal_commit_push`
  to `ask_before_commit_or_push_unless_current_request_explicitly_authorized`.

Compatibility:

- If showing an older rules file with `version: 1`, `claude_p_policy`,
  `use_claude_p`, or `human_pause_policy: irreversible`, explain that this is a
  legacy rule set.
- Legacy `irreversible` paused for normal `commit` and `push`, which can make
  git finishing feel stuck. Recommend rerunning `council-longrun` to migrate to
  `git_safe`.
- When writing new rules, use `version: 2`, `peer_review_policy`, and
  `use_peer_p`. Use `human_pause_policy: git_safe` as the default and legacy
  migration target; if the user selected `product` or `strict`, write that
  selected value.

## User-Facing Response

Keep the final response short:

```text
Longrun rules configured.

Mode: balanced
- Continue low-risk approved work; use subagents for moderate risk; use peer review for high-risk checkpoints.

Peer review: strategic
- Use council-peer-p for design, plan, release, security, or major tradeoff checks only.

Human pause / Git: git_safe
- Normal requested add/commit/push may continue after checks pass.
- Pause for force-push, merge/rebase, deploy/release, data loss, security boundary changes, broad staging, or unclear branch/remote.

Saved:
- .agent-council/longrun/rules.md
- .agent-council/longrun/history.md

Side effects:
- Council files modified: longrun rules only
- Formal project files modified: none
```

Do not say that Council will automatically start tasks. Say these rules apply
only when the user has already authorized ongoing work.
