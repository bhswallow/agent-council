---
name: council-help
description: Show concise help for Agent Council in English or Chinese.
---

# Council Help

Arguments:
`[zh|en] [command]`

Examples:
- `/council-help`
- `$council-help zh`
- `/council-help en council-review`

This skill is read-only. Do not write `.agent-council/` files and do not modify project files.

If the user asks in Chinese or passes `zh`, answer in Chinese. If the user passes `en`, answer in English.

## Chinese help

Agent Council v2.0.1 是 Claude Code 和 Codex 之间的“最新一轮交接”桥梁。

常用命令：
- `council-open <topic-id> [-- 交接说明]`
- `council-review <topic-id> [CONSENSUS] [-- 评审要求]`
- `council-apply <topic-id> [-- 应用要求]`
- `council-status [topic-id|all]`
- `council-help [zh|en] [command]`

`council-respond` 是兼容别名，等同于 `council-review`。

示例：
- `$council-open retry-design -- 使用我最近一次回复作为交接内容，请对方判断下一步是否合理。`
- `/council-review retry-design -- 重点看阻塞问题和是否可以继续推进。`
- `$council-review retry-design -- 只回应对方提出的阻塞问题。`
- `/council-review retry-design CONSENSUS -- 如果只剩非阻塞问题，请收敛。`
- `$council-apply retry-design -- 根据共识修改 docs/design.md。`

原则：默认只读取对方最新交接内容，不读完整历史。讨论重点是 topic 对应的实际内容，不是 Council 流程本身。只有 `council-apply` 应该修改项目正式文件。

## English help

Agent Council v2.0.1 is a latest-turn bridge between Claude Code and Codex.

Commands:
- `council-open <topic-id> [-- handoff note]`
- `council-review <topic-id> [CONSENSUS] [-- review instruction]`
- `council-apply <topic-id> [-- apply instruction]`
- `council-status [topic-id|all]`
- `council-help [zh|en] [command]`

`council-respond` is a compatibility alias for `council-review`.

Examples:
- `$council-open retry-design -- Use my latest answer as the handoff. Ask the peer to check whether the next step is reasonable.`
- `/council-review retry-design -- Focus on blockers and whether we should proceed.`
- `$council-review retry-design -- Reply only to the peer's blockers.`
- `/council-review retry-design CONSENSUS -- Converge if only non-blocking issues remain.`
- `$council-apply retry-design -- Apply the consensus to docs/design.md.`

Rule of thumb: read the peer's latest handoff, not the full history. Keep the discussion focused on the topic, not on the Council workflow. Only `council-apply` should modify formal project files.
