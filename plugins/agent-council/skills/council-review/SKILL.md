---
name: council-review
description: Review the peer's latest Agent Council handoff and write the current agent's latest reply.
disable-model-invocation: true
---

# Council Review

Arguments:
`{topic_id} [CONSENSUS] [-- review instruction]`

Examples:
- `/council-review retry-design -- Check whether the proposed next step is reasonable.`
- `$council-review retry-design -- Reply only to blockers and major concerns.`
- `/council-review retry-design CONSENSUS -- If only non-blocking issues remain, converge.`

## Purpose

Read the peer's latest handoff for the topic, review the actual content, and write your reply back to the topic.

This command covers review, response, rebuttal, confirmation, and convergence. Use `council-review` for both directions.

`council-review` is the merged review/respond command. `council-respond` is not part of the v2 flow.

Manual invocation boundary: only run this skill because the user explicitly
invoked `council-review`. Council is advisory and topic-scoped. It must not
automatically stop tasks, create follow-up topics, route into another task, or
claim authority over the surrounding workflow.

## Current agent

If running in Claude Code, use `claude` as the current agent and read Codex's latest message first.

If running in Codex, use `codex` as the current agent and read Claude's latest message first.

Agent ids are canonical lowercase. Never write paths with `Claude`, `CLAUDE`, `Codex`, or `CODEX`.

## Default read set

Read only:

- `.agent-council/active/{topic_id}/topic.md`
- `.agent-council/active/{topic_id}/status.md`
- `.agent-council/active/{topic_id}/latest/{peer_agent}.md`
- `.agent-council/active/{topic_id}/latest/for-peer.md`
- `.agent-council/active/{topic_id}/latest/user-request.md`
- `.agent-council/active/{topic_id}/consensus.md` if present

Do not read all turns, other topics, archive directories, or unrelated project files unless explicitly asked.

If the arguments include `CONSENSUS`, also read both latest files:

- `.agent-council/active/{topic_id}/latest/claude.md`
- `.agent-council/active/{topic_id}/latest/codex.md`

If either latest file is missing, do not write natural `CONSENSUS` or
`CONSENSUS_WITH_NITS`. Either ask for the missing peer review, or write
`USER_FORCED_CONSENSUS` only when the user explicitly accepts stopping without
both latest files.

If `status.md` state is `CLOSED` or `ABANDONED`, stop and tell the user review should not continue unless they explicitly reopen the topic.

Before writing, check for case-conflict paths such as `latest/CLAUDE.md` or `latest/Codex.md`. If found, warn briefly and continue only with canonical lowercase paths.

If the peer latest handoff is long, do not mirror its length. Extract only the
current decisions, evidence, blockers, open questions, and requested review
focus.

## Focus rule

The subject is the topic content, not Agent Council.

If the peer message contains workflow boilerplate, ignore it and review the actual technical, product, design, plan, or next-step content.

Hard rule: unless the topic itself is Agent Council, do not review Agent Council protocol, file structure, skill behavior, or workflow mechanics.

Do not spend the response explaining Council mechanics. At most, add one short line at the end with the `.agent-council` files updated.

## Review behavior

Evaluate the peer's latest content directly.

Use this compact structure:

- `Verdict: {state}`
- Topic judgment: one short paragraph about the actual topic.
- Blockers: only if present.
- Non-blocking nits or constraints: only if useful.
- Next action.
- Side effects.

Do not include long explanations of the Council protocol, file structure,
status model, or why the bridge exists. The user asked for a topic review, not
an essay about the tool.

Apply the default handoff size budget when writing `latest/{current_agent}.md`
and `latest/for-peer.md`:

- maximum 500 words;
- maximum 20 bullets;
- prefer fewer bullets when the next peer action is narrow;
- preserve blockers, accepted risks, must-preserve nits, and exact next action;
- drop stale detail from earlier turns unless it is still needed for the next
  decision.

If the user includes `CONSENSUS`:

