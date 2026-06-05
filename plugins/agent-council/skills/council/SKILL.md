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

- `$council-help`：完整帮助。
- `$council-open`：开启 topic 并记录交接内容。
- `$council-review`：读取对方交接并回应或收敛共识。
- `$council-apply`：把共识应用到正式项目文件。
- `$council-status`：查看 topic 状态或运行 `--doctor`。
- `$council-longrun`：配置长跑时何时用 subagents、peer headless review，或两者一起辅助判断。
- `$council-version`：查看当前生效版本。
- `$council-upgrade`：检查或显式升级 standalone 安装。
- `$council-uninstall`：检查或显式卸载 standalone 安装。

可选的一次性 peer headless review 工具是 `$council-peer`。

## English Response

Agent Council command index:

- `$council-help`: full help.
- `$council-open`: open a topic and record a handoff.
- `$council-review`: read the peer handoff and reply or converge.
- `$council-apply`: apply consensus to formal project files.
- `$council-status`: inspect topic status or run `--doctor`.
- `$council-longrun`: configure when long-running work uses subagents, peer
  headless review, or both for assisted judgment.
- `$council-version`: show the active installed version.
- `$council-upgrade`: check or explicitly upgrade standalone installs.
- `$council-uninstall`: check or explicitly uninstall standalone installs.

The optional one-shot peer headless review utility is `$council-peer`.
