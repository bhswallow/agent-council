---
name: council-upgrade
description: Upgrade Agent Council standalone installs and explain plugin upgrade steps.
disable-model-invocation: true
---

# Council Upgrade

Arguments:
`[--check] [--claude-only|--codex-only]`

Examples:
- `/council-upgrade`
- `$council-upgrade --check`
- `/agent-council:council-upgrade`

## Purpose

Upgrade Agent Council to the latest repository version.

This skill may modify local skill installation directories, but it must not modify project source files or `.agent-council/` discussion state.

Do not review Agent Council protocol or workflow mechanics. This skill only handles installation state and upgrade guidance.

Important: standalone skills and plugin-installed skills are different installations.
If `council-help` still shows an old version after upgrade, the user is probably
calling a plugin install or another standalone copy. Use `council-version` to
check the active copy.

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

If `--check` is present, only report installed versions and the latest version. Do not upgrade.

## Standalone Upgrade

If any of these exists, treat it as a standalone install target:

- `$PROJECT_ROOT/.claude/skills/council-help`
- `$PROJECT_ROOT/.agents/skills/council-help`
- `$HOME/.claude/skills/council-help`
- `$HOME/.agents/skills/council-help`

Clone the latest repository to a temporary directory:

```sh
tmpdir="$(mktemp -d)"
git clone --depth 1 https://github.com/bhswallow/agent-council.git "$tmpdir/agent-council"
```

Run the newest installer against each detected standalone root.

For project-local installs:

```sh
"$tmpdir/agent-council/install.sh" "$PROJECT_ROOT"
```

For home-level standalone installs, use `$HOME` as the root:

```sh
"$tmpdir/agent-council/install.sh" "$HOME" --claude-only
"$tmpdir/agent-council/install.sh" "$HOME" --codex-only
```

Respect mode flags when choosing targets:

- `--claude-only`: run the installer with `--claude-only`
- `--codex-only`: run the installer with `--codex-only`

After install, verify stale deprecated commands are gone:

```sh
test ! -e "$PROJECT_ROOT/.claude/skills/council-respond"
test ! -e "$PROJECT_ROOT/.agents/skills/council-respond"
test ! -e "$HOME/.claude/skills/council-respond"
test ! -e "$HOME/.agents/skills/council-respond"
```

Then remove the temporary clone.

After upgrading, tell the user to restart the tool or reload plugins if the old version still appears.

## Plugin Upgrade

If no standalone install exists, or if the active command is namespaced as
`/agent-council:council-upgrade`, explain that this appears to be a plugin
install. A standalone installer cannot reliably update a plugin cache.

For Claude Code plugin installs:

```text
/plugin marketplace add bhswallow/agent-council
/plugin install agent-council@agent-council-marketplace
/reload-plugins
```

If `council-respond` still appears after upgrade, uninstall the old `agent-council` plugin first, then install again.

For Codex plugin installs:

```sh
codex plugin marketplace add bhswallow/agent-council
```

Then open `/plugins`, remove the old `agent-council` plugin if needed, and install it again from the Agent Council marketplace.

## User-Facing Response

Keep the response concise:

- installed version before upgrade;
- latest version installed;
- whether Claude Code and/or Codex standalone skills were updated;
- whether stale `council-respond` was removed;
- next verification command: `council-version`, then `council-help`.