- If no material blockers remain, write `CONSENSUS` or `CONSENSUS_WITH_NITS` and write `consensus.md`.
- If material risks remain but the user wants to stop, write `USER_FORCED_CONSENSUS`, write `consensus.md`, and list accepted risks clearly.
- If severe blockers remain, write `BLOCKED`, do not write natural consensus, and ask whether the user explicitly wants to override.

Do not write `USER_FORCED_CONSENSUS` as if both tools naturally agreed.

If the state is `USER_DECISION_NEEDED`, list the exact user decision needed and do not route to another peer-review round.

If a human interaction is needed, list the decision or authorization needed.
Do not say Council itself requires that interaction, and do not automatically
open another Council topic.

When writing `consensus.md`, use this short template:

```markdown
---
topic: {topic_id}
state: {CONSENSUS|CONSENSUS_WITH_NITS|USER_FORCED_CONSENSUS}
agent: {current_agent}
turn: {turn_number}
formal_files_modified: false
---

# Consensus

Verdict: {state}

## Decision

Ready for:
- {next_phase_or_action}

Not authorized:
- {forbidden_action_if_any}

## Blockers

None. OR list blockers / accepted risks.

## Must-Preserve Nits

1. {nit_or_constraint}

## Side Effects

Formal project files modified:
- none
```

Use `Must-Preserve Nits` for constraints that are not blockers but must carry into the next phase. Do not let them disappear as turns are summarized.

## Write policy

Create or update:

- `.agent-council/active/{topic_id}/latest/{current_agent}.md`
- `.agent-council/active/{topic_id}/latest/for-peer.md`
- `.agent-council/active/{topic_id}/latest/user-request.md`
- `.agent-council/active/{topic_id}/status.md`
- `.agent-council/active/{topic_id}/turns/{turn_number}-{current_agent}-review.md`
- `.agent-council/active/{topic_id}/consensus.md` if consensus is reached or forced

Do not modify formal project files.

Add short YAML frontmatter to the turn record:

```yaml
---
topic: {topic_id}
agent: {current_agent}
turn: {turn_number}
state: {state}
formal_files_modified: false
---
```

Write `status.md` with this schema:

```yaml
topic: {topic_id}
state: {REVIEW_REQUESTED|DISCUSSION|NEEDS_DISCUSSION|CONSENSUS|CONSENSUS_WITH_NITS|USER_FORCED_CONSENSUS|USER_DECISION_NEEDED|BLOCKED|APPLIED|CLOSED|ABANDONED}
turn: {turn_number}
last_agent: {current_agent}
next_agent: {peer_agent_or_user_or_none}
updated_at: {iso8601_utc_timestamp}
latest_handoff: latest/for-peer.md
consensus: {consensus_md_or_empty}
```

## User-facing response

Start with the verdict line.

Then give the topic judgment. Keep it short and about the user's actual
technical, product, design, planning, or writing content.

List only material blockers and must-preserve nits. Skip protocol commentary.

Every response must end with `Next action`.

`Next action` is advisory and limited to this Council topic. It is not
authorization to stop, resume, chain, commit, push, merge, deploy, or enter the
next task.

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
Return to the normal task flow. Optional: run `$council-apply {topic_id} -- Apply the consensus.`
```

If state is `USER_FORCED_CONSENSUS`, say the stop was user-forced and list any accepted risks. Offer apply only if the user has explicitly accepted those risks.

If state is `USER_DECISION_NEEDED`, list the user decisions needed. Do not ask another agent to review.

If state is `BLOCKED`, say apply is not allowed unless the user explicitly overrides the risk.

If state is `CLOSED` or `ABANDONED`, say review should not continue unless the user explicitly reopens the topic.

When a topic reaches `CONSENSUS`, `CONSENSUS_WITH_NITS`,
`USER_FORCED_CONSENSUS`, `BLOCKED`, `CLOSED`, `ABANDONED`, or `APPLIED`, do
not suggest opening a new topic or continuing into the next implementation
task. Say that control returns to the normal user/tool workflow.

Then add a short `Side effects` summary:

```text
Side effects:
- Council files modified: status.md, latest/{agent}.md, latest/for-peer.md, turns/{turn_number}-{agent}-review.md
- Formal project files modified: none
- Code changes: none
```
