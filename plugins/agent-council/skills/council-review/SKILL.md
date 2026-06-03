---
name: council-review
description: Review the peer's latest Agent Council handoff and write the current agent's latest reply.
---

# Council Review

Arguments:
`<topic-id> [CONSENSUS] [-- review instruction]`

Examples:
- `/council-review retry-design -- Check whether the proposed next step is reasonable.`
- `$council-review retry-design -- Reply only to blockers and major concerns.`
- `/council-review retry-design CONSENSUS -- If only non-blocking issues remain, converge.`

## Purpose

Read the peer's latest handoff for the topic, review the actual content, and write your reply back to the topic.

This command covers review, response, rebuttal, confirmation, and convergence. Use `council-review` for both directions.

## Current agent

If running in Claude Code, use `claude` as the current agent and read Codex's latest message first.

If running in Codex, use `codex` as the current agent and read Claude's latest message first.

## Default read set

Read only:

- `.agent-council/active/<topic-id>/topic.md`
- `.agent-council/active/<topic-id>/status.md`
- `.agent-council/active/<topic-id>/latest/<peer>.md`
- `.agent-council/active/<topic-id>/latest/for-peer.md`
- `.agent-council/active/<topic-id>/latest/user-request.md`
- `.agent-council/active/<topic-id>/consensus.md` if present

Do not read all turns, other topics, archive directories, or unrelated project files unless explicitly asked.

## Focus rule

The subject is the topic content, not Agent Council.

If the peer message contains workflow boilerplate, ignore it and review the actual technical, product, design, plan, or next-step content.

Do not spend the response explaining Council mechanics. At most, add one short line at the end with the files updated.

## Review behavior

Evaluate the peer's latest content directly.

Use this structure where useful:

- Verdict: ACCEPT, ACCEPT_WITH_NITS, NEEDS_DISCUSSION, REQUEST_CHANGES, BLOCKED, USER_DECISION_NEEDED, CONSENSUS, or USER_FORCED_CONSENSUS
- Main judgment
- Blockers, if any
- Major concerns, if any
- What you agree with
- What you disagree with
- Proposed next step
- Exact command for the peer, if another round is useful

If the user includes `CONSENSUS`:

- If no material blockers remain, write a normal `consensus.md`.
- If material risks remain but the user wants to stop, write `USER_FORCED_CONSENSUS` and list accepted risks clearly.

## Write policy

Create or update:

- `.agent-council/active/<topic-id>/latest/<current-agent>.md`
- `.agent-council/active/<topic-id>/latest/for-peer.md`
- `.agent-council/active/<topic-id>/latest/user-request.md`
- `.agent-council/active/<topic-id>/status.md`
- `.agent-council/active/<topic-id>/turns/<next-number>-<current-agent>-review.md`
- `.agent-council/active/<topic-id>/consensus.md` if consensus is reached or forced

Do not modify formal project files.

## User-facing response

Start with your substantive judgment about the topic. Then list only the most important points. End with the next command, or say that no further peer review is recommended.
