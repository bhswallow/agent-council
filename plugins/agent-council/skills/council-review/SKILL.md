---
name: council-review
description: Review a Council topic as the current agent without modifying the formal artifact.
---

# Council Review

Arguments:
`<topic-id> [CONSENSUS] [-- extra instruction]`

Examples:
- `/council-review retry-design -- Review whether the design is ready for planning.`
- `$council-review checkout-design -- Use domain architect and senior engineer perspectives.`
- `/council-review retry-design CONSENSUS -- If only non-blocking issues remain, converge.`

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

1. Resolve `<topic-id>`.
2. Load only the default read set for that topic.
3. Review the bound artifact if it exists. If it does not exist and `source-brief.md` exists, review the source brief.
4. Respect extra instruction after `--` for this turn.
   - If the user asks for subagents or specialist reviewers, use them if available.
   - If no real subagents exist, say that you are using specialist perspectives in the main session instead.
5. Do not modify the formal artifact.
6. Write:
   - `latest/<current-agent>.md`
   - `positions/<current-agent>.md`
   - `latest/peer-request.md`
   - `turns/<NNNN>-<current-agent>-review.md`
   - update `context-pack.md`
   - update `open-questions.md` and `decisions.md` when needed
7. If consensus is reached, write or update `consensus.md`.
8. If the user supplied `CONSENSUS`, stop expanding the discussion and record natural or user-forced consensus according to the consensus rule.
9. Reply to the user with verdict, findings, files written, and next command.

## Review output requirements

Use this structure in the turn file:

- Verdict
- Summary
- Blockers
- Major concerns
- Minor concerns
- Questions for peer agent
- Suggested changes
- Accepted risks
- Next recommended action

A blocker must include evidence from the artifact, source brief, or explicit assumption. If evidence is missing, put it under Questions, not Blockers.
