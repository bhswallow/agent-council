---
name: council
description: Show the Agent Council command index and route short Council requests.
---

# Council

Arguments:
`[zh|en] [command]`

Examples:
- `$council`
- `$council zh`
- `$council peer`
- `$council longrun`

This is the top-level Agent Council command index. Use it when the user invokes
`$council` or `/council`, or when they ask which Council command to use.

This skill is read-only. Do not write `.agent-council/` files and do not modify
project files.

If the user passes a specific Council command name, show a short usage hint for
that command. If the user passes an intent word, map it conservatively:

- `open`, `handoff`, `start`, `topic`: suggest `council-open`;
- `review`, `reply`, `consensus`: suggest `council-review`;
- `apply`: suggest `council-apply`;
- `status`, `doctor`: suggest `council-status`;
- `version`: suggest `council-version`;
- `upgrade`, `update`: suggest `council-upgrade`;
- `uninstall`, `remove`: suggest `council-uninstall`;
- `longrun`, `subagents`, `peer`, `both`: suggest `council-longrun` unless
  the user clearly asks for a one-shot peer headless check.

Do not invoke another Council skill automatically from this index. Tell the user
the exact command to run.

## Chinese Response

Agent Council 命令入口：

- standalone：`$council-help`、`$council-open`、`$council-review`、`$council-apply`、`$council-status`、`$council-longrun`、`$council-version`、`$council-upgrade`、`$council-uninstall`。
- Codex plugin：`$agent-council:council-help`、`$agent-council:council-open`、`$agent-council:council-review`、`$agent-council:council-apply`、`$agent-council:council-status`、`$agent-council:council-longrun`、`$agent-council:council-version`、`$agent-council:council-upgrade`、`$agent-council:council-uninstall`。

可选的一次性 peer headless review 工具：standalone 用 `$council-peer-review`，Codex plugin 用 `$agent-council:council-peer-review`。

## English Response

Agent Council command index:

- Standalone: `$council-help`, `$council-open`, `$council-review`,
  `$council-apply`, `$council-status`, `$council-longrun`,
  `$council-version`, `$council-upgrade`, `$council-uninstall`.
- Codex plugin: `$agent-council:council-help`,
  `$agent-council:council-open`, `$agent-council:council-review`,
  `$agent-council:council-apply`, `$agent-council:council-status`,
  `$agent-council:council-longrun`, `$agent-council:council-version`,
  `$agent-council:council-upgrade`, `$agent-council:council-uninstall`.

The optional one-shot peer headless review utility is `$council-peer-review`
for standalone installs or `$agent-council:council-peer-review` for Codex
plugin installs.
