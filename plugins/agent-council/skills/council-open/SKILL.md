---
name: council-open
description: Open a lightweight Agent Council topic using the latest turn as the peer handoff.
---

# Council Open

Arguments:
`<topic-id> [-- handoff note]`

Examples:
- `$council-open retry-design -- Use my latest answer as the handoff. Ask the peer to check whether the next step is reasonable.`
- `/council-open checkout-plan -- Record the current recommendation so Codex can review it.`

## Purpose

Open one isolated topic under `.agent-council/active/<topic-id>/` and write the current handoff for the peer tool.

Keep this action simple. Do not require artifact paths, stages, or special modes. If the user includes a file path in the note, record it. If not, do not invent one.

## Current agent

If running in Claude Code, use `claude` as the current agent and `codex` as the peer.

If running in Codex, use `codex` as the current agent and `claude` as the peer.

## Read policy

Use only the current visible conversation context and the user's optional handoff note. Do not scan repository files unless the user explicitly points to them.

If the useful content is not visible or is represented only by a placeholder, ask the user to provide a short handoff note instead of guessing.

## Write policy

Create or update:

- `.agent-council/index.md`
- `.agent-council/active/<topic-id>/topic.md`
- `.agent-council/active/<topic-id>/status.md`
- `.agent-council/active/<topic-id>/latest/<current-agent>.md`
- `.agent-council/active/<topic-id>/latest/for-peer.md`
- `.agent-council/active/<topic-id>/latest/user-request.md`
- `.agent-council/active/<topic-id>/turns/<next-number>-<current-agent>-open.md`

Do not modify formal project files.

## Content policy

The handoff should focus on the actual topic. Do not explain or analyze Agent Council itself unless the user explicitly asks for that.

Write a concise handoff with this shape:

- Topic
- Latest peer-facing message
- What needs review
- Suggested next command for the peer

Do not summarize the entire chat history. Capture only the latest meaningful answer or the user's explicit note.

## User-facing response

Reply with:

- one short summary of what was handed off;
- files written;
- the exact command the peer should run next.

Keep the response content-first. Mention Council files only briefly at the end.
