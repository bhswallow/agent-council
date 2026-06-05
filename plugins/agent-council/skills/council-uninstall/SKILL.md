---
name: council-uninstall
description: Check or explicitly uninstall Agent Council standalone installs and explain plugin uninstall steps.
---

# Council Uninstall

Arguments:
`[--check|--apply] [--claude-only|--codex-only] [--project {path}] [--home] [--remove-state] [--remove-codex-marketplace]`

Examples:
- `/council-uninstall --check`
- `$council-uninstall --apply`
- `$council-uninstall --apply --codex-only`
- `/agent-council:council-uninstall`

## Purpose

Check Agent Council installation locations and, only when explicitly requested,
uninstall standalone skills from the selected project or home root.

Default behavior is read-only. This skill may delete local standalone skill
directories only when the user includes `--apply`. It must not modify project
source files. It must not remove `.agent-council/` discussion state unless the
user also includes `--remove-state`.

Do not review Agent Council protocol or workflow mechanics. This skill only
handles installation state and uninstall guidance.

Important: standalone skills and plugin-installed skills are different
installations. A standalone uninstall removes directories such as
`.agents/skills/council-peer`; a plugin uninstall must go through the plugin
manager or Codex plugin CLI.

## Behavior

Detect the project root as the current working directory unless the user passes
`--project {path}`. If `--home` is present, use `$HOME` as the target root.

Known standalone skill directories are:

- `council-open`
- `council`
- `council-review`
- `council-apply`
- `council-status`
- `council-help`
- `council-upgrade`
- `council-uninstall`
- `council-version`
- `council-peer`
- `council-longrun`

Check these roots:

- `$PROJECT_ROOT/.claude/skills`
- `$PROJECT_ROOT/.agents/skills`
- `$HOME/.claude/skills`
- `$HOME/.agents/skills`

Respect mode flags:

- `--claude-only`: check or remove only `.claude/skills`
- `--codex-only`: check or remove only `.agents/skills`
- no mode flag: check or remove both

If neither `--check` nor `--apply` is present, behave exactly like `--check`.
Report detected standalone locations, plugin status hints if visible, and the
safe uninstall command. Do not delete anything.

If `--check` is present, only report what would be removed. Do not delete
anything.

If `--apply` is present, remove only known Agent Council standalone skill
directories from the selected roots. Do not delete the parent `.agents/skills`
or `.claude/skills` directory. Do not delete unrelated skills.

If `--remove-state` is present with `--apply`, remove `.agent-council/` under
the selected project root. Do not remove `.agent-council/` for `$HOME` unless
the user explicitly selected `--home` and clearly wants home-level state
removed.

## Standalone Uninstall

When running from a repository checkout that contains `uninstall.sh`, prefer:

```sh
./uninstall.sh "$PROJECT_ROOT" --dry-run
./uninstall.sh "$PROJECT_ROOT" --apply
./uninstall.sh "$PROJECT_ROOT" --codex-only --apply
./uninstall.sh "$PROJECT_ROOT" --claude-only --apply
```

Use `--remove-state` only when the user explicitly asks to remove local Council
discussion state:

```sh
./uninstall.sh "$PROJECT_ROOT" --apply --remove-state
```

If `uninstall.sh` is not available, perform the same deletion directly only
when `--apply` is present.

After uninstalling, verify removed commands are absent:

```sh
test ! -e "$PROJECT_ROOT/.agents/skills/council-help"
test ! -e "$PROJECT_ROOT/.agents/skills/council"
test ! -e "$PROJECT_ROOT/.agents/skills/council-peer"
test ! -e "$PROJECT_ROOT/.claude/skills/council-help"
test ! -e "$PROJECT_ROOT/.claude/skills/council"
test ! -e "$PROJECT_ROOT/.claude/skills/council-peer"
```

Adjust the verification for `--claude-only` or `--codex-only`.

## Plugin Uninstall

If the active command is namespaced as `/agent-council:council-uninstall`, or no
standalone skill directory exists but the plugin appears installed, treat it as
a plugin install. Do not delete plugin cache files by hand.

For Codex plugin installs, if `--apply` is present and the Codex CLI is
available, run:

```sh
codex plugin remove agent-council@agent-council-marketplace
```

Only remove the marketplace source when the user also passes
`--remove-codex-marketplace`:

```sh
codex plugin marketplace remove agent-council-marketplace
```

For Claude Code plugin installs, tell the user to remove the `agent-council`
plugin from the `/plugins` or `/plugin` manager and then run:

```text
/reload-plugins
```

Do not invent a Claude Code plugin CLI command unless the local tool documents
one.

## User-Facing Response

Keep the response concise:

- whether this was check-only or applied;
- standalone roots checked or removed;
- whether Claude Code and/or Codex standalone skills were affected;
- whether `.agent-council/` discussion state was kept or removed;
- plugin uninstall command or next UI step when the active install is a plugin;
- restart or reload guidance.

For check-only standalone responses, include:

```text
council-uninstall --apply
```

For Codex plugin uninstall, include:

```sh
codex plugin remove agent-council@agent-council-marketplace
```
