---
name: council-status
description: Show, compact, archive, abandon, or close Agent Council topics without changing formal artifacts.
---

# Council Status

Arguments:
`[topic-id|all] [archive|abandon|close|compact] [-- extra instruction]`

Examples:
- `/council-status all`
- `$council-status retry-design`
- `/council-status retry-design compact`
- `$council-status retry-design abandon`

## Agent Council protocol

This skill participates in a manual cross-review workflow between Claude Code and Codex.

Persistent working directory:
.agent-council/active/<topic-id>/

Never write Council discussion files into .claude/, .agents/, .codex/, AGENTS.md, CLAUDE.md, docs/, source files, tests, or third-party skill/plugin directories. Formal artifacts may only be changed by council-apply or by an explicit direct user instruction.

Default files for a topic:
- manifest.md: topic id, stage, artifact, status, protocol version, current owner, last turn number.
- focus.md: current review scope and out-of-scope items.
- source-brief.md: compressed handoff when the source material exists only in the current chat.
- context-pack.md: compact current state. Keep concise and update after every turn.
- latest/<agent>.md: latest concise turn from the agent.
- latest/user-request.md: the user's per-turn extra instruction.
- latest/peer-request.md: a short request for the other agent.
- positions/<agent>.md: current position and verdict for the agent.
- decisions.md: accepted, rejected, deferred, and disputed decisions.
- open-questions.md: active questions only.
- consensus.md: final or user-forced consensus.
- turns/<NNNN>-<agent>-<action>.md: the current turn log. Keep only recent useful turns in active context.

Topic isolation:
- Read only the requested topic.
- Do not read other active topics unless the user explicitly asks.
- If the user omits a topic and more than one topic is active, stop and ask for the topic id.
- If one topic is active, you may infer it and state that you did so.

Context budget:
- Default read set: manifest.md, focus.md, source-brief.md if present, context-pack.md, latest peer turn, latest user request, positions/*.md, decisions.md, open-questions.md, consensus.md if present, and the bound artifact if it exists.
- Do not read archive/ by default.
- Do not recursively load .agent-council/.
- Keep context-pack.md below roughly 200 lines. If it is too long, compact it before continuing.

Extra instructions:
- Text after `--` is per-turn user guidance.
- In council-open, extra instructions become topic context.
- In review/respond/apply/status, extra instructions affect only the current turn unless they start with `sticky:`.
- Sticky instructions may be added to focus.md if useful.

Verdicts:
- ACCEPT
- ACCEPT_WITH_NITS
- NEEDS_DISCUSSION
- REQUEST_CHANGES
- BLOCKED
- USER_DECISION_NEEDED
- CONSENSUS
- CONSENSUS_WITH_NITS
- USER_FORCED_CONSENSUS

Consensus rule:
- Natural consensus requires both agents to be ACCEPT or ACCEPT_WITH_NITS and no blocking open questions.
- If the user includes CONSENSUS while disagreement remains, record USER_FORCED_CONSENSUS, not natural consensus.
- Serious unresolved risks must be listed as accepted risks or user decisions. Do not hide them.

User-facing response after every action:
- Verdict.
- Files written.
- Short summary.
- Whether peer review is recommended.
- Exact next command if another action is recommended.

## Behavior

1. If no topic is provided, infer it only when exactly one active topic exists.
2. `all`: list active topics from `.agent-council/index.md` and directories under `.agent-council/active/`.
3. Default status: summarize manifest, current verdicts, open questions, consensus state, and next command.
4. `compact`: reduce old turns into `context-pack.md`, move old turn details to `archive/`, and keep only recent useful turn files.
5. `archive`: move the topic from active to archive if it is complete or explicitly requested.
6. `abandon`: mark status `ABANDONED` and stop recommending peer review.
7. `close`: mark status `CLOSED` when consensus has been applied or the user explicitly closes it.
8. Do not modify formal artifacts.
9. Reply with the current state and a recommended next command or say that no next action is needed.
