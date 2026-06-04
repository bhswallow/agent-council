---
name: council-version
description: Show the installed Agent Council version and upgrade hints.
disable-model-invocation: true
---

# Council Version

Arguments:
`[--check]`

Examples:
- `/council-version`
- `$council-version --check`
- `/agent-council:council-version`

## Purpose

Show the Agent Council version from the installed skill that is currently being used.

This skill is read-only. Do not write `.agent-council/` files and do not modify project files.

Do not review Agent Council protocol, file structure, skill behavior, or
workflow mechanics. This skill only reports the active installed version.

## Behavior

Report:

- installed version: `2.7.3`
- whether this appears to be standalone or plugin usage, if the path is visible
- if `--check` is present, compare against:

```sh
curl -fsSL https://raw.githubusercontent.com/bhswallow/agent-council/main/VERSION
```

If the installed version is older than the latest version, tell standalone users to run:

```text
/council-upgrade --apply
```

For plugin installs, tell the user to reinstall the `agent-council` plugin from the marketplace and reload plugins.

## User-Facing Response

Keep it short:

```text
Agent Council v2.7.3
```

If `--check` is used, add latest-version status and one upgrade hint.

Do not add protocol explanation unless the user explicitly asks why versions can
differ between standalone and plugin installs.
