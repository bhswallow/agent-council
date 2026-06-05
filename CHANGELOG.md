# Changelog

## 2.10.4

- Removed `disable-model-invocation: true` from Council skills so explicit
  Codex commands such as `$council-peer-p` remain visible after plugin install.
- Kept `allow_implicit_invocation: false` in Codex metadata so Council skills
  remain user-invoked and do not auto-trigger.

## 2.10.3

- Added `council-uninstall` for explicit check/apply uninstall workflows.
- Made `uninstall.sh` dry-run by default; pass `--apply` to remove standalone
  skills and `--remove-state` to remove `.agent-council/` state.
- Changed `council-longrun` option presentation to three grouped tables with
  consistent `A` / `B` / `C` choices, and clarified that users can reply in
  chat instead of using a blocking chooser.
- Refocused `council-longrun` on assisted judgment: configure when to use
  subagents, `council-peer-p`, or both, without configuring human interruption
  or git-finalization policy.

## 2.10.2

- Added `council-upgrade --apply --force` guidance for dirty standalone
  installs, including cases where deprecated `claude-p` remains or replacement
  commands are missing.
- Updated `install.sh` to accept `--force`, always clean known deprecated
  standalone commands, and verify `council-peer-p` / `council-claude-p` are
  installed.
- Clarified that `claude-p` is deprecated, with `council-peer-p` as the
  preferred replacement and `council-claude-p` as the compatibility alias.
- Kept plugin installs under plugin-manager control: force upgrade reports
  reinstall/reload guidance instead of editing plugin caches.

## 2.10.1

- Expanded `council-longrun` prompts with localized, concrete explanations for
  every mode, peer review, and human-pause/git option.
- Changed the recommended human-pause/git policy to `git_safe`, allowing
  user-requested precise add/commit/push after checks pass while still pausing
  for force-push, merge/rebase, release/deploy, broad staging, destructive
  actions, unclear branch/remote, and unrequested git operations.
- Updated longrun rules schema guidance to write `peer_review_policy` and
  `use_peer_p`, with old `claude_p_policy`, `use_claude_p`, and
  `irreversible` rules treated as legacy migration-only fields.
- Added validation to prevent vague longrun option prompts and to keep normal
  requested commit/push out of the default pause lists.

## 2.10.0

- Tightened the README first screen with a short positioning statement, quick
  install paths, a three-command demo, and a security model summary.
- Added repository health files: `SECURITY.md`, `CONTRIBUTING.md`,
  `CODE_OF_CONDUCT.md`, issue templates, and a PR template.
- Added `docs/RELEASE_AND_DISCOVERY.md` with release, demo, GitHub topic,
  Claude directory, and Codex marketplace/community checklists.
- Added `council-peer-p` as the neutral peer-headless utility command.
- Kept `council-claude-p` as a backward-compatible alias.
- From Codex, the utility continues to call Claude Code through `claude -p`.
- From Claude Code, the utility now calls Codex through
  `codex exec --sandbox read-only`.
- Added Codex-specific peer options such as `--codex-model`,
  `--codex-profile`, and `--codex-sandbox`.
- `council-peer-p --topic` saves to `latest/council-peer-p.md`; the historical
  `council-claude-p` alias keeps `latest/council-claude-p.md`.

## 2.9.0

- Added `-n` / `--rounds` and `--full` context selection to `council-open`
  and `council-claude-p`.
- Defined a conversation round as one user message plus the immediately
  following Codex or Claude Code reply.
- Kept `council-open --full` lightweight by storing full visible source text in
  a separate `open-full-context.md` attachment while latest handoffs remain
  compact.
- Updated docs, help, protocol, and validation from latest-turn wording to
  recent-round behavior.

## 2.8.0

- Added `council-longrun` to configure explicit long-run self-review rules with
  short choices.
- Longrun rules define when future authorized work should self-judge, use
  subagents, use `council-claude-p`, use both, or pause for a human decision.
- Rules are stored under `.agent-council/longrun/` and do not create normal
  Council topics or modify formal project files.

## 2.7.5

- Increased the default `council-claude-p` headless review timeout from 120
  seconds to 600 seconds (10 minutes).
- Kept `--diagnose` ping checks short so troubleshooting remains fast.

## 2.7.4

- Added `council-claude-p --diagnose` for checking the local `claude` path,
  `claude --version`, and a short read-only `claude -p` ping.
- Improved timeout/no-output guidance so users get actionable next steps when
  Claude Code headless mode hangs or returns nothing.

## 2.7.3

