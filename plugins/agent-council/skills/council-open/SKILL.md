---
name: council-open
description: Open a lightweight Agent Council topic using the latest turn as the peer handoff.
disable-model-invocation: true
---

# Council Open

Arguments:
`[topic-id] [-- handoff note]`

Examples:
- `/council-open`
- `$council-open -- Use my latest answer as the handoff. Ask the peer to check whether the next step is reasonable.`
- `$council-open retry-design -- Use my latest answer as the handoff. Ask the peer to check whether the next step is reasonable.`
- `/council-open checkout-plan -- Record the current recommendation so Codex can review it.`

## Purpose

Open one isolated topic under `.agent-council/active/<topic-id>/` and write the current handoff for the peer tool.

Keep this action simple. Do not require artifact paths, stages, or special modes. If the user includes a file path in the note, record it. If not, do not invent one.

`council-open` is only a latest-turn bridge. It captures the current tool's latest key content for the peer; it does not summarize full history.

## Topic id

The topic id is optional.

If the user provides a topic id, use it after normalizing to lowercase kebab-case.

If the user omits the topic id, generate one without asking:

- Default format: `<YYYY-MM-DD>-<n>`, for example `2026-06-03-1`.
- Use the current local date if available.
- Pick the first positive integer that does not already exist under `.agent-council/active/` or `.agent-council/archive/`.
- If the user's handoff note contains an obvious short subject, a concise slug such as `review-l1-spike` is also acceptable.

Do not make naming a blocking question. If unsure, use the date-based id.

## Current agent

If running in Claude Code, use `claude` as the current agent and `codex` as the peer.

If running in Codex, use `codex` as the current agent and `claude` as the peer.

Agent ids are canonical lowercase. Never write paths with `Claude`, `CLAUDE`, `Codex`, or `CODEX`.

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

Before writing, check for case-conflict paths such as `latest/CLAUDE.md` or `latest/Codex.md`. If found, mention the canonical lowercase path and avoid writing the mixed-case path.

## Content policy

The handoff should focus on the actual topic. Do not explain or analyze Agent Council itself unless the user explicitly asks for that.

Hard rule: unless the topic itself is Agent Council, do not review Agent Council protocol, file structure, skill behavior, or workflow mechanics.

Write a concise handoff with this shape:

- Topic
- Latest peer-facing message
- What needs review
- Suggested next command for the peer

Do not summarize the entire chat history. Capture only the latest meaningful answer or the user's explicit note.

Apply the default handoff size budget when writing `latest/<current-agent>.md` and `latest/for-peer.md`:

- maximum 500 words;
- maximum 20 bullets;
- prefer fewer bullets when the peer only needs a narrow review;
- if the source turn is longer, compress it to decisions, evidence, blockers, open questions, and the requested peer focus.

Do not carry forward old detail just because it was present in a previous latest handoff.

Add short YAML frontmatter to the turn record:

```yaml
---
topic: <topic-id>
agent: <current-agent>
turn: <number>
state: REVIEW_REQUESTED
formal_files_modified: false
---
```

Write `status.md` with this schema:

```yaml
topic: <topic-id>
state: REVIEW_REQUESTED
turn: <number>
last_agent: <current-agent>
next_agent: <peer-agent>
updated_at: <ISO-8601 UTC timestamp>
latest_handoff: latest/for-peer.md
consensus:
```

## User-facing response

Reply with:

- one short summary of what was handed off;
- the topic id used, especially if it was generated automatically;
- the exact command the peer should run next.
- `Side effects` with Council files modified, formal project files modified, code changes, and next action.

Keep the response content-first. Mention Council files only briefly at the end.
