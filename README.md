# Agent Council

Current version: 2.3.0

Agent Council is a small workflow package for people who use Claude Code and Codex in the same repository.

It provides a lightweight, manual bridge between the two tools. One tool can write a proposal, plan, review, or next-step recommendation. The other tool can review the latest handoff without needing the original chat history.

Agent Council is intentionally simple:

- `council-open` starts a topic and records the current handoff.
- `council-review` reads the peer's latest handoff and replies.
- `council-apply` is the only action that should change project files.
- `council-status` shows the current state.
- `council-help` explains usage.
- `council-upgrade` updates standalone installs.

`council-respond` was removed in v2.0.2. Use `council-review` for review, response, rebuttal, confirmation, and consensus. The installer also cleans stale standalone `council-respond` installs from older versions.

Agent Council should stay focused on the user's topic. Unless the topic itself is Agent Council, reviews should not analyze Council protocol, file layout, skill behavior, or the workflow mechanics.

## What problem it solves

Claude Code and Codex do not share the same chat window. When you move work between them, the latest reasoning or recommendation is easy to lose.

Agent Council writes the latest handoff into `.agent-council/active/<topic-id>/`. The peer tool reads that file, reviews the actual topic, and writes its own latest reply back to the same topic.

Formal project files stay clean. The Council directory is only a communication bridge.

## How it works

A topic is an isolated discussion, for example:

    .agent-council/active/retry-design/

A topic stores:

- `topic.md`: short topic note and initial handoff.
- `latest/codex.md`: the latest Codex message for Claude Code.
- `latest/claude.md`: the latest Claude Code message for Codex.
- `latest/for-peer.md`: the current handoff that the peer should read next.
- `turns/`: recent turn records for traceability.
- `consensus.md`: final agreed result, if one is reached.
- `status.md`: current state.

By default, skills read only the current topic and the peer's latest message. They should not scan the whole history unless you explicitly ask.

## Lightweight Guardrails

Agent Council stays lightweight, but uses a few guardrails to reduce drift:

- Agent ids are canonical lowercase: `claude` and `codex`.
- File paths must use lowercase agent ids, such as `latest/claude.md`, `latest/codex.md`, and `turns/0005-claude-review.md`.
- `council-review` and `council-open` may write only `.agent-council/` files.
- `council-apply` is the only command that may modify formal project files.
- User-facing command responses include a short `Side effects` summary.
- `council-status <topic-id> --doctor` checks common consistency problems without turning Council into a strict workflow engine.

The bridge should remain a low-friction shared notepad with guardrails, not a heavy process manager.

## Topic States

`status.md` uses a small state set:

- `REVIEW_REQUESTED`: a handoff is ready for the peer to review.
- `DISCUSSION`: both tools are still exchanging substantive points.
- `CONSENSUS`: both sides naturally agree. There are no blockers and no disputed decisions, so peer review can stop.
- `CONSENSUS_WITH_NITS`: both sides agree on direction and only non-blocking small issues remain. Another peer-review round is usually not useful; apply or move to the next stage.
- `USER_FORCED_CONSENSUS`: the user explicitly passed `CONSENSUS` to stop discussion, but unresolved issues may remain. Record that this was user-forced; do not present it as natural agreement.
- `NEEDS_DISCUSSION`: the peer still needs to answer specific questions. The response must tell the user which tool should run which `council-review` command next.
- `USER_DECISION_NEEDED`: the tools cannot decide, or there is a product or tradeoff choice. Stop the peer loop and ask the user to decide.
- `BLOCKED`: there is a blocking safety, data-loss, rollback, requirement, or evidence issue. Do not apply unless the user explicitly overrides the risk.
- `APPLIED`: the consensus has been applied to formal project files.
- `CLOSED`: the topic is closed and should not be reviewed unless the user reopens it.
- `ABANDONED`: the topic was abandoned and should not be reviewed unless the user reopens it.

The stable `status.md` shape is:

```yaml
topic: product-l1-gate
state: REVIEW_REQUESTED
turn: 1
last_agent: codex
next_agent: claude
updated_at: 2026-06-03T12:00:00Z
latest_handoff: latest/for-peer.md
consensus:
```

## Consensus Usage

Use `CONSENSUS` when you want a tool to decide whether the discussion can stop:

```text
$council-review product-l1-gate CONSENSUS -- If you agree there are no blockers, converge and preserve the status/evidence matrix requirement.
```

This does not mean the model should blindly declare agreement.

- If no blocker remains, write `CONSENSUS` or `CONSENSUS_WITH_NITS`.
- If disagreements remain but the user explicitly wants to stop, write `USER_FORCED_CONSENSUS`.
- If a serious blocker remains, state the risk and ask the user whether to explicitly override it.

When `council-review` finishes, it always ends with `Next action`. If the state is `NEEDS_DISCUSSION`, it gives the exact command for the other tool. If the state is `CONSENSUS` or `CONSENSUS_WITH_NITS`, it says no further peer-review round is recommended and suggests `council-apply` as an optional next step.

`disable-model-invocation: true` only means Claude Code will not auto-trigger a skill. It does not prevent a skill from telling the user what command to run next. Next-step guidance is controlled by `council-review`'s output rules.

Consensus files should stay short and stable:

