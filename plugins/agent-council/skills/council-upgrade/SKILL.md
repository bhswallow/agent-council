---
name: council-upgrade
description: Check or explicitly upgrade Agent Council standalone installs and explain plugin upgrade steps.
---

# Council Upgrade

Arguments:
`[--check|--apply] [--force] [--ref {git_ref}] [--claude-only|--codex-only]`

Examples:
- `/council-upgrade --check`
- `/council-upgrade --apply`
- `/council-upgrade --apply --force`
- `/council-upgrade --apply --ref {git_ref}`
- `$council-upgrade --check`
- `/agent-council:council-upgrade`

## Purpose

Check Agent Council installation versions and, only when explicitly requested,
upgrade standalone installs from a chosen repository ref.

Default behavior is read-only. This skill may modify local skill installation
directories only when the user includes `--apply`. `--force` is allowed only as
an addition to `--apply`; by itself it is still check-only. This skill must not
modify project source files or `.agent-council/` discussion state.

Do not review Agent Council protocol or workflow mechanics. This skill only handles installation state and upgrade guidance.

Important: standalone skills and plugin-installed skills are different installations.
If `council-help` still shows an old version after upgrade, the user is probably
calling a plugin install or another standalone copy. Use `council-version` to
check the active copy.

Historical note: the old standalone command `claude-p` is deprecated and should
be removed. The replacement commands are `council-peer-p` and the compatibility
alias `council-claude-p`. If `claude-p` disappeared but neither replacement is
available, the upgrade probably did not run against the active standalone
skills directory, or a plugin cache still needs reinstall/reload.

## Behavior

Detect the project root as the current working directory unless the user explicitly names another target path.

Read local installed versions, if present:

- `.claude/skills/council-help/SKILL.md`
- `.agents/skills/council-help/SKILL.md`
- `$HOME/.claude/skills/council-help/SKILL.md`
- `$HOME/.agents/skills/council-help/SKILL.md`

Extract a version from `Agent Council vX.Y.Z` if possible. If no version is found, report it as `unknown`.

Check the latest version:

```sh
curl -fsSL https://raw.githubusercontent.com/bhswallow/agent-council/main/VERSION
```

If neither `--check` nor `--apply` is present, behave exactly like `--check`.
Report installed versions, the latest version on `main`, and the safe upgrade
command. Do not clone, install, delete, or overwrite anything.

If `--check` is present, only report installed versions and the latest version.
Do not upgrade.

If `--apply` is present, upgrade detected standalone installs. If `--ref
{git_ref}` is present, use that git ref. Otherwise use `main`.

Do not treat `--ref` by itself as permission to upgrade. `--apply` is required
for any installation change.

Do not treat `--force` by itself as permission to upgrade. `--apply` is required
for any deletion, cleanup, overwrite, or install. If the user passes `--force`
without `--apply`, report what would be cleaned and tell them to run
`council-upgrade --apply --force`.

## Standalone Upgrade

Only perform this section when `--apply` is present.

If any of these exists, treat it as a standalone install target:

- `$PROJECT_ROOT/.claude/skills/council-help`
- `$PROJECT_ROOT/.agents/skills/council-help`
- `$HOME/.claude/skills/council-help`
- `$HOME/.agents/skills/council-help`

When `--force` is present, also treat a root as a standalone cleanup target if
any known Agent Council skill directory exists there, including deprecated or
partially upgraded commands:

- `council-open`
- `council-review`
- `council-respond`
- `council-apply`
- `council-status`
- `council-help`
- `council-upgrade`
- `council-version`
- `council-peer-p`
- `council-claude-p`
- `council-longrun`
- `claude-p`

This fixes dirty installs where old commands remain but `council-help` is
missing, or where `claude-p` was deleted without installing `council-peer-p` and
`council-claude-p`.

Clone the repository to a temporary directory:

```sh
tmpdir="$(mktemp -d)"
git clone --depth 1 --branch "{git_ref}" https://github.com/bhswallow/agent-council.git "$tmpdir/agent-council"
```

Use `main` when no `--ref` was supplied. `--ref` may be a branch, tag, or
commit.

