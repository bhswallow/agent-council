---
name: council-longrun
description: Configure when long-running work uses subagents, council-peer-p, or both for assisted judgment.
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

`council-longrun` configures a user-approved assistance policy for future
authorized long-running work. It tells future work when to use subagents, when
to use `council-peer-p` (or its compatibility alias `council-claude-p`), and
when to use both together before continuing.

This skill does not decide when work must interrupt the user. It does not
configure human-pause or git-finalization policy. Instead, when the surrounding
workflow would otherwise stop because it needs judgment, tradeoff analysis, or
extra confidence, these rules tell the agent which assistance to run first. If
the assisted judgment produces a clear recommendation within the user's
authorized scope and no external hard gate applies, continue execution.
In short, `council-longrun` does not configure when to interrupt the user.

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
- Do not add new human gates. Do not remove external hard gates required by the
  user, system, tool policy, credentials, sandbox, or deployment process.

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

Present the choices as three clearly separated groups, not as one continuous
numbered list. In plain chat, use compact Markdown tables with options `A`,
`B`, and `C` inside each group. If the host UI supports tabs, segmented
controls, or another nonblocking grouped chooser, it is acceptable to show one
tab/group per setting. Do not require a blocking modal or pause the chat just
to collect choices; ask in the chat and let the user reply normally.

Do not present bare tokens such as only `balanced / light / thorough`. Do not
label Group 2 as "Claude-p usage" or `Claude-p 使用策略`; label it as peer review
or `council-peer-p` strategy. Each option must say what it controls in concrete
terms:

- when subagents are used for local or technical judgment;
- when `council-peer-p` is used for independent peer judgment;
- when subagents and `council-peer-p` are used together;
- that assisted judgment should continue automatically when clear and within
  the user-authorized scope;
- that `council-longrun` does not configure human-pause or git-finalization
  policy.

Accept the exact option value, `A`/`B`/`C` within each group, a compact reply
such as `A A A`, a key-value reply such as
`subagents=balanced peer=strategic both=high_risk`, or a localized default
reply such as `default` / `默认`.

### Question Presentation Templates

Use the user's current language. The exact wording can be shorter, but it must
explain the behavior of every option.

Chinese template:

```text
我会按 `council-longrun` 配置“辅助判断”规则，不配置什么时候打断你。
请在 chat 里回复 3 个选择；接受默认可直接回复“默认”。
也可以回复：`subagents=balanced peer=strategic both=high_risk`。

**Group 1: Subagents 辅助判断**
控制什么时候先让 subagents 做本地/技术判断；判断清楚后继续。推荐：`balanced`

| 选项 | 等级 | 行为 |
| --- | --- | --- |
| A | `balanced` 推荐 | 中等不确定、跨文件、覆盖不清、实现路径不确定时用 subagents；低风险已授权工作直接继续。 |
| B | `light` | 只在明显复杂或不清楚时用 subagents；更依赖当前 agent 自己判断。 |
| C | `thorough` | 多数非平凡实现、测试策略、数据/并发/集成风险都先用 subagents 判断。 |

**Group 2: Peer review / council-peer-p 辅助判断**
控制什么时候跑对方 headless review；判断清楚后继续。推荐：`strategic`

| 选项 | 等级 | 行为 |
| --- | --- | --- |
| A | `strategic` 推荐 | design、plan、发布前、安全/权限边界、重大取舍时跑 council-peer-p。 |
| B | `implementation` | 除 strategic 场景外，复杂 diff、跨模块实现、弱覆盖、并发/数据安全也跑 council-peer-p。 |
| C | `manual` | 不自动跑 council-peer-p；只有你明确要求时才跑。 |

**Group 3: Combined assistance / subagents + council-peer-p**
控制什么时候两种辅助一起用；用于原本可能需要人工判断的复杂点，结论清楚后继续。推荐：`high_risk`

| 选项 | 等级 | 行为 |
| --- | --- | --- |
| A | `high_risk` 推荐 | 架构/发布/安全边界/blocker/重大取舍/大范围变更时同时用 subagents + council-peer-p。 |
| B | `escalation` | 先用单一路线；只有 subagents 或 peer 发现未解决风险、意见冲突、证据不足时再两者一起用。 |
| C | `intensive` | 对多数跨模块、弱覆盖、数据迁移、并发、复杂回滚风险都同时用两者。 |
```

