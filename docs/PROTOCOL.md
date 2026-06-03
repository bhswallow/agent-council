# Protocol

Agent Council v2 uses a latest-turn bridge model.

## Workspace

All runtime state lives under:

    .agent-council/active/<topic-id>/

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

## Read policy

Default read set:

- `topic.md`
- `status.md`
- peer latest message under `latest/`
- `latest/for-peer.md`
- `consensus.md` if present

Do not read other topics or archive/history by default.

## Focus policy

The subject is the user's topic. The Council mechanism is not the subject unless the user explicitly says so.

Ignore workflow boilerplate in peer messages. Extract and review the actual technical or product content.

Do not review Agent Council protocol, file structure, skill behavior, or workflow mechanics unless the topic itself is Agent Council.

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

If the state is `NEEDS_DISCUSSION`, provide the exact command the other tool should run.

If the state is `CONSENSUS` or `CONSENSUS_WITH_NITS`, say no further peer-review round is recommended and offer `council-apply` as optional.

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

`council-status <topic-id> --doctor` checks:

- lowercase agent path conflicts such as `latest/CLAUDE.md`;
- missing `latest/for-peer.md`;
- missing peer latest files when expected;
- non-contiguous turn numbers;
- `status.md` state disagreeing with `consensus.md`;
- consensus older than the latest turn;
- signs that a review turn modified formal project files.

Doctor should report short `OK` and `Warnings` lists. It should not enforce a heavy state machine.
