# Protocol

Agent Council v2 uses a recent-round bridge model.

## Manual invocation boundary

Council is human-invoked. It must not automatically stop tasks, create topics,
or insert itself into normal task flow.

If a human interaction point appears, the surrounding workflow should pause for
that human gate first. The user may manually choose to run Council, but Council
must not decide that it is required.

When a topic finishes, Council does not chain into the next task. Control
returns to the normal user/tool workflow.

`council-longrun` is a narrow exception only because the user explicitly invokes
it to record long-run assisted-judgment rules. It does not start tasks, create
normal Council topics, commit, push, merge, deploy, add human gates, remove
human gates, or bypass external hard gates.

## Longrun rules

`council-longrun` configures assisted-judgment rules for future
user-authorized ongoing work.

It asks a few short choices and writes:

    .agent-council/longrun/rules.md
    .agent-council/longrun/history.md

The rules may tell future work when to use:

- subagents for local or technical judgment;
- `council-peer-review` for independent peer judgment;
- both subagents and `council-peer-review` for complex or high-risk judgment.

The rules must not configure when to interrupt the user. Interruption timing
belongs to the surrounding workflow, user instructions, tool policy,
credentials, sandbox, deployment process, or other external hard gates.

When the surrounding workflow would otherwise ask for judgment, the configured
assistance should run first. If the assisted recommendation is clear, the next
action stays inside the user's authorized scope, and no external hard gate
applies, continue execution.

New rules use `version: 3`, `subagent_policy`, `peer_review_policy`,
`combined_assist_policy`, `use_subagents`, `use_peer_p`, and `use_both`.
Legacy fields such as `human_pause_policy`, `pause_for_human`, or
`git_finalization` should be treated as older rule sets.

The rules apply only after the user has authorized ongoing work. They do not
authorize new scope, formal project changes outside the task, dangerous git,
release, deploy, data-loss, public side effects, credential access, or
security-boundary operations. Running `council-longrun` again redefines the
rules.

## Peer headless utility

`council-peer-review` is the optional one-shot peer headless utility.

From Codex, the utility calls Claude Code through `claude -p`. From Claude Code,
it calls Codex through `codex exec --sandbox read-only`.

The utility is not part of the Council review loop. It does not declare
consensus, trigger `council-apply`, or write Council topics by default. It must
use only selected visible context or explicit user-provided context.

## Optional reminders outside Council

Outer workflow instructions may remind the user that Council is available after
brainstorming, design, plans, specs, a completed task batch, or a blocker.

The reminder must be brief, optional, and written in the user's current
language. It must not invoke Council, stop the workflow, or imply that Council
is required. If the user does not ask for Council, continue under the approved
workflow.

## Workspace

All runtime state lives under:

    .agent-council/active/{topic_id}/

Recommended files:

    topic.md
    status.md
    latest/codex.md
    latest/claude.md
    latest/for-peer.md
    latest/user-request.md
    turns/0001-codex-open.md
    turns/0002-claude-review.md
    consensus.md
    applied/0003-apply.md

Agent ids are canonical lowercase. Valid built-in ids are `claude` and `codex`. Paths must use lowercase agent ids only.

## Conversation rounds

A conversation round is one user message plus the immediately following Codex
or Claude Code assistant response. If the latest visible user message does not
yet have an assistant response, it is an unfinished round.

This is different from Council `turns/`, which are compact files that record
one Council command output from one agent.

Only visible user/assistant chat text is eligible for range selection. Do not
include system/developer instructions, tool schemas, hidden chain-of-thought,
or other internal runtime context.

For commands that accept context ranges:

- no `-n` / `--rounds`: select the latest 1 visible conversation round;
- bare `-n` or bare `--rounds`: select the latest 1 visible conversation round;
- `-n={N}` or `--rounds={N}`: select the latest `N` visible rounds;
- `-n=all` or `--rounds=all`: select all visible user/assistant rounds in the
  current chat window.

Without `--full`, selected rounds are summarized. With `--full`, selected
visible text is preserved or sent as full context according to the command's
own write policy.

## Topic ids

`council-open` may be called without a topic id.

When the user omits it, generate an id without asking:

- default: `{YYYY-MM-DD}-{n}`, for example `2026-06-03-1`;
- choose the first positive integer not already used in active or archive;
- a short obvious slug such as `review-l1-spike` is acceptable when the user
  note makes the subject clear.

Do not let naming become a blocking step.

## Read policy

