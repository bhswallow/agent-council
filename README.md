# Agent Council

Current version: 2.8.0

Agent Council is a lightweight, manual latest-turn bridge for Claude Code and
Codex. It records what one tool wants the other to review, lets the peer reply,
and preserves consensus without polluting project files.

It does not automatically call another tool. It is a small shared notepad with
guardrails, not a workflow engine.

It is human-invoked by design. Council must not automatically stop tasks,
create topics, or insert itself between normal task steps.

## Commands

Agent Council keeps the review loop intentionally small:

- `council-open` starts a topic and records the current handoff.
  The topic id is optional.
- `council-review` reads the peer's latest handoff and replies.
- `council-apply` applies an agreed result to formal project files.
- `council-status` shows topic state, with an optional `--doctor` check.

Support commands are also explicit:

- `council-help` shows concise usage help.
- `council-version` prints the installed version.
- `council-upgrade` checks for updates and can update standalone installs when
  explicitly run with `--apply`.
- `council-longrun` configures explicit long-run self-review and human-pause
  rules.

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

## Manual Invocation Boundary

Council is opt-in. Agents and workflows should not open Council automatically,
even when they notice risk. If a human-gated point appears, pause for the human
gate first; the user may then choose to involve Council.

Council may:

- record a handoff when the user runs `council-open`;
- review a topic when the user runs `council-review`;
- preserve consensus for that topic;
- apply agreed changes only when the user runs `council-apply`.

Council must not:

- act as an automatic task gate;
- stop or block unrelated task execution by itself;
- create a Council topic for every task;
- decide that a human gate requires Council;
- chain from one finished topic into the next task automatically.

`council-longrun` is the exception only in this narrow sense: it can record
user-approved long-run rules after the user explicitly runs it. It still does
not start tasks, create Council topics, commit, push, merge, deploy, or override
human gates by itself.

After a topic reaches consensus, blocked, closed, abandoned, or applied state,
control returns to the normal user/tool workflow. Any next task starts only from
the user's ordinary task instructions, not from Council.

## Optional Workflow Reminders

Outer workflows such as `CLAUDE.md`, `AGENTS.md`, Superpowers, or project memory
may briefly remind the user that Council is available at useful phase
boundaries:

- after brainstorming;
- after writing design;
- after writing plans;
- after writing specs;
- after a planned task batch completes;
- when the workflow is blocked or needs a human decision.

These reminders are optional and must match the user's current language. If the
user is working in Chinese, remind in Chinese. If the user is working in
English, remind in English.

The reminder must not invoke Council, stop execution by itself, or imply that
Council is required. If the user does not ask for Council, continue with the
approved workflow.

Example:

```text
Design complete.
Optional: you can manually run Council for peer review:
$council-open checkout-design -- Review the completed design.

Continuing without Council unless you ask for it.
```

## Longrun Rules

Use `council-longrun` when you want to define how future authorized long-running
work should self-review with less repeated human input:

```text
$council-longrun
```

The skill asks a few short multiple-choice questions, then saves the active
rules to:

```text
.agent-council/longrun/rules.md
```

The rules decide which events should:

- continue by self-judgment;
- use subagents;
- use `council-claude-p`;
- use both subagents and `council-claude-p`;
- pause for a human decision.

Recommended defaults are:

- mode: `balanced`;
- `council-claude-p`: strategic or high-risk checks only;
- human pause: irreversible gates such as commit, push, merge, deploy, deleting
  data, permission/security changes, accepting blockers, or expanding scope.

Run `council-longrun` again to redefine the rules. Run
`council-longrun --show` to inspect the active rules.

These rules apply only when the user has already authorized ongoing work. They
do not authorize new scope, formal project changes outside the task, or
irreversible operations.

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

## Optional Utility: council-claude-p

`council-claude-p` is an optional utility skill, not part of the Agent Council main
flow. The Council flow remains `council-open`, `council-review`,
`council-apply`, `council-status`, and `council-help`.

`council-claude-p` wraps the Claude Code native headless command `claude -p`. That
command comes from Claude Code / Anthropic, not Codex or OpenAI.

Requirements and boundaries:

- The user-facing Agent Council skill command is `council-claude-p`.
- The underlying subprocess is Claude Code's native `claude -p`.
- Claude Code CLI must already be installed.
- The local `claude` command must be available in `PATH`.
- It does not require Codex CLI.
- It does not install or configure Claude Code.
- It receives only the prompt/context selected by the skill; it cannot read an
  unlimited current Codex or Claude Code chat transcript by itself.
- It does not write Council topics by default.
- It does not modify project files by default.
- It does not declare consensus or trigger `council-apply`.
- It should use a bounded timeout and report a timeout rather than pretending a
  Claude analysis was produced.
- The default headless review timeout is 600 seconds (10 minutes).
- It supports `--diagnose` for a short CLI/auth/ping check when `claude -p`
  times out or returns no output.
- It should show status updates while running: `starting`, `running`,
  `completed`, or `timed out` / `no output`.

Examples:

```text
$council-claude-p
$council-claude-p --diagnose
$council-claude-p "Review docs/design.md for blockers and missing tests."
$council-claude-p --output-format json "Summarize the current repository risks."
$council-claude-p --allowed-tools "Read,Grep,Glob" "Review docs/design.md for blockers."
$council-claude-p --topic product-l1-gate "Review the latest Council handoff for blockers."
```

If you run `$council-claude-p` with no substantive text after the command,
whitespace or punctuation-only input is ignored. The skill uses the most recent
substantive visible chat message as context and asks Claude for a focused
one-shot review, for example blockers, missing assumptions, risks, and whether
it is reasonable to proceed. It should adapt the question to the current topic
and language instead of using a fixed template.

Use `--topic {topic_id}` only when you explicitly want to save the result under:

```text
.agent-council/active/{topic_id}/latest/council-claude-p.md
```

That saved file is an external `council-claude-p` attachment under the topic. It is not
the same as an interactive Claude Code Council review. To enter the standard
Council peer-review loop, manually run `council-open` / `council-review`.

If you want Claude to summarize a longer previous chat, paste the relevant
content into the prompt or save it to a file and reference the file. A headless
`claude -p` call only receives the prompt/context selected by the skill; it
cannot read an unlimited surrounding Codex chat transcript by itself.

`council-claude-p` should not leave you staring at a blank wait. It should announce when
the headless process starts, report elapsed time while it is still running, and
clearly say whether it completed, timed out, or returned no output.

If it times out or returns no useful output, run:

```text
$council-claude-p --diagnose
```

Diagnose mode checks the local `claude` path, `claude --version`, and a short
read-only `claude -p` ping. It does not write Council topics or project files.

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

Council next-step guidance is advisory and topic-scoped. It must not be treated
as permission to stop, resume, chain, commit, push, merge, deploy, or enter the
next task. Those decisions remain normal user/tool workflow decisions.

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