English template:

```text
I will configure `council-longrun` assisted-judgment rules, not human interruption rules.
Reply in chat with 3 choices; reply `default` to accept the defaults.
You can also reply: `subagents=balanced peer=strategic both=high_risk`.

**Group 1: Subagents assisted judgment**
Controls when to ask subagents for local/technical judgment; continue when the result is clear. Recommended: `balanced`

| Option | Level | Behavior |
| --- | --- | --- |
| A | `balanced` recommended | Use subagents for moderate uncertainty, cross-file changes, unclear coverage, or uncertain implementation paths; continue low-risk approved work directly. |
| B | `light` | Use subagents only for clearly complex or unclear work; rely more on the current agent's judgment. |
| C | `thorough` | Use subagents for most non-trivial implementation, test strategy, data/concurrency, or integration risk. |

**Group 2: Peer review / council-peer-p assisted judgment**
Controls when to run the peer headless review; continue when the result is clear. Recommended: `strategic`

| Option | Level | Behavior |
| --- | --- | --- |
| A | `strategic` recommended | Use council-peer-p for design, plan, pre-release, security/permission boundary, or major tradeoff checks. |
| B | `implementation` | Also use council-peer-p for complex diffs, cross-module implementation risk, weak coverage, concurrency, or data safety. |
| C | `manual` | Never use council-peer-p automatically; use it only when the user explicitly asks. |

**Group 3: Combined assistance / subagents + council-peer-p**
Controls when to use both kinds of assistance; use it for complex points that might otherwise need human judgment, then continue when clear. Recommended: `high_risk`

| Option | Level | Behavior |
| --- | --- | --- |
| A | `high_risk` recommended | Use both for architecture, release, security boundary, blocker resolution, major tradeoffs, or broad scope changes. |
| B | `escalation` | Start with one route; use both only when subagents or peer review finds unresolved risk, conflicting judgment, or insufficient evidence. |
| C | `intensive` | Use both for most cross-module, weak-coverage, migration, concurrency, or complex rollback-risk work. |
```

### Question 1: Subagents Assisted Judgment

Recommended default: `balanced`.

This question controls when to ask subagents for local or technical judgment.
It does not authorize new scope, formal project changes outside the requested
work, or git finalization.

Choices:

- `balanced`: default. Continue low-risk approved work directly. Use subagents
  for moderate ambiguity, cross-file changes, unclear test coverage, uncertain
  implementation paths, unfamiliar code ownership, or local design choices.
- `light`: more autonomous. Use subagents only for clearly complex, unclear, or
  risky local work. This saves time but relies more on the current agent's
  judgment.
- `thorough`: more review checkpoints. Use subagents for most non-trivial
  implementation choices, test strategy, data/concurrency risk, integration
  risk, and broad refactors.

### Question 2: Peer Review / council-peer-p Assisted Judgment

Recommended default: `strategic`.

This question controls when the optional peer-headless utility runs. It does
not start tasks and does not modify formal project files.

Choices:

- `strategic`: use `council-peer-p` for design, plan, release readiness,
  security/privacy/permission boundary, and major tradeoff checks. Do not use
  it for ordinary small code, docs, or test edits.
- `implementation`: also use `council-peer-p` for complex diffs, cross-module
  implementation risk, weak test coverage, concurrency/data safety, migrations,
  or broad refactors.
- `manual`: do not automatically use `council-peer-p`; only use it when the
  user explicitly asks. `council-claude-p` remains accepted as a compatibility
  alias.

### Question 3: Combined Assistance

Recommended default: `high_risk`.

This question controls when to use both subagents and `council-peer-p` together
before continuing.

Choices:

- `high_risk`: default. Use both for high-risk architecture, release readiness,
  security/privacy/permission boundaries, blocker resolution, major product or
  technical tradeoffs, broad scope changes, and hard-to-reverse implementation
  choices.
