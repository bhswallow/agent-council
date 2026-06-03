---
name: council-review
description: Review the peer's latest Agent Council handoff and write the current agent's latest reply.
disable-model-invocation: true
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

`council-review` is the merged review/respond command. `council-respond` is not part of the v2 flow.

## Current agent

If running in Claude Code, use `claude` as the current agent and read Codex's latest message first.

If running in Codex, use `codex` as the current agent and read Claude's latest message first.

Agent ids are canonical lowercase. Never write paths with `Claude`, `CLAUDE`, `Codex`, or `CODEX`.

## Default read set

Read only:

- `.agent-council/active/<topic-id>/topic.md`
- `.agent-council/active/<topic-id>/status.md`
- `.agent-council/active/<topic-id>/latest/<peer>.md`
- `.agent-council/active/<topic-id>/latest/for-peer.md`
- `.agent-council/active/<topic-id>/latest/user-request.md`
- `.agent-council/active/<topic-id>/consensus.md` if present

Do not read all turns, other topics, archive directories, or unrelated project files unless explicitly asked.

If `status.md` state is `CLOSED` or `ABANDONED`, stop and tell the user review should not continue unless they explicitly reopen the topic.

Before writing, check for case-conflict paths such as `latest/CLAUDE.md` or `latest/Codex.md`. If found, warn briefly and continue only with canonical lowercase paths.

## Focus rule

The subject is the topic content, not Agent Council.

If the peer message contains workflow boilerplate, ignore it and review the actual technical, product, design, plan, or next-step content.

Hard rule: unless the topic itself is Agent Council, do not review Agent Council protocol, file structure, skill behavior, or workflow mechanics.

Do not spend the response explaining Council mechanics. At most, add one short line at the end with the `.agent-council` files updated.

## Review behavior

Evaluate the peer's latest content directly.

Use this structure where useful:

- Verdict: CONSENSUS, CONSENSUS_WITH_NITS, NEEDS_DISCUSSION, USER_DECISION_NEEDED, BLOCKED, USER_FORCED_CONSENSUS, or DISCUSSION
- Main judgment
- Blockers, if any
- Major concerns, if any
- What you agree with
- What you disagree with
- Proposed next step
- Exact command for the peer, if another round is useful

If the user includes `CONSENSUS`:

- If no material blockers remain, write `CONSENSUS` or `CONSENSUS_WITH_NITS` and write `consensus.md`.
- If material risks remain but the user wants to stop, write `USER_FORCED_CONSENSUS`, write `consensus.md`, and list accepted risks clearly.
- If severe blockers remain, write `BLOCKED`, do not write natural consensus, and ask whether the user explicitly wants to override.

Do not write `USER_FORCED_CONSENSUS` as if both tools naturally agreed.

If the state is `USER_DECISION_NEEDED`, list the exact user decision needed and do not route to another peer-review round.

When writing `consensus.md`, use this short template:

```markdown
---
topic: <topic-id>
state: <CONSENSUS|CONSENSUS_WITH_NITS|USER_FORCED_CONSENSUS>
agent: <current-agent>
turn: <number>
formal_files_modified: false
---

# Consensus

Verdict: <state>

## Decision

Ready for:
- <next phase or action>

Not authorized:
- <forbidden action, if any>

## Blockers

None. OR list blockers / accepted risks.

## Must-Preserve Nits

1. <nit or constraint>

## Side Effects

Formal project files modified:
- none
```

Use `Must-Preserve Nits` for constraints that are not blockers but must carry into the next phase. Do not let them disappear as turns are summarized.

## Write policy

Create or update:

- `.agent-council/active/<topic-id>/latest/<current-agent>.md`
- `.agent-council/active/<topic-id>/latest/for-peer.md`
- `.agent-council/active/<topic-id>/latest/user-request.md`
- `.agent-council/active/<topic-id>/status.md`
- `.agent-council/active/<topic-id>/turns/<next-number>-<current-agent>-review.md`
- `.agent-council/active/<topic-id>/consensus.md` if consensus is reached or forced

Do not modify formal project files.

Add short YAML frontmatter to the turn record:

```yaml
---
topic: <topic-id>
agent: <current-agent>
turn: <number>
state: <state>
formal_files_modified: false
---
```

Write `status.md` with this schema:

```yaml
topic: <topic-id>
state: <REVIEW_REQUESTED|DISCUSSION|NEEDS_DISCUSSION|CONSENSUS|CONSENSUS_WITH_NITS|USER_FORCED_CONSENSUS|USER_DECISION_NEEDED|BLOCKED|APPLIED|CLOSED|ABANDONED>
turn: <number>
last_agent: <current-agent>
next_agent: <peer-agent or user or none>
updated_at: <ISO-8601 UTC timestamp>
latest_handoff: latest/for-peer.md
consensus: <consensus.md or empty>
```

## User-facing response

Start with your substantive judgment about the topic. Then list only the most important points.

Every response must end with `Next action`.

If state is `NEEDS_DISCUSSION`, provide the exact command for the other tool. Use the correct tool label:

```text
Next action:
Run in Claude Code:
/council-review product-l1-gate -- Review Codex's latest response and focus only on the remaining blockers.
```

or:

```text
Next action:
Run in Codex:
$council-review product-l1-gate -- Review Claude's latest concerns and decide whether they are blockers.
```

If state is `CONSENSUS` or `CONSENSUS_WITH_NITS`, say:

```text
Next action:
No further peer-review round is recommended.
Optional: run `$council-apply <topic-id> -- Apply the consensus.`
```

If state is `USER_FORCED_CONSENSUS`, say the stop was user-forced and list any accepted risks. Offer apply only if the user has explicitly accepted those risks.

If state is `USER_DECISION_NEEDED`, list the user decisions needed. Do not ask another agent to review.

If state is `BLOCKED`, say apply is not allowed unless the user explicitly overrides the risk.

If state is `CLOSED` or `ABANDONED`, say review should not continue unless the user explicitly reopens the topic.

Then add a short `Side effects` summary:

```text
Side effects:
- Council files modified: status.md, latest/<agent>.md, latest/for-peer.md, turns/<turn>-<agent>-review.md
- Formal project files modified: none
- Code changes: none
```