- Updated `council-claude-p` so an empty, whitespace-only, or
  punctuation-only invocation uses the most recent substantive visible chat
  message as context for a focused Claude Code headless review.
- Clarified that `claude -p` receives the selected prompt/context only, not an
  unlimited chat transcript.

## 2.7.2

- Renamed the optional Claude Code headless utility from `claude-p` to
  `council-claude-p` so its command prefix matches the other Agent Council
  skills.
- Updated standalone install and uninstall scripts to remove stale `claude-p`
  skill directories from v2.7.0 and v2.7.1 installs.

## 2.7.1

- Clarified `claude-p` context boundaries: `claude -p` only receives the
  explicit prompt and cannot automatically see the current Codex or Claude chat.
- Added timeout and hang-diagnostic guidance for `claude-p` so stalled headless
  runs return a useful explanation instead of appearing to succeed.
- Required visible `claude-p` status updates while headless runs are starting,
  still running, completed, timed out, or returning no output.

## 2.7.0

- Added optional `claude-p` utility skill for one-shot Claude Code headless
  checks through the native `claude -p` command.
- Kept `claude-p` outside the Agent Council main review loop: no default topic
  writes, no default project file changes, and no automatic consensus or apply.
- Updated installer, uninstaller, help, README files, and validation for the
  optional utility boundary.

## 2.6.0

- Reframed Council as a human-invoked bridge, not an automatic risk gate.
- Added manual invocation boundaries: no auto-open, no task-stopping authority,
  and no automatic chaining after a topic finishes.
- Updated `council-open`, `council-review`, `council-status`, and
  `council-apply` guidance to keep Council advisory and topic-scoped.
- Documented that human gates happen outside Council; users may manually choose
  whether Council should participate.

## 2.5.2

- Made `council-upgrade` check-only by default.
- Required explicit `--apply` before modifying standalone skill installs.
- Added `--ref {git_ref}` guidance for users who need a specific branch, tag, or commit.
- Updated help, usage docs, and validation for the safer upgrade flow.

## 2.5.1

- Replaced raw angle-bracket placeholders with `{safe_placeholder}` syntax so
  GitHub/raw readers do not collapse path examples.
- Added validation for malformed placeholder output, SKILL.md frontmatter, and
  broken `.agent-council` paths.
- Tightened `council-review CONSENSUS` to read both latest handoffs before
  natural consensus.
- Added `council-open --overwrite` protection for active topics.
- Added `council-apply` guards for `USER_DECISION_NEEDED` and
  `USER_FORCED_CONSENSUS`.

## 2.5.0

- Made `council-open` topic ids optional, with automatic date-based ids such as `2026-06-03-1`.
- Added a default handoff size budget: 500 words or 20 bullets for latest handoffs.
- Documented short descriptive topic ids as optional, not required.

## 2.4.0

- Added `council-version` for direct installed-version checks.
- Clarified `council-upgrade` so standalone upgrades update the active standalone install and plugin users reinstall the plugin.
- Reflowed README files for better raw-text readability.
- Tightened skill output rules to keep topic judgments short and avoid discussing Council mechanics.

## 2.3.0

- Added lightweight guardrails: canonical lowercase agent ids, side effects summaries, and `council-status --doctor`.
- Added short consensus templates with must-preserve nits and forbidden actions.
- Added lightweight frontmatter guidance for turn records and consensus files.

## 2.2.0

- Defined stable Council status states and `status.md` schema.
- Required `council-review` responses to end with a `Next action`.
- Tightened `council-apply` so formal consensus is required unless the user explicitly applies latest.
- Added validation for invocation policies, version consistency, status docs, and deprecated aliases.

## 2.1.0

- Added `council-upgrade` to update standalone installs from the latest repository version.
- Documented plugin upgrade guidance in the upgrade skill.

## 2.0.3

- Added explicit v1 upgrade cleanup for stale `council-respond` standalone installs.
- Documented the safest v1-to-v2 upgrade path.

## 2.0.2

- Removed the deprecated `council-respond` compatibility alias.
- Use `council-review` for review, response, rebuttal, confirmation, and consensus.

## 2.0.1

- Show the Agent Council version in `council-help` output.

## 2.0.0

- Simplified Agent Council into a latest-turn bridge.
- Simplified `council-open` around a topic id and optional handoff note.
- Unified review and response around `council-review`.
- Kept `council-respond` as a compatibility alias.
- Removed artifact, stage, and brief arguments from the primary flow.
- Updated README and protocol docs in English and Chinese.

## 1.2.0

- Added separate English and Chinese README files.
- Added local install and marketplace install documentation.
- Added source brief support for chat-only context.