```markdown
---
topic: product-l1-gate
state: CONSENSUS_WITH_NITS
agent: codex
turn: 6
formal_files_modified: false
---

# Consensus

Verdict: CONSENSUS_WITH_NITS

## Decision

Ready for:
- writing-plans

Not authorized:
- code changes
- completion claim

## Blockers

None.

## Must-Preserve Nits

1. Keep owner decisions separate from implementation tasks.
2. Preserve abnormal-case terminal semantics.

## Side Effects

Formal project files modified:
- none
```

Turn records and `consensus.md` may use lightweight YAML frontmatter. Keep it short: `topic`, `agent`, `turn`, `state` or `verdict`, and whether formal files were modified are enough for the default flow.

## Local installation

Install the standalone skills into a project repository:

    ./install.sh /path/to/your/project

If you are already in the target project root:

    ./install.sh .

Install only Claude Code skills:

    ./install.sh /path/to/your/project --claude-only

Install only Codex skills:

    ./install.sh /path/to/your/project --codex-only

The installer copies skills into:

- `.claude/skills/` for Claude Code.
- `.agents/skills/` for Codex.

When upgrading from v1, run the installer again. It overwrites the active skills and removes stale standalone `council-respond` directories from both `.claude/skills/` and `.agents/skills/`.

After v2.1.0 or newer is installed, standalone users can upgrade later with:

    /council-upgrade
    $council-upgrade

Add this to the target project's `.gitignore` unless your team wants to keep local discussion state:

    .agent-council/

## Claude Code installation

### Option A: standalone project install

Use the local installer above. Then run the skills in Claude Code with short names:

    /council-help
    /council-open retry-design -- Use the latest answer as the handoff for peer review.
    /council-review retry-design -- Check whether the proposed next step is safe.
    /council-review retry-design CONSENSUS -- Converge if only non-blocking issues remain.
    /council-apply retry-design -- Apply the agreed result to the relevant files.
    /council-status retry-design
    /council-upgrade --check

### Option B: install as a Claude Code plugin

Add this repository as a Claude Code marketplace and install the plugin:

    /plugin marketplace add bhswallow/agent-council
    /plugin install agent-council@agent-council-marketplace
    /reload-plugins

When upgrading an older plugin install, uninstall the old plugin first if your plugin manager still shows `council-respond`, then install again and reload plugins.

When installed as a plugin, Claude Code namespaces skills with the plugin name:

    /agent-council:council-help
    /agent-council:council-open retry-design -- Use the latest answer as the handoff for peer review.
    /agent-council:council-review retry-design
    /agent-council:council-apply retry-design
    /agent-council:council-status retry-design
    /agent-council:council-upgrade --check

## Codex installation

### Option A: standalone project install

Use the local installer above. Then run the skills in Codex with explicit skill calls:

    $council-help
    $council-open retry-design -- Use the latest answer as the handoff for peer review.
    $council-review retry-design -- Check whether the proposed next step is safe.
    $council-review retry-design CONSENSUS -- Converge if only non-blocking issues remain.
    $council-apply retry-design -- Apply the agreed result to the relevant files.
    $council-status retry-design
    $council-upgrade --check

### Option B: install as a Codex plugin

Add this repository as a Codex marketplace:

    codex plugin marketplace add bhswallow/agent-council

Then open Codex, run `/plugins`, choose the Agent Council marketplace, and install the `agent-council` plugin.

When upgrading an older plugin install, remove the old `agent-council` plugin in `/plugins` first if `council-respond` is still listed, then install it again from the marketplace.

After installation, use the bundled skills explicitly:

    $council-help
    $council-open retry-design -- Use the latest answer as the handoff for peer review.
    $council-review retry-design
    $council-apply retry-design
    $council-status retry-design
    $council-upgrade --check

## Basic workflow

Tool A opens a topic:

    $council-open retry-plan -- I changed the retry plan. Please ask the peer to review whether the next step is reasonable.

Tool B reviews the latest handoff:

    /council-review retry-plan -- Focus on risks and whether we should proceed.

Tool A reviews the reply:

    $council-review retry-plan -- Respond to the peer's blockers only.

When the discussion is ready to stop:

    /council-review retry-plan CONSENSUS -- If only non-blocking issues remain, write the final agreed result.

Then choose one tool to apply the result:

    $council-apply retry-plan -- Apply the consensus to docs/design.md.

## Topic ids

A topic id is a short name for an isolated discussion. Use lowercase kebab-case.

Good examples:

- `retry-design`
- `product-l1-gate`
- `checkout-plan`
- `search-index-review`
- `retry-plan`

Avoid reusing the same topic id for unrelated work.

## Principles

- Keep the discussion focused on the topic, not on the Council workflow.
- Read the peer's latest handoff by default, not the full history.
- Keep formal project files separate from Council state.
- Use `council-apply` for changes to project files.
- Use `CONSENSUS` when you want to stop expanding the discussion.

## Repository layout

    .claude-plugin/marketplace.json          Claude Code marketplace catalog
    .agents/plugins/marketplace.json         Codex marketplace catalog
    plugins/agent-council/                   Plugin package
    plugins/agent-council/skills/            Shared skills
    install.sh                               Local standalone installer
    uninstall.sh                             Local standalone uninstaller
    docs/                                    Usage and protocol notes

## Notes

The workflow is manual by design. It does not automatically call the other tool.

It does not replace human judgment, tests, or normal code review.
