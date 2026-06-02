---
name: council-open
description: Open an isolated Agent Council topic for a design, plan, diff, or chat-only source brief.
---

# Council Open

Arguments:
`<topic-id> <artifact>`
`<topic-id> brief <target-artifact> [stage] -- <brief instruction>`

Examples:
- `$council-open retry-design docs/design.md -- This design follows a structured design-to-plan workflow.`
- `/council-open checkout-design brief docs/design.md design -- Summarize the current brainstorming conversation into a source brief before design is written.`

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

1. Parse the arguments.
   - Normal mode: `<topic-id> <artifact>`.
   - Source-brief mode: `<topic-id> brief <target-artifact> [stage]`.
   - Text after `--` is extra instruction.
2. Validate topic id.
   - Use lowercase kebab-case when possible.
   - Treat it as a variable, not a fixed phrase.
3. Create `.agent-council/active/<topic-id>/` and subdirectories:
   - `latest/`
   - `positions/`
   - `turns/`
   - `archive/`
4. Create or update:
   - `manifest.md`
   - `focus.md`
   - `context-pack.md`
   - `decisions.md`
   - `open-questions.md`
   - `latest/user-request.md`
   - `latest/<current-agent>.md`
   - `positions/<current-agent>.md`
   - `.agent-council/index.md`
5. If source-brief mode is used:
   - Compress the current chat context into `source-brief.md`.
   - Do not invent details missing from the chat.
   - Mark assumptions clearly.
   - Target artifact may not exist yet.
6. If normal mode is used:
   - Bind the existing or intended artifact to the topic.
7. Set status to `REVIEW_REQUESTED` unless the user says otherwise.
8. Return a concise summary and the next command to run in the peer tool.

## Source-brief template

Write `source-brief.md` with these sections:

- Purpose
- Background
- Current understanding
- Accepted constraints
- Rejected directions
- Assumptions
- Open questions
- Target artifact
- What the peer should review
- Suggested next step

## Safety

Do not create or modify the formal artifact unless the user explicitly asked for it. This skill only opens the topic and writes Council files.
