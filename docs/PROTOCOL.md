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

## Write policy

`council-open`, `council-review`, and `council-status` write only Council state.

`council-apply` may modify formal project files, but only when the user gives an apply instruction or the target is explicit.

## Consensus

If both sides agree or the user passes `CONSENSUS`, write `consensus.md`.

If the user forces convergence while material risks remain, record those risks clearly.
