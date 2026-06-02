# Agent Council

Agent Council is a small workflow package for teams that use Claude Code and Codex in the same repository.

It provides a manual review loop for designs, plans, source briefs, and implementation diffs. One tool can draft or implement, the other can review, and either tool can respond or apply the agreed changes. The user stays in control of how many rounds happen and which tool edits the formal artifact.

中文文档见 [README.zh-CN.md](README.zh-CN.md)。

## What it solves

Claude Code and Codex do not automatically share the same chat context. When work moves between them, important assumptions are often copied by hand or lost.

Agent Council solves this by writing compact handoff state into `.agent-council/`, grouped by topic id. Formal files such as `docs/design.md`, plans, tests, and source code stay clean. Discussion state, peer requests, decisions, and consensus stay in the Council workspace.

## How it works

A Council topic is a directory such as:

`.agent-council/active/retry-design/`

Each topic tracks:

- the artifact being reviewed;
- the current focus;
- the latest Claude Code and Codex positions;
- open questions;
- accepted, rejected, and deferred decisions;
- optional `source-brief.md` when the source context only exists in the current chat;
- final or user-forced consensus.

Only `council-apply` should change the formal artifact. `council-open`, `council-review`, `council-respond`, and `council-status` only write Council state.

## Included skills

- `council-open`
- `council-review`
- `council-respond`
- `council-apply`
- `council-status`
- `council-help`

## Local installation

Clone the repository, then install the standalone skills into a project repository:

```sh
./install.sh /path/to/your/project
```

If you are already in the target project root:

```sh
./install.sh .
```

Install only Claude Code skills:

```sh
./install.sh /path/to/your/project --claude-only
```

Install only Codex skills:

```sh
./install.sh /path/to/your/project --codex-only
```

The installer copies skills into:

- `.claude/skills/` for Claude Code;
- `.agents/skills/` for Codex.

Add this to the target project's `.gitignore` unless you want to commit Council state:

```text
.agent-council/
```

## Claude Code installation

### Option A: standalone project install

Use the local installer above. Then run the skills in Claude Code with short names:

```text
/council-help
/council-open retry-design docs/design.md -- This is the design stage of a structured workflow.
/council-review retry-design -- Review whether the design is ready for planning.
/council-respond retry-design
/council-apply retry-design
/council-status retry-design
```

### Option B: install as a Claude Code plugin

Add this repository as a Claude Code marketplace and install the plugin:

```text
/plugin marketplace add OWNER/REPO
/plugin install agent-council@agent-council-marketplace
/reload-plugins
```

Replace `OWNER/REPO` with the repository location that hosts this package.

When installed as a plugin, Claude Code namespaces skills with the plugin name:

```text
/agent-council:council-help
/agent-council:council-open retry-design docs/design.md -- This is the design stage of a structured workflow.
/agent-council:council-review retry-design
/agent-council:council-respond retry-design
/agent-council:council-apply retry-design
/agent-council:council-status retry-design
```

## Codex installation

### Option A: standalone project install

Use the local installer above. Then run the skills in Codex with explicit skill calls:

```text
$council-help
$council-open retry-design docs/design.md -- This is the design stage of a structured workflow.
$council-review retry-design -- Review whether the design is ready for planning.
$council-respond retry-design
$council-apply retry-design
$council-status retry-design
```

### Option B: install as a Codex plugin

Add this repository as a Codex marketplace:

```sh
codex plugin marketplace add OWNER/REPO
```

Then open Codex, run `/plugins`, choose the Agent Council marketplace, and install the `agent-council` plugin.

After installation, use the bundled skills explicitly:

```text
$council-help
$council-open retry-design docs/design.md -- This is the design stage of a structured workflow.
$council-review retry-design
$council-respond retry-design
$council-apply retry-design
$council-status retry-design
```

## Source brief mode

Use source brief mode when the useful context is still in the current chat and has not been written to a design or plan file.

From Claude Code or Codex:

```text
/council-open checkout-design brief docs/design.md design -- Summarize the current brainstorming conversation into source-brief.md before writing the design.
```

or in Codex:

```text
$council-open checkout-design brief docs/design.md design -- Summarize the current brainstorming conversation into source-brief.md before writing the design.
```

The peer tool can then review the brief:

```text
/council-review checkout-design -- Review whether the source brief is sufficient to write the design.
```

## Typical workflow

1. Tool A drafts or summarizes context.
2. Tool A runs `council-open`.
3. Tool B runs `council-review`.
4. Tool A runs `council-respond`.
5. Repeat review/respond only while useful.
6. Use `CONSENSUS` when you want to stop expanding the discussion.
7. The chosen tool runs `council-apply`.
8. Run one final review if the artifact changed significantly.

Example:

```text
$council-open retry-design docs/design.md -- This design should be ready before planning starts.
/council-review retry-design -- Use architect and senior engineer perspectives.
$council-respond retry-design -- Only answer blockers and major concerns.
/council-respond retry-design CONSENSUS -- Converge if only non-blocking issues remain.
$council-apply retry-design -- Apply only accepted decisions.
```

## Topic ids

A topic id is a short name for an isolated discussion. Use lowercase kebab-case.

Good examples:

- `retry-design`
- `checkout-plan`
- `search-index-review`

Avoid reusing the same topic id for unrelated work.

## Repository layout

```text
.claude-plugin/marketplace.json          Claude Code marketplace catalog
.agents/plugins/marketplace.json         Codex marketplace catalog
plugins/agent-council/                   Plugin package
plugins/agent-council/skills/            Shared skills
install.sh                               Local standalone installer
uninstall.sh                             Local standalone uninstaller
docs/                                    Usage and protocol notes
```

## Notes

- The workflow is manual by design. It does not automatically call the other tool.
- It does not replace human judgment, tests, or code review.
- Keep `.agent-council/` out of version control unless your team explicitly wants to keep the discussion record.