- `escalation`: start with the narrower route from Question 1 or Question 2.
  Use both only when the first route reports unresolved risk, conflicting
  recommendations, insufficient evidence, or a blocker.
- `intensive`: use both for most cross-module implementation, weak test
  coverage, migrations, concurrency/data safety, complex rollback risk, and
  broad refactors.

## Default Mapping

After choices are made, write a rules file with this shape:

```yaml
enabled: true
version: 3
configured_at: {iso8601_utc_timestamp}
subagent_policy: balanced|light|thorough
peer_review_policy: strategic|implementation|manual
combined_assist_policy: high_risk|escalation|intensive
applies_until: redefined_by_council_longrun
interruption_policy: not_configured_by_council_longrun
judgment_flow:
  when_existing_workflow_would_ask_for_judgment: assist_then_continue
  continue_after_assist_when:
    - recommendation_is_clear
    - action_is_within_user_authorized_scope
    - checks_pass_or_next_check_is_defined
    - no_external_hard_gate_applies
use_subagents:
  - moderate_ambiguity
  - cross_file_changes
  - unclear_test_coverage
  - uncertain_implementation_path
  - local_design_choice
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
  - hard_to_reverse_choice
  - pre_release_review
hard_gates_not_owned_by_longrun:
  - explicit_user_request_to_choose_or_pause
  - credentials_or_auth_required
  - external_approval_required
  - destructive_or_public_side_effect_not_authorized
  - tool_policy_or_sandbox_requires_user_approval
```

Adapt the lists to the selected choices:

- For `light`, keep `use_subagents` narrower and let more low/moderate work
  continue by current-agent judgment.
- For `thorough`, add more implementation, test strategy, integration, and
  refactor cases to `use_subagents`.
- For `peer_review_policy: manual`, keep `use_peer_p` empty and only use
  `council-peer-p` when the user explicitly asks. Because combined assistance
  includes peer review, also avoid automatic `use_both` unless the user
  explicitly asks.
- For `peer_review_policy: implementation`, add complex diff review,
  cross-module implementation risk, weak-test-coverage review, migrations, and
  data/concurrency safety to `use_peer_p`.
- For `combined_assist_policy: escalation`, keep `use_both` focused on
  unresolved risk, conflicting recommendations, insufficient evidence, and
  blockers after a narrower route has run.
- For `combined_assist_policy: intensive`, add cross-module implementation,
  weak coverage, migrations, data/concurrency safety, broad refactors, and
  rollback risk to `use_both`.

Compatibility:

- If showing an older rules file with `version: 1`, `version: 2`,
  `claude_p_policy`, `use_claude_p`, `human_pause_policy`,
  `pause_for_human`, or `git_finalization`, explain that this is a legacy rule
  set.
- New rules must use `version: 3`, `subagent_policy`, `peer_review_policy`,
  `combined_assist_policy`, and `use_peer_p`.
- New rules must not write human-pause or git-finalization policy. Interruption
  timing belongs to the surrounding workflow and hard gates, not
  `council-longrun`.

## User-Facing Response

Keep the final response short:

```text
Longrun assistance rules configured.

Subagents: balanced
- Use subagents for moderate ambiguity, cross-file changes, unclear coverage, or uncertain implementation paths.

Peer review: strategic
- Use council-peer-p for design, plan, release, security, or major tradeoff checks.

Combined assistance: high_risk
- Use subagents + council-peer-p for architecture, blockers, release/security boundaries, broad scope changes, or hard-to-reverse choices.

Continue behavior:
- If a workflow would otherwise ask for judgment, run the configured assistance first.
- Continue automatically when the assisted recommendation is clear and inside the user-authorized scope.

Saved:
- .agent-council/longrun/rules.md
- .agent-council/longrun/history.md

Side effects:
- Council files modified: longrun assistance rules only
- Formal project files modified: none
```

Do not say that Council will automatically start tasks. Say these rules apply
only when the user has already authorized ongoing work.
