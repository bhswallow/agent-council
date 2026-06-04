# Usage

Agent Council v2.7.1 is a latest-turn bridge.
Use it when Claude Code and Codex need to comment on each other's latest
message without sharing the same chat window.

Agent Council is a lightweight, manual latest-turn bridge for Claude Code and
Codex. It records what one tool wants the other to review, lets the peer reply,
and preserves consensus without polluting project files.

Council is invoked by the user. It must not automatically stop tasks, create
topics, or chain into another task after a topic finishes.

Outer workflows may briefly remind the user that Council is available after
brainstorming, design, plans, specs, a task batch, or a blocker. Match the
user's current language. The reminder is optional and must not invoke Council
or stop execution.

Keep reviews focused on the topic. Unless the topic itself is Agent Council, do
not turn the exchange into a review of Council protocol or workflow mechanics.

Agent ids and paths are lowercase: `claude`, `codex`, `latest/claude.md`, `latest/codex.md`.

## Commands

    council-open [topic-id] [-- handoff note]
    council-review {topic_id} [CONSENSUS] [-- review instruction]
    council-apply {topic_id} [-- apply instruction]
    council-status [topic-id|all] [--doctor]
    council-help [zh|en]
    council-version [--check]
    council-upgrade [--check|--apply] [--ref {git_ref}] [--claude-only|--codex-only]

`council-respond` was removed in v2.0.2. Use `council-review` instead.

Use `council-upgrade` to check standalone install versions.
It is check-only by default. Use `council-upgrade --apply` to update. Add
`--ref {git_ref}` only when you want a specific branch, tag, or commit.

Use `council-version` to confirm which installed copy is active.

If `council-upgrade` completes but `council-help` still shows an old version,
the active command is usually from another standalone location or from a plugin
cache.

Use `council-status {topic_id} --doctor` to check lowercase path conflicts,
turn continuity, stale consensus, and status/consensus drift.

`council-open` can omit the topic id. If omitted, it generates a date-based id
such as `2026-06-03-1`.

## Optional utility: claude-p

`claude-p` is not part of the Council main flow. It is a one-shot utility for
running the Claude Code native headless command `claude -p` when the local
`claude` CLI is installed and available in `PATH`.

It does not require Codex CLI. It does not write Council topics or project
files by default.

It only receives the explicit prompt. It cannot automatically read the current
Codex or Claude chat transcript. Use a bounded timeout and report timeout/no
output clearly.

It should also show status updates while running, including starting, elapsed
running time, completed, timed out, or no-output states.

Examples:

    $claude-p "Review docs/design.md for blockers."
    $claude-p --topic product-l1-gate "Review the latest Council handoff for blockers."

## Open a topic

    $council-open retry-design -- Use my latest answer as the handoff.

Or let Council choose the topic id:

    $council-open -- Use my latest answer as the handoff.

The skill writes the handoff under `.agent-council/active/retry-design/`.

Latest handoffs should stay under 500 words or 20 bullets. Compress long source
turns to decisions, evidence, blockers, open questions, and requested peer
focus.

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

    $council-apply retry-design -- Apply the consensus to docs/plan.md.

Only `council-apply` should modify formal project files.

By default, apply requires `consensus.md`. To apply without one, the user must explicitly request applying latest.

Every writing command should show a short `Side effects` summary.
`council-review` and `council-open` should report no formal project file
changes.

`council-review` should start with a verdict, then a short topic judgment, then
`Next action` and `Side effects`.
Do not add long explanations of the Council workflow unless the topic is Agent
Council itself.

`Next action` is advisory for the current topic only. It is not permission to
stop, resume, commit, push, merge, deploy, or enter the next task.

## Notes

Keep the topic focused.
Do not ask the tools to analyze the Council workflow unless the topic is
specifically about Agent Council.
