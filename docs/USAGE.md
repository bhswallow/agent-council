# Usage

Agent Council v2.10.7 is a recent-round bridge.
Use it when Claude Code and Codex need to comment on each other's latest
message without sharing the same chat window.

Agent Council is a lightweight, manual recent-round bridge for Claude Code and
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

    council [zh|en] [command]
    council-open [topic-id] [--overwrite] [-n[=N|all]|--rounds[=N|all]] [--full] [-- handoff note]
    council-review {topic_id} [CONSENSUS] [-- review instruction]
    council-apply {topic_id} [-- apply instruction]
    council-status [topic-id|all] [--doctor]
    council-help [zh|en]
    council-version [--check]
    council-upgrade [--check|--apply] [--force] [--ref {git_ref}] [--claude-only|--codex-only]
    council-uninstall [--check|--apply] [--claude-only|--codex-only] [--remove-state]
    council-longrun [--show|--reset]

Use `council` as the top-level command index when you want a quick reminder or
are unsure which Council command to run.

Use `council-upgrade` to check standalone install versions.
It is check-only by default. Use `council-upgrade --apply` to update. Use
`council-upgrade --apply --force` for dirty standalone installs where stale or
partial commands remain. Add `--ref {git_ref}` only when you want a
specific branch, tag, or commit.

Use `council-version` to confirm which installed copy is active.

If `council-upgrade` completes but `council-help` still shows an old version,
the active command is usually from another standalone location or from a plugin
cache.

Use `council-uninstall --check` to preview standalone uninstall targets.
Nothing is deleted unless `--apply` is present. Add `--remove-state` only when
you also want to delete `.agent-council/` discussion state. Codex plugin
installs should use:

```sh
codex plugin remove agent-council@agent-council-marketplace
```

Use `council-status {topic_id} --doctor` to check lowercase path conflicts,
turn continuity, stale consensus, and status/consensus drift.

`council-open` can omit the topic id. If omitted, it generates a date-based id
such as `2026-06-03-1`.

Use `council-longrun` to configure explicit long-run assisted-judgment rules.
It asks in chat with three grouped choice tables: subagents, peer review, and
combined assistance. The default mix is `balanced` subagents, `strategic` peer
review, and `high_risk` combined assistance. That means subagents help with
moderate ambiguity, peer headless review helps with design/release/security/major
tradeoff checks, and both run for architecture, blockers, release/security
boundaries, broad scope changes, or hard-to-reverse choices. `council-longrun`
does not configure when to interrupt the user; when assisted judgment is clear,
inside the authorized scope, and no external hard gate applies, continue.

    $council-longrun
    $council-longrun --show

## Optional utility: council-peer

`council-peer` is not part of the Council main flow. It is a one-shot utility
for calling the peer tool headlessly.

From Codex, it runs Claude Code through `claude -p`. From Claude Code, it runs
Codex through `codex exec --sandbox read-only`.

It requires the peer CLI to be installed and available in `PATH`: `claude` from
Codex, or `codex` from Claude Code. It does not write Council topics or project
files by default.

If a substantive prompt is provided, it sends that prompt. If no substantive
prompt is provided, it uses the selected recent visible conversation rounds as
context and asks the peer for a focused one-shot review. Whitespace-only and
punctuation-only input do not count as a prompt.

A conversation round means one user message plus the immediately following
Codex or Claude Code reply. By default `council-peer` uses the latest 1
round as summarized context. Use `-n` / `--rounds` to choose more visible
rounds, and add `--full` only when the peer should receive the selected visible
text verbatim.

Range selection only uses visible user/assistant chat text. It does not include
system/developer instructions, tool schemas, hidden reasoning, or other
internal runtime context.

It cannot read an unlimited Codex or Claude chat transcript by itself. The
default headless review timeout is 600 seconds (10 minutes). Report timeout/no
output clearly.

It should also show status updates while running, including starting, elapsed
running time, completed, timed out, or no-output states.

If the peer command times out or returns no useful output, run
`$council-peer --diagnose`. Diagnose mode checks the detected peer command,
version, and a short read-only ping. It writes no files.

Examples:

    $council-peer
    $council-peer --diagnose
    $council-peer -n=3 "Review the recent plan for blockers."
    /council-peer --codex-model gpt-5 "Review the latest plan for blockers."
    $council-peer --rounds=all --full "Summarize the visible conversation and call out risks."
    $council-peer "Review docs/design.md for blockers."
    $council-peer --topic product-l1-gate "Review the latest Council handoff for blockers."

## Open a topic

    $council-open retry-design -- Use the latest visible round as the handoff.

Or let Council choose the topic id:

    $council-open -- Use the latest visible round as the handoff.

The skill writes the handoff under `.agent-council/active/retry-design/`.

A conversation round means one user message plus the immediately following
Codex or Claude Code reply. By default `council-open` uses the latest 1 visible
round. Use `-n` / `--rounds` to select more visible rounds:

    $council-open -n=10 -- Review the recent plan changes.
    $council-open retry-design --rounds=all --full -- Preserve the visible context and review blockers.

Latest handoffs should stay under 500 words or 20 bullets. Without `--full`,
compress selected rounds to decisions, evidence, blockers, open questions, and
requested peer focus. With `--full`, write full visible source text to a
separate `turns/{turn_number}-{agent}-open-full-context.md` attachment and keep
latest handoffs short.

Even in `--full` mode, only visible user/assistant chat text is eligible for
the attachment.

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
