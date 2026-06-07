# Changelog

## 2.10.10

- Renamed the peer-headless utility entry point to `council-peer-review` so
  Codex users have a clearer one-shot review command to invoke.
- Enabled Codex discovery for `council-peer-review` while keeping the skill
  text explicit that it should only run after user invocation.
- Removed the old `council-peer` skill directory from the plugin bundle and
  updated standalone install cleanup to reconcile stale peer command names.

## 2.10.9

- Restored Codex skill discovery metadata to the top-level `interface:` shape
  used by the original visible `claude-p` command and by current bundled Codex
  plugins.
- Kept `policy.allow_implicit_invocation: false` so commands remain explicit
  while the command picker can index display metadata correctly.

## 2.10.8

- Added `council-longrun --template` to print a long-running task startup
  prompt that can default to Superpowers when installed or required by project
  instructions.
- The template tells future work to apply saved `council-longrun` assisted
  judgment rules before continuing through uncertain execution points.

## 2.10.7

- Published `council-peer` as the single peer-headless command surface.
- Removed old peer-headless skill directories from the current plugin bundle.
- Updated install and uninstall scripts to reconcile stale standalone Agent
  Council skill directories.
- Cleaned user-facing docs, help, and validation so current guidance only shows
  supported commands.

## 2.10.x

- Added the top-level `council` command index.
- Improved Codex command discovery metadata for bundled skills.
- Added `council-uninstall` and safer check/apply upgrade behavior.
- Refined `council-longrun` into grouped assisted-judgment settings for
  subagents, peer review, and combined assistance.

## 2.x

- Kept Agent Council as a lightweight, manual bridge between Claude Code and
  Codex.
- Added recent-round handoffs, compact status output, doctor checks,
  standalone/plugin installation guidance, and explicit apply boundaries.
