# Agent Council

Agent Council is a small workflow package for people who use Claude Code and Codex in the same repository.

It provides a lightweight, manual bridge between the two tools. One tool can write a proposal, plan, review, or next-step recommendation. The other tool can review the latest handoff without needing the original chat history.

Agent Council is intentionally simple:

- `council-open` starts a topic and records the current handoff.
- `council-review` reads the peer's latest handoff and replies.
- `council-apply` is the only action that should change project files.
- `council-status` shows the current state.
- `council-help` explains usage.

`council-respond` was removed in v2.0.2. Use `council-review` for review, response, rebuttal, confirmation, and consensus.

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

## Codex installation

### Option A: standalone project install

Use the local installer above. Then run the skills in Codex with explicit skill calls:

    $council-help
    $council-open retry-design -- Use the latest answer as the handoff for peer review.
    $council-review retry-design -- Check whether the proposed next step is safe.
    $council-review retry-design CONSENSUS -- Converge if only non-blocking issues remain.
    $council-apply retry-design -- Apply the agreed result to the relevant files.
    $council-status retry-design

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

## Basic workflow

Tool A opens a topic:

    $council-open retry-design -- I changed the retry plan. Please ask the peer to review whether the next step is reasonable.

Tool B reviews the latest handoff:

    /council-review retry-design -- Focus on risks and whether we should proceed.

Tool A reviews the reply:

    $council-review retry-design -- Respond to the peer's blockers only.

When the discussion is ready to stop:

    /council-review retry-design CONSENSUS -- If only non-blocking issues remain, write the final agreed result.

Then choose one tool to apply the result:

    $council-apply retry-design -- Apply the consensus to docs/design.md.

## Topic ids

A topic id is a short name for an isolated discussion. Use lowercase kebab-case.

Good examples:

- `retry-design`
- `checkout-plan`
- `search-index-review`

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
