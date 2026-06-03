# Agent Council

Current version: 2.5.2

Agent Council is a lightweight, manual latest-turn bridge for Claude Code and
Codex. It records what one tool wants the other to review, lets the peer reply,
and preserves consensus without polluting project files.

It does not automatically call another tool. It is a small shared notepad with
guardrails, not a workflow engine.

## Commands

Agent Council keeps the main flow intentionally small:

- `council-open` starts a topic and records the current handoff.
  The topic id is optional.
- `council-review` reads the peer's latest handoff and replies.
- `council-apply` applies an agreed result to formal project files.
- `council-status` shows topic state, with an optional `--doctor` check.
- `council-help` shows concise usage help.
- `council-version` prints the installed version.
- `council-upgrade` checks for updates and can update standalone installs when
  explicitly run with `--apply`.

`council-respond` was removed in v2.0.2. Use `council-review` for review,
response, rebuttal, confirmation, and consensus. The installer also removes
stale standalone `council-respond` directories from older versions.

Agent Council should stay focused on the user's topic. Unless the topic itself
is Agent Council, reviews should not analyze Council protocol, file layout,
skill behavior, or workflow mechanics.

## What It Solves

Claude Code and Codex do not share the same chat window. When work moves
between them, the latest reasoning, recommendation, or risk callout is easy to
lose.

Agent Council writes the latest handoff into:

```text
.agent-council/active/{topic_id}/
```

The peer tool reads that latest handoff, reviews the actual topic, and writes
its reply back to the same topic.

Formal project files stay clean until `council-apply`.

## Choosing A Bridge

Agent Council complements direct invocation tools; it does not replace them.

| Tool | Solves | Strengths | Tradeoffs | Choose When |
| --- | --- | --- | --- | --- |
| Agent Council | Manual latest-turn handoff, peer review, consensus capture | Auditable files, low setup, no hidden cross-agent call, project files stay clean until `council-apply` | User runs the next command manually; not instant; does not fetch the peer answer automatically | You need a durable decision trail and a clear apply boundary |
| Codex-in-Claude plugin | Call Codex from Claude Code for one-off review or alternatives | Fast second opinion without leaving Claude Code | More setup, possible token/API cost, less durable unless recorded | Speed matters more than an auditable handoff |
| Claude-in-Codex via `claude -p` | Call Claude Code non-interactively from Codex | Good for scripted checks, JSON review, CI-like one-shot tasks | Prompt/context packaging matters; Claude auth, billing, and limits are separate | The task is naturally a one-shot scripted Claude call |

You can combine them: use direct invocation for quick checks, then use Agent
Council only when the result should become a shared decision.

References:

