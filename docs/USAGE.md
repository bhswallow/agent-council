# Usage

Agent Council v2 is a latest-turn bridge. Use it when Claude Code and Codex need to comment on each other's latest message without sharing the same chat window.

## Commands

    council-open <topic-id> [-- handoff note]
    council-review <topic-id> [CONSENSUS] [-- review instruction]
    council-apply <topic-id> [-- apply instruction]
    council-status [topic-id|all]
    council-help [zh|en]
    council-upgrade [--check] [--claude-only|--codex-only]

`council-respond` was removed in v2.0.2. Use `council-review` instead.

Use `council-upgrade` to update standalone installs from the latest repository version.

## Open a topic

    $council-open retry-design -- Use my latest answer as the handoff. Ask the peer to check whether the next step is sound.

The skill writes the handoff under `.agent-council/active/retry-design/`.

## Review the peer's latest handoff

    /council-review retry-design -- Focus on blockers and whether we should proceed.

The reviewing tool reads the peer's latest message and writes its own reply back to the same topic.

## Continue the loop

    $council-review retry-design -- Reply only to the peer's blockers.

## Converge

    /council-review retry-design CONSENSUS -- If only non-blocking issues remain, write the final agreed result.

## Apply

    $council-apply retry-design -- Apply the consensus to docs/design.md.

Only `council-apply` should modify formal project files.

## Notes

Keep the topic focused. Do not ask the tools to analyze the Council workflow unless the topic is specifically about Agent Council.