Run the newest installer against each detected standalone root.

For project-local installs without `--force`:

```sh
"$tmpdir/agent-council/install.sh" "$PROJECT_ROOT"
```

For project-local installs with `--force`:

```sh
"$tmpdir/agent-council/install.sh" "$PROJECT_ROOT" --force
```

For home-level standalone installs without `--force`, use `$HOME` as the root:

```sh
"$tmpdir/agent-council/install.sh" "$HOME" --claude-only
"$tmpdir/agent-council/install.sh" "$HOME" --codex-only
```

For home-level standalone installs with `--force`, use `$HOME` as the root:

```sh
"$tmpdir/agent-council/install.sh" "$HOME" --claude-only --force
"$tmpdir/agent-council/install.sh" "$HOME" --codex-only --force
```

Respect mode flags when choosing targets:

- `--claude-only`: run the installer with `--claude-only`
- `--codex-only`: run the installer with `--codex-only`
- `--force`: pass `--force` to the installer and include dirty/stale roots in
  target detection

After install, verify stale deprecated commands are gone:

```sh
test ! -e "$PROJECT_ROOT/.claude/skills/council-respond"
test ! -e "$PROJECT_ROOT/.agents/skills/council-respond"
test ! -e "$HOME/.claude/skills/council-respond"
test ! -e "$HOME/.agents/skills/council-respond"
test ! -e "$PROJECT_ROOT/.claude/skills/claude-p"
test ! -e "$PROJECT_ROOT/.agents/skills/claude-p"
test ! -e "$HOME/.claude/skills/claude-p"
test ! -e "$HOME/.agents/skills/claude-p"
```

Also verify the replacement commands exist in every target that was actually
upgraded. Do not require Codex directories when `--claude-only` was used, and
do not require Claude Code directories when `--codex-only` was used:

```sh
test -d "$PROJECT_ROOT/.claude/skills/council-peer-p"
test -d "$PROJECT_ROOT/.claude/skills/council-claude-p"
test -d "$PROJECT_ROOT/.agents/skills/council-peer-p"
test -d "$PROJECT_ROOT/.agents/skills/council-claude-p"
test -d "$HOME/.claude/skills/council-peer-p"
test -d "$HOME/.claude/skills/council-claude-p"
test -d "$HOME/.agents/skills/council-peer-p"
test -d "$HOME/.agents/skills/council-claude-p"
```

Then remove the temporary clone.

After upgrading, tell the user to restart the tool or reload plugins if the old version still appears.

## Plugin Upgrade

If no standalone install exists, or if the active command is namespaced as
`/agent-council:council-upgrade`, explain that this appears to be a plugin
install. A standalone installer cannot reliably update a plugin cache.

For plugin installs, do not run standalone installation commands even when
`--apply` or `--apply --force` is present. Give reinstall instructions instead.
`--force` cannot safely delete plugin-cache commands because the plugin manager
owns that cache.

For Claude Code plugin installs:

```text
/plugin marketplace add bhswallow/agent-council
/plugin install agent-council@agent-council-marketplace
/reload-plugins
```

If `council-respond` or `claude-p` still appears after upgrade, uninstall the
old `agent-council` plugin first, then install again.

For Codex plugin installs:

```sh
codex plugin marketplace add bhswallow/agent-council
```

Then open `/plugins`, remove the old `agent-council` plugin if needed, and
install it again from the Agent Council marketplace.

## User-Facing Response

Keep the response concise:

- installed version before upgrade;
- latest version or requested ref;
- whether this was check-only or applied;
- whether `--force` was used;
- whether Claude Code and/or Codex standalone skills were updated;
- whether stale `council-respond` and `claude-p` were removed;
- whether replacements `council-peer-p` and `council-claude-p` are present;
- next verification command: `council-version`, then `council-help`.

For check-only responses, include this command when an update is available:

```text
/council-upgrade --apply
```

For dirty standalone installs with missing replacement commands or leftover
deprecated commands, include:

```text
/council-upgrade --apply --force
```

Use `--ref {git_ref}` only when the user asks for a specific branch, tag, or
commit.