- Codex `/plugins` and Codex plugin documentation in your installed Codex app.
- [Claude Code CLI reference](https://code.claude.com/docs/en/cli-usage)
- [Run Claude Code programmatically](https://code.claude.com/docs/en/headless)

## Topic Files

A topic is an isolated discussion, for example:

```text
.agent-council/active/retry-design/
```

Typical files are:

- `topic.md`: short topic note and initial handoff.
- `latest/codex.md`: the latest Codex message for Claude Code.
- `latest/claude.md`: the latest Claude Code message for Codex.
- `latest/for-peer.md`: the handoff the peer should read next.
- `latest/user-request.md`: the latest user instruction for this turn.
- `turns/`: compact turn records for traceability.
- `consensus.md`: final agreed result, if one is reached.
- `status.md`: current state.

By default, skills read only the current topic and the peer's latest message.
They should not scan all turns, archives, or unrelated project files unless you
explicitly ask.

## Lightweight Guardrails

Agent Council stays lightweight, but it uses a few high-value guardrails:

- `council-open` can generate a topic id when the user omits one.
- Agent ids are canonical lowercase: `claude` and `codex`.
- Paths use lowercase agent ids:
  `latest/claude.md`, `latest/codex.md`, and
  `turns/0005-claude-review.md`.
- Latest handoffs should stay under 500 words or 20 bullets.
- `council-open` and `council-review` may write only `.agent-council/`.
- `council-apply` is the only command that may modify formal project files.
- Command responses include a short `Side effects` summary.
- `council-status {topic_id} --doctor` checks common consistency problems.

The goal is a low-friction bridge with guardrails, not a strict state machine.

## Automatic Topic Ids

You can name a topic yourself:

```text
$council-open product-l1-gate -- Please review the gate criteria.
```

You can also omit the topic id:

```text
$council-open -- Please review the latest plan.
```

When no topic id is provided, `council-open` generates one without asking.
The default format is date-based:

```text
2026-06-03-1
2026-06-03-2
```

If the handoff note contains an obvious short subject, a concise slug such as
`review-l1-spike` is also fine. Naming should not become a blocking step.

## Handoff Size Budget

The bridge reads latest turns by default, so latest files must stay short.

When writing `latest/{agent}.md` and `latest/for-peer.md`, keep the handoff
within:

- 500 words; or
- 20 bullets.

If the source turn is longer, compress it to:

- decisions;
- evidence;
- blockers;
- open questions;
- requested peer focus.

Do not carry old detail forward just because it was present in a previous latest
handoff.

## Topic States

`status.md` uses a small state set:

- `REVIEW_REQUESTED`: a handoff is ready for the peer to review.
- `DISCUSSION`: both tools are still exchanging substantive points.
- `CONSENSUS`: both sides naturally agree. There are no blockers and no
  disputed decisions, so peer review can stop.
- `CONSENSUS_WITH_NITS`: both sides agree on direction and only non-blocking
  small issues remain. Another peer-review round is usually not useful.
- `USER_FORCED_CONSENSUS`: the user explicitly passed `CONSENSUS` to stop
  discussion, but unresolved issues may remain. Record that this was
  user-forced; do not present it as natural agreement.
- `NEEDS_DISCUSSION`: the peer still needs to answer specific questions. The
  response must tell the user which tool should run which `council-review`
  command next.
- `USER_DECISION_NEEDED`: the tools cannot decide, or there is a product or
  tradeoff choice. Stop the peer loop and ask the user to decide.
- `BLOCKED`: there is a blocking safety, data-loss, rollback, requirement, or
  evidence issue. Do not apply unless the user explicitly overrides the risk.
- `APPLIED`: the consensus has been applied to formal project files.
- `CLOSED`: the topic is closed and should not be reviewed unless the user
  reopens it.
- `ABANDONED`: the topic was abandoned and should not be reviewed unless the
  user reopens it.

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

Allowed `state` values include:

```text
REVIEW_REQUESTED
DISCUSSION
NEEDS_DISCUSSION
CONSENSUS
CONSENSUS_WITH_NITS
USER_FORCED_CONSENSUS
USER_DECISION_NEEDED
BLOCKED
APPLIED
CLOSED
ABANDONED
```

## Consensus Usage

Use `CONSENSUS` when you want a tool to decide whether the discussion can stop:

```text
$council-review product-l1-gate CONSENSUS -- \
  If you agree there are no blockers, converge and preserve the status/evidence matrix requirement.
```

This does not mean the model should blindly declare agreement.

- If no blocker remains, write `CONSENSUS` or `CONSENSUS_WITH_NITS`.
- If disagreements remain but the user explicitly wants to stop, write
  `USER_FORCED_CONSENSUS`.
- If a serious blocker remains, state the risk and ask the user whether to
  explicitly override it.

When `council-review` finishes, it always ends with `Next action`.

If the state is `NEEDS_DISCUSSION`, it gives the exact command for the other
tool.

If the state is `CONSENSUS` or `CONSENSUS_WITH_NITS`, it says:

```text
No further peer-review round is recommended.
```

It may then suggest:

```text
$council-apply {topic_id} -- Apply the consensus.
```

If the state is `USER_DECISION_NEEDED`, it lists the decisions the user must
make. It should not route another peer-review round.

If the state is `BLOCKED`, it says apply is not allowed unless the user
explicitly overrides the risk.

`disable-model-invocation: true` only means Claude Code will not auto-trigger a
skill. It does not affect whether the skill tells the user what command to run
next. Next-step guidance is controlled by `council-review` output rules.

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

Turn records and `consensus.md` may use lightweight YAML frontmatter. Keep it
short: `topic`, `agent`, `turn`, `state` or `verdict`, and whether formal files
were modified are enough for the default flow.

## Installation

Install the standalone skills into a project repository:

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

- `.claude/skills/` for Claude Code.
- `.agents/skills/` for Codex.

When upgrading from v1, run the installer again. It overwrites the active
standalone skills and removes stale standalone `council-respond` directories.

Add this to the target project's `.gitignore` unless your team wants to keep
local discussion state:

```gitignore
.agent-council/
```

## Checking The Version

After installing or upgrading, run:

```text
/council-version
$council-version
```

Use `--check` to compare the installed version with the repository version:

```text
/council-version --check
$council-version --check
```

If `council-upgrade` finishes but `council-help` still shows an old version, the
active command is usually coming from another install location or from a plugin
cache. Run `council-version` in the same tool to confirm the active copy.

For standalone installs, `council-upgrade` is check-only by default. To update,
run it again from the active project or home install with `--apply`. Use
`--ref {git_ref}` only when you intentionally want a specific branch, tag, or
commit.

For plugin installs, reinstall the `agent-council` plugin from the marketplace
and reload plugins.

## Claude Code

### Standalone Project Install

Use the installer above. Then run the skills in Claude Code with short names:

```text
/council-help
/council-version
/council-open -- Use the latest answer as the handoff for peer review.
/council-open retry-design -- Use the latest answer as the handoff for peer review.
/council-review retry-design -- Check whether the proposed next step is safe.
/council-review retry-design CONSENSUS -- Converge if only non-blocking issues remain.
/council-apply retry-design -- Apply the agreed result to the relevant files.
/council-status retry-design
/council-status retry-design --doctor
/council-upgrade --check
/council-upgrade --apply
```

### Claude Code Plugin

Add this repository as a Claude Code marketplace and install the plugin:

```text
/plugin marketplace add bhswallow/agent-council
/plugin install agent-council@agent-council-marketplace
/reload-plugins
```

When installed as a plugin, Claude Code namespaces skills with the plugin name:

```text
/agent-council:council-help
/agent-council:council-version
/agent-council:council-open -- Use the latest answer as the handoff for peer review.
/agent-council:council-open retry-design -- Use the latest answer as the handoff for peer review.
/agent-council:council-review retry-design
/agent-council:council-apply retry-design
/agent-council:council-status retry-design
/agent-council:council-upgrade --check
```

When upgrading an older plugin install, remove the old plugin if the plugin
manager still shows `council-respond`, install again, and reload plugins.

## Codex

### Standalone Project Install

Use the installer above. Then run the skills in Codex with explicit skill calls:

```text
$council-help
$council-version
$council-open -- Use the latest answer as the handoff for peer review.
$council-open retry-design -- Use the latest answer as the handoff for peer review.
$council-review retry-design -- Check whether the proposed next step is safe.
$council-review retry-design CONSENSUS -- Converge if only non-blocking issues remain.
$council-apply retry-design -- Apply the agreed result to the relevant files.
$council-status retry-design
$council-status retry-design --doctor
$council-upgrade --check
$council-upgrade --apply
```

### Codex Plugin

Add this repository as a Codex marketplace:

```sh
codex plugin marketplace add bhswallow/agent-council
```

Then open Codex, run `/plugins`, choose the Agent Council marketplace, and
install the `agent-council` plugin.

After installation, use the bundled skills explicitly:

```text
$council-help
$council-version
$council-open -- Use the latest answer as the handoff for peer review.
$council-open retry-design -- Use the latest answer as the handoff for peer review.
$council-review retry-design
$council-apply retry-design
$council-status retry-design
$council-upgrade --check
```

When upgrading an older plugin install, remove the old plugin if `/plugins`
still lists `council-respond`, install again, and restart or reload Codex.

## Basic Workflow

Tool A opens a topic:

```text
$council-open retry-plan -- I changed the retry plan. Please ask the peer to review whether the next step is reasonable.
```

Or let Council choose the topic id:

```text
$council-open -- I changed the retry plan. Please ask the peer to review whether the next step is reasonable.
```

Tool B reviews the latest handoff:

```text
/council-review retry-plan -- Focus on risks and whether we should proceed.
```

Tool A reviews the reply:

```text
$council-review retry-plan -- Respond to the peer's blockers only.
```

When the discussion is ready to stop:

```text
/council-review retry-plan CONSENSUS -- If only non-blocking issues remain, write the final agreed result.
```

Then choose one tool to apply the result:

```text
$council-apply retry-plan -- Apply the consensus to docs/plan.md.
```

## Topic Ids

A topic id is a short name for an isolated discussion. It is optional for
`council-open`.

When provided, use lowercase kebab-case.

Good examples:

- `retry-design`
- `product-l1-gate`
- `checkout-design`
- `search-index-review`
- `retry-plan`
- `2026-06-03-1`

Avoid reusing the same topic id for unrelated work.

## Principles

- Keep the discussion focused on the topic, not on the Council workflow.
- Read the peer's latest handoff by default, not the full history.
- Keep formal project files separate from Council state.
- Use `council-apply` for changes to project files.
- Use `council-version` to confirm which installed copy is active.
- Use `CONSENSUS` when you want to stop expanding the discussion.

## Repository Layout

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

The workflow is manual by design. It does not automatically call the other tool.

It does not replace human judgment, tests, or normal code review.
