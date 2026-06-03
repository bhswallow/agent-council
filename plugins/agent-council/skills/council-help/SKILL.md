---
name: council-help
description: Show concise help for Agent Council in English or Chinese.
disable-model-invocation: true
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

Do not review Agent Council protocol, file structure, skill behavior, or
workflow mechanics unless the user is asking about Agent Council itself. Keep
help short; prefer command examples over long conceptual explanations.

## Chinese help

Agent Council v2.5.0 是 Claude Code 与 Codex 之间的轻量手动交接板。

它不自动调用另一个工具，只把最新观点、评审请求和最终共识落盘，让另一个工具可以接住。

常用命令：
- `council-open [topic-id] [-- 交接说明]`
- `council-review <topic-id> [CONSENSUS] [-- 评审要求]`
- `council-apply <topic-id> [-- 应用要求]`
- `council-status [topic-id|all] [--doctor]`
- `council-help [zh|en] [command]`
- `council-version [--check]`
- `council-upgrade [--check] [--claude-only|--codex-only]`

`council-respond` 已在 v2.0.2 移除。请改用 `council-review`。安装脚本会清理 standalone 旧版残留。

示例：
- `$council-open -- 使用我最近一次回复作为交接内容，请对方判断下一步是否合理。`
- `$council-open retry-design -- 使用我最近一次回复作为交接内容，请对方判断下一步是否合理。`
- `/council-review retry-design -- 重点看阻塞问题和是否可以继续推进。`
- `$council-review retry-design -- 只回应对方提出的阻塞问题。`
- `/council-review retry-design CONSENSUS -- 如果只剩非阻塞问题，请收敛。`
- `$council-apply retry-design -- 根据共识修改 docs/design.md。`
- `$council-status product-l1-gate --doctor`
- `$council-version --check`
- `/council-upgrade --check`

原则：
- `council-open` 可以省略 topic-id，并自动生成类似 `2026-06-03-1` 的名称。
- 默认只读取对方最新交接内容，不读完整历史。
- latest handoff 控制在 500 words 或 20 bullets 以内。
- 讨论重点是 topic 对应的实际内容，不是 Council 流程本身。
- `council-review` 先给 verdict，再给 topic 判断，最后给 `Next action` 和简短 `Side effects`。
- 只有 `council-apply` 应该修改项目正式文件。

## English help

Agent Council v2.5.0 is a lightweight, manual latest-turn bridge for Claude Code and Codex.

It records what one tool wants the other to review, lets the peer reply, and preserves consensus without polluting project files.

Commands:
- `council-open [topic-id] [-- handoff note]`
- `council-review <topic-id> [CONSENSUS] [-- review instruction]`
- `council-apply <topic-id> [-- apply instruction]`
- `council-status [topic-id|all] [--doctor]`
- `council-help [zh|en] [command]`
- `council-version [--check]`
- `council-upgrade [--check] [--claude-only|--codex-only]`

`council-respond` was removed in v2.0.2. Use `council-review` instead. The installer cleans stale standalone installs.

Examples:
- `$council-open -- Use my latest answer as the handoff. Ask the peer to check whether the next step is reasonable.`
- `$council-open retry-design -- Use my latest answer as the handoff. Ask the peer to check whether the next step is reasonable.`
- `/council-review retry-design -- Focus on blockers and whether we should proceed.`
- `$council-review retry-design -- Reply only to the peer's blockers.`
- `/council-review retry-design CONSENSUS -- Converge if only non-blocking issues remain.`
- `$council-apply retry-design -- Apply the consensus to docs/design.md.`
- `$council-status product-l1-gate --doctor`
- `$council-version --check`
- `/council-upgrade --check`

Rule of thumb:
- `council-open` can omit the topic id and generate one such as `2026-06-03-1`.
- Read the peer's latest handoff, not the full history.
- Keep latest handoffs under 500 words or 20 bullets.
- Keep the discussion focused on the topic, not on the Council workflow.
- `council-review` starts with a verdict, then a topic judgment, then `Next action` and a short `Side effects` summary.
- Only `council-apply` should modify formal project files.
