---
name: council-status
description: Show or update the status of Agent Council topics.
disable-model-invocation: true
---

# Council Status

Arguments:
`[topic-id|all] [--doctor] [close|abandon|archive] [-- note]`

Examples:
- `/council-status all`
- `$council-status retry-design`
- `/council-status retry-design close`
- `$council-status retry-design abandon`
- `$council-status product-l1-gate --doctor`

## Purpose

Show the active topic state without changing project files.

Optionally close, abandon, or archive a topic when the user explicitly asks.

Do not review Agent Council protocol, file structure, skill behavior, or workflow mechanics unless the topic itself is Agent Council.

## Read policy

For `all`, read only `.agent-council/index.md` and the `status.md` file for each active topic.

For one topic, read only:

- `.agent-council/active/{topic_id}/topic.md`
- `.agent-council/active/{topic_id}/status.md`
- `.agent-council/active/{topic_id}/consensus.md` if present
- latest timestamps or latest file names if useful

Do not load full turns by default.

## Behavior

If no topic is provided and only one active topic exists, you may infer it and say so. If multiple active topics exist, ask for the topic id.

For `close`, mark the topic closed.

For `abandon`, mark it abandoned and preserve files.

For `archive`, move it from `.agent-council/active/{topic_id}/` to `.agent-council/archive/{topic_id}/` if tools allow. If not, explain the move needed.

For `--doctor`, check consistency without modifying files unless the user explicitly asks for a repair. Keep checks short and high-value:

- case-conflict paths that differ only by agent id casing, such as `latest/CLAUDE.md` vs `latest/claude.md`;
- missing `latest/for-peer.md`;
- missing `latest/claude.md` or `latest/codex.md` when status implies both sides reviewed;
- non-contiguous turn numbers;
- `status.md` state disagreeing with `consensus.md` verdict/state;
- `consensus.md` older than the newest turn;
- any indication that a review/open turn modified formal project files.

Doctor output should be:

```text
Doctor: {topic_id}

OK:
- ...

Warnings:
- ...
```

Do not enforce a strict state machine. Report warnings and suggested fixes.

Use the stable `status.md` schema:

```yaml
topic: {topic_id}
state: {REVIEW_REQUESTED|DISCUSSION|NEEDS_DISCUSSION|CONSENSUS|CONSENSUS_WITH_NITS|USER_FORCED_CONSENSUS|USER_DECISION_NEEDED|BLOCKED|APPLIED|CLOSED|ABANDONED}
turn: {turn_number}
last_agent: {agent}
next_agent: {agent_or_user_or_none}
updated_at: {iso8601_utc_timestamp}
latest_handoff: latest/for-peer.md
consensus: {consensus_md_or_empty}
```

For `close`, set state to `CLOSED`. For `abandon`, set state to `ABANDONED`. Closed or abandoned topics should not continue review unless the user explicitly reopens them.

## User-facing response

Keep the response short:

- current topic status;
- latest owner / next recommended command;
- whether another peer review is useful.
- `Side effects` if files were modified; for read-only status or doctor, say `none`.
