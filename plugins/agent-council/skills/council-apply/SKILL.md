---
name: council-apply
description: Apply an Agent Council consensus or latest agreed result to project files.
---

# Council Apply

Arguments:
`<topic-id> [-- apply instruction]`

Examples:
- `$council-apply retry-design -- Apply the consensus to docs/design.md.`
- `/council-apply checkout-plan -- Update the plan only; do not change source code.`

## Purpose

Apply the agreed Council result to formal project files.

This is the only Council action that should modify project files. If the target file or change is not clear, stop and ask the user for an explicit apply instruction.

## Current agent

If running in Claude Code, write this turn as `claude`.

If running in Codex, write this turn as `codex`.

## Read policy

Read:

- `.agent-council/active/<topic-id>/topic.md`
- `.agent-council/active/<topic-id>/status.md`
- `.agent-council/active/<topic-id>/latest/claude.md` if present
- `.agent-council/active/<topic-id>/latest/codex.md` if present
- `.agent-council/active/<topic-id>/consensus.md` if present

Prefer `consensus.md` when it exists. If no consensus exists, use only the latest clearly agreed result and say that no formal consensus was found.

Do not read full history by default.

## Apply behavior

Make only the changes requested by the user or clearly agreed by both tools.

Do not introduce new design decisions during apply. If a new issue appears, stop and ask whether to reopen review.

After applying, write:

- `.agent-council/active/<topic-id>/status.md`
- `.agent-council/active/<topic-id>/applied/<next-number>-<current-agent>-apply.md`
- `.agent-council/active/<topic-id>/latest/<current-agent>.md`

## User-facing response

Report:

- what changed;
- what files were changed;
- whether a final peer review is recommended;
- the exact next command if useful.
