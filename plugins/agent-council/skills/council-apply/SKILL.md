---
name: council-apply
description: Apply an Agent Council consensus or latest agreed result to project files.
disable-model-invocation: true
---

# Council Apply

Arguments:
`{topic_id} [-- apply instruction]`

Examples:
- `$council-apply retry-design -- Apply the consensus to docs/plan.md.`
- `/council-apply checkout-plan -- Update the plan only; do not change source code.`

## Purpose

Apply the agreed Council result to formal project files.

This is the only Council action that should modify project files. If the target file or change is not clear, stop and ask the user for an explicit apply instruction.

Do not review Agent Council protocol, file structure, skill behavior, or workflow mechanics unless the topic itself is Agent Council.

## Current agent

If running in Claude Code, write this turn as `claude`.

If running in Codex, write this turn as `codex`.

Agent ids are canonical lowercase. Never write paths with `Claude`, `CLAUDE`, `Codex`, or `CODEX`.

## Read policy

Read:

- `.agent-council/active/{topic_id}/topic.md`
- `.agent-council/active/{topic_id}/status.md`
- `.agent-council/active/{topic_id}/latest/claude.md` if present
- `.agent-council/active/{topic_id}/latest/codex.md` if present
- `.agent-council/active/{topic_id}/consensus.md` if present

Prefer `consensus.md` when it exists.

Default rule: if no `consensus.md` exists, stop and tell the user to run `council-review {topic_id} CONSENSUS`, or explicitly request apply latest.

Only apply without `consensus.md` when the user explicitly says to apply latest or apply the latest result.

Do not read full history by default.

## Apply behavior

Make only the changes requested by the user or clearly agreed by both tools.

Do not introduce new design decisions during apply. If a new issue appears, stop and ask whether to reopen review.

If applying without `consensus.md` by explicit user instruction, the user-facing response must include:

`No formal consensus was found. Applied latest result by explicit user instruction.`

Do not apply when `status.md` state is `BLOCKED`, unless the user explicitly overrides the blocker.

Do not apply when `status.md` state is `USER_DECISION_NEEDED`, unless the user
explicitly states the decision, for example: "I choose option A; continue
apply."

If `consensus.md` exists but its state or verdict is
`USER_FORCED_CONSENSUS`, restate the accepted risks before applying. If the
user has not explicitly accepted those risks, stop and ask for confirmation.

After applying, write:

- `.agent-council/active/{topic_id}/status.md`
- `.agent-council/active/{topic_id}/applied/{turn_number}-{current_agent}-apply.md`
- `.agent-council/active/{topic_id}/latest/{current_agent}.md`

Set `status.md` state to `APPLIED` after a successful apply.

Write an apply report with short YAML frontmatter:

```yaml
---
topic: {topic_id}
agent: {current_agent}
state: APPLIED
formal_files_modified: true
---
```

## User-facing response

Report:

- what changed;
- what files were changed;
- whether a final peer review is recommended;
- the exact next command if useful.
- `Side effects` with Council files modified, formal project files modified, and code changes.
