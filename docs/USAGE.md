# Usage

Agent Council v2 is a latest-turn bridge.
Use it when Claude Code and Codex need to comment on each other's latest
message without sharing the same chat window.

Agent Council is a lightweight, manual latest-turn bridge for Claude Code and
Codex. It records what one tool wants the other to review, lets the peer reply,
and preserves consensus without polluting project files.

Keep reviews focused on the topic. Unless the topic itself is Agent Council, do
not turn the exchange into a review of Council protocol or workflow mechanics.

Agent ids and paths are lowercase: `claude`, `codex`, `latest/claude.md`, `latest/codex.md`.

## Commands

    council-open <topic-id> [-- handoff note]
    council-review <topic-id> [CONSENSUS] [-- review instruction]
    council-apply <topic-id> [-- apply instruction]
    council-status [topic-id|all] [--doctor]
    council-help [zh|en]
    council-version [--check]
    council-upgrade [--check] [--claude-only|--codex-only]

`council-respond` was removed in v2.0.2. Use `council-review` instead.

Use `council-upgrade` to update standalone installs from the latest repository version.

Use `council-version` to confirm which installed copy is active.

If `council-upgrade` completes but `council-help` still shows an old version,
the active command is usually from another standalone location or from a plugin
cache.

Use `council-status <topic-id> --doctor` to check lowercase path conflicts,
turn continuity, stale consensus, and status/consensus drift.

## Open a topic

    $council-open retry-design -- Use my latest answer as the handoff.

The skill writes the handoff under `.agent-council/active/retry-design/`.

## Review the peer's latest handoff

    /council-review retry-design -- Focus on blockers and whether we should proceed.

The reviewing tool reads the peer's latest message and writes its own reply back to the same topic.

## Continue the loop

    $council-review retry-design -- Reply only to the peer's blockers.

## Converge

    /council-review retry-design CONSENSUS -- If only non-blocking issues remain, write the final agreed result.

`CONSENSUS` asks the tool to judge whether the loop can stop.
It does not require natural agreement.
Serious unresolved risks should become `BLOCKED` or
`USER_FORCED_CONSENSUS`, depending on the user's instruction.

## Apply

    $council-apply retry-design -- Apply the consensus to docs/design.md.

Only `council-apply` should modify formal project files.

By default, apply requires `consensus.md`. To apply without one, the user must explicitly request applying latest.

Every writing command should show a short `Side effects` summary.
`council-review` and `council-open` should report no formal project file
changes.

`council-review` should start with a verdict, then a short topic judgment, then
`Next action` and `Side effects`.
Do not add long explanations of the Council workflow unless the topic is Agent
Council itself.

## Notes

Keep the topic focused.
Do not ask the tools to analyze the Council workflow unless the topic is
specifically about Agent Council.