Default read set:

- `topic.md`
- `status.md`
- peer latest message under `latest/`
- `latest/for-peer.md`
- `consensus.md` if present

Do not read other topics or archive/history by default.

## Handoff size budget

When writing `latest/{agent}.md` or `latest/for-peer.md`, keep the handoff under:

- 500 words; or
- 20 bullets.

Compress longer selected rounds to decisions, evidence, blockers, open questions,
and requested peer focus.

Do not roll forward stale detail from previous latest files unless it is still
needed for the next decision.

If `council-open --full` is used, keep latest files short and write full visible
source text to a separate `turns/{turn_number}-{agent}-open-full-context.md`
attachment.

## Focus policy

The subject is the user's topic. The Council mechanism is not the subject unless the user explicitly says so.

Ignore workflow boilerplate in peer messages. Extract and review the actual technical or product content.

Do not review Agent Council protocol, file structure, skill behavior, or workflow mechanics unless the topic itself is Agent Council.

User-facing `council-review` output should be compact:

- verdict first;
- short topic judgment;
- blockers or must-preserve nits only when useful;
- `Next action`;
- `Side effects`.

Do not add long protocol explanations to normal topic reviews.

## Lightweight metadata

Turn records and `consensus.md` may use short YAML frontmatter:

```yaml
topic: product-l1-gate
agent: claude
turn: 5
state: CONSENSUS_WITH_NITS
formal_files_modified: false
```

Do not add large metadata blocks by default. The bridge should stay cheap to read.

## status.md schema

Use this stable shape:

```yaml
topic: product-l1-gate
state: REVIEW_REQUESTED
turn: 1
last_agent: codex
next_agent: claude
updated_at: 2026-06-03T12:00:00Z
latest_handoff: latest/for-peer.md
consensus:
```

Legal `state` values:

- `REVIEW_REQUESTED`
- `DISCUSSION`
- `NEEDS_DISCUSSION`
- `CONSENSUS`
- `CONSENSUS_WITH_NITS`
- `USER_FORCED_CONSENSUS`
- `USER_DECISION_NEEDED`
- `BLOCKED`
- `APPLIED`
- `CLOSED`
- `ABANDONED`

## Write policy

`council-open`, `council-review`, and `council-status` write only Council state.

`council-longrun` writes only longrun rules under `.agent-council/longrun/`.
It must not create normal Council topics or modify formal project files.

`council-apply` may modify formal project files, but only when the user gives an apply instruction or the target is explicit.

## Consensus

If both sides naturally agree, write `CONSENSUS`.

If both sides agree on direction and only non-blocking small issues remain, write `CONSENSUS_WITH_NITS`.

If the user passes `CONSENSUS` but material risks remain, write `USER_FORCED_CONSENSUS` and record those risks clearly.

Do not turn a user-forced stop into natural agreement.

Use a short consensus template:

- verdict;
- decision / ready-for;
- forbidden actions;
- blockers;
- must-preserve nits;
- side effects.

## Next action

Every `council-review` user-facing response must end with `Next action`.

`Next action` is advisory and scoped to the current Council topic. It is not
permission to stop, resume, chain tasks, commit, push, merge, deploy, or enter a
new workflow stage.

If the state is `NEEDS_DISCUSSION`, provide the exact command the other tool should run.

If the state is `CONSENSUS` or `CONSENSUS_WITH_NITS`, say no further peer-review round is recommended, say control returns to the normal workflow, and offer `council-apply` as optional when formal project files should change.

If the state is `USER_DECISION_NEEDED`, list the user decision needed instead of sending the topic to another peer.

If the state is `BLOCKED`, say apply is not allowed unless the user explicitly overrides the risk.

## Side effects

Every command that writes files should include a short side effects summary:

- Council files modified;
- formal project files modified;
- code changes;
- next action.

For `council-open` and `council-review`, formal project files and code changes should be `none`.

## Doctor checks

`council-status {topic_id} --doctor` checks:

- lowercase agent path conflicts such as `latest/CLAUDE.md`;
- missing `latest/for-peer.md`;
- missing peer latest files when expected;
- non-contiguous turn numbers;
- `status.md` state disagreeing with `consensus.md`;
- consensus older than the latest recorded turn;
- signs that a review turn modified formal project files.

Doctor should report short `OK` and `Warnings` lists. It should not enforce a heavy state machine.

Doctor must not recommend Council intervention merely because tasks are
continuing without Council. Council is opt-in.
