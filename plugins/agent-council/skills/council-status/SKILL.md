---
name: council-status
description: Show or update the status of Agent Council topics.
---

# Council Status

Arguments:
`[topic-id|all] [close|abandon|archive] [-- note]`

Examples:
- `/council-status all`
- `$council-status retry-design`
- `/council-status retry-design close`
- `$council-status retry-design abandon`

## Purpose

Show the active topic state without changing project files.

Optionally close, abandon, or archive a topic when the user explicitly asks.

## Read policy

For `all`, read only `.agent-council/index.md` and the `status.md` file for each active topic.

For one topic, read only:

- `.agent-council/active/<topic-id>/topic.md`
- `.agent-council/active/<topic-id>/status.md`
- `.agent-council/active/<topic-id>/consensus.md` if present
- latest timestamps or latest file names if useful

Do not load full turns by default.

## Behavior

If no topic is provided and only one active topic exists, you may infer it and say so. If multiple active topics exist, ask for the topic id.

For `close`, mark the topic closed.

For `abandon`, mark it abandoned and preserve files.

For `archive`, move it from `.agent-council/active/<topic-id>/` to `.agent-council/archive/<topic-id>/` if tools allow. If not, explain the move needed.

## User-facing response

Keep the response short:

- current topic status;
- latest owner / next recommended command;
- whether another peer review is useful.
