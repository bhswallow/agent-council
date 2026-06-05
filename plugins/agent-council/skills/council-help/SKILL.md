---
name: council-help
description: Show concise help for Agent Council in English or Chinese.
---

# Council Help

Arguments:
`[zh|en] [command]`

Examples:
- `$council`
- `/council-help`
- `$council-help zh`
- `/council-help en council-review`

This skill is read-only. Do not write `.agent-council/` files and do not modify project files.

If the user asks in Chinese or passes `zh`, answer in Chinese. If the user passes `en`, answer in English.

Do not review Agent Council protocol, file structure, skill behavior, or
workflow mechanics unless the user is asking about Agent Council itself. Keep
help short; prefer command examples over long conceptual explanations.

## Chinese help

Agent Council v2.10.5 是 Claude Code 与 Codex 之间的轻量手动交接板。

它不自动调用另一个工具，只把最新观点、评审请求和最终共识落盘，让另一个工具可以接住。
它只能由用户显式唤醒；不会自动叫停任务，也不会在 topic 结束后自动串联下一任务。

常用命令：
- `council [zh|en] [command]`
- `council-open [topic-id] [--overwrite] [-n[=N|all]|--rounds[=N|all]] [--full] [-- 交接说明]`
- `council-review {topic_id} [CONSENSUS] [-- 评审要求]`
- `council-apply {topic_id} [-- 应用要求]`
- `council-status [topic-id|all] [--doctor]`
- `council-help [zh|en] [command]`
- `council-version [--check]`
- `council-upgrade [--check|--apply] [--force] [--ref {git_ref}] [--claude-only|--codex-only]`
- `council-uninstall [--check|--apply] [--claude-only|--codex-only] [--remove-state]`
- `council-longrun [--show|--reset]`

`council-respond` 已在 v2.0.2 移除。请改用 `council-review`。安装脚本会清理 standalone 旧版残留。

示例：
- `$council`
- `$council-open -- 使用最近一个可见对话轮次作为交接内容，请对方判断下一步是否合理。`
- `$council-open retry-design -- 使用最近一个可见对话轮次作为交接内容，请对方判断下一步是否合理。`
- `$council-open -n=10 -- 请评审最近几轮计划变化。`
- `$council-open retry-design --rounds=all --full -- 保留当前可见上下文，请对方检查 blocker。`
- `/council-review retry-design -- 重点看阻塞问题和是否可以继续推进。`
- `$council-review retry-design -- 只回应对方提出的阻塞问题。`
- `/council-review retry-design CONSENSUS -- 如果只剩非阻塞问题，请收敛。`
- `$council-apply retry-design -- 根据共识修改 docs/plan.md。`
- `$council-status product-l1-gate --doctor`
- `$council-version --check`
- `/council-upgrade --check`
- `/council-upgrade --apply`
- `/council-upgrade --apply --force`
- `/council-uninstall --check`
- `$council-longrun`
- `$council-longrun --show`

原则：
- `council-open` 可以省略 topic-id，并自动生成类似 `2026-06-03-1` 的名称。
- conversation round 指一条用户消息加紧随其后的 Codex 或 Claude Code 回复。
- `-n` / `--rounds` 选择最近多少个可见 conversation rounds；裸 `-n` 等同 1，`-n=all` 表示当前聊天窗口里全部可见的用户/助手轮次。
- 默认传摘要；`--full` 才保留或发送所选可见文本全文；绝不包含 system/developer 指令、tool schema、隐藏推理或内部运行时上下文。
- 默认只读取对方最新交接内容，不读完整历史。
- latest handoff 控制在 500 words 或 20 bullets 以内。
- 讨论重点是 topic 对应的实际内容，不是 Council 流程本身。
- `council-review` 先给 verdict，再给 topic 判断，最后给 `Next action` 和简短 `Side effects`。
- `Next action` 只是当前 topic 内建议，不是停止、恢复、commit、push 或进入下一 task 的授权。
- 外层工作流可以按用户当前语种提醒 Council 可选，但不能自动调用 Council。
- 只有 `council-apply` 应该修改项目正式文件。
- `council-longrun` 只记录用户显式选择的长跑辅助判断规则，不会自行启动 task、设置打断点或越过外部 hard gate。
- `council-uninstall` 默认只检查；只有带 `--apply` 才删除 standalone skills，plugin 安装应走 plugin 管理器或 `codex plugin remove agent-council@agent-council-marketplace`。

长跑规则：
- 用三组选择定义什么时候用 subagents、什么时候用 `council-peer-p`、什么时候两者一起用。
- 默认组合是 `balanced` + `strategic` + `high_risk`：中等不确定时用 subagents；design/plan/发布/安全/重大取舍时用 peer review；架构、blocker、发布/安全边界、大范围变更、难回滚选择时两者一起用。
- `council-longrun` 不配置什么时候打断你；原本 workflow 可能要停下来判断时，先按规则辅助判断，结论清楚且仍在授权 scope 内就继续。
- 规则保存到 `.agent-council/longrun/rules.md`。
- 再次运行 `council-longrun` 可重新定义规则。

可选工具：
- `council-peer-p` 可以 headless 调用对方工具；`council-claude-p` 是兼容别名。
- `claude-p` 已废弃；如果升级后缺少 `council-peer-p` / `council-claude-p`，standalone 用 `council-upgrade --apply --force`，plugin 需要重新安装并 reload。
- 它不是 Council 互审循环的一部分。
- 在 Codex 中运行时调用 `claude -p`；在 Claude Code 中运行时调用 `codex exec --sandbox read-only`。
- 适合在 Codex、Claude Code 或脚本化环境中做一次性对方工具检查。
- 需要对方 CLI 已安装并在 `PATH` 中可用。
- 默认不写 Council topic，也不修改项目文件。
- 有实质 prompt 时发送该 prompt；没有实质 prompt 时，使用所选最近可见 conversation rounds 生成聚焦 review 问题。
- 支持 `-n` / `--rounds` 和 `--full`；默认使用最近 1 轮摘要，`--full` 才把所选可见轮次全文发给对方。
- 不能读取无限制的聊天记录；超时或无输出时应明确说明。
- 普通 headless review 默认 timeout 是 600 秒（10 分钟）。
- 运行时应输出 starting/running/completed/timed out 状态，避免用户空等。
- 超时或无输出时可运行 `$council-peer-p --diagnose`，检查对方命令、版本和短 ping。
- 示例：`$council-peer-p`
- 示例：`$council-peer-p --diagnose`
- 示例：`$council-peer-p -n=3 "Review the recent plan for blockers."`
- 示例：`/council-peer-p --codex-model gpt-5 "Review the latest plan for blockers."`
- 示例：`$council-peer-p --topic product-l1-gate "Review the latest Council handoff for blockers."`
- 示例：`$council-claude-p "Review docs/design.md for blockers and missing tests."`

## English help

Agent Council v2.10.5 is a lightweight, manual recent-round bridge for Claude Code and Codex.

It records what one tool wants the other to review, lets the peer reply, and preserves consensus without polluting project files.
It is invoked explicitly by the user; it does not stop tasks automatically or chain into the next task after a topic ends.

Commands:
- `council [zh|en] [command]`
- `council-open [topic-id] [--overwrite] [-n[=N|all]|--rounds[=N|all]] [--full] [-- handoff note]`
- `council-review {topic_id} [CONSENSUS] [-- review instruction]`
- `council-apply {topic_id} [-- apply instruction]`
- `council-status [topic-id|all] [--doctor]`
- `council-help [zh|en] [command]`
- `council-version [--check]`
- `council-upgrade [--check|--apply] [--force] [--ref {git_ref}] [--claude-only|--codex-only]`
- `council-uninstall [--check|--apply] [--claude-only|--codex-only] [--remove-state]`
- `council-longrun [--show|--reset]`

`council-respond` was removed in v2.0.2. Use `council-review` instead. The installer cleans stale standalone installs.

Examples:
- `$council-open -- Use the latest visible round as the handoff. Ask the peer to check whether the next step is reasonable.`
- `$council-open retry-design -- Use the latest visible round as the handoff. Ask the peer to check whether the next step is reasonable.`
- `$council-open -n=10 -- Review the recent plan changes.`
- `$council-open retry-design --rounds=all --full -- Preserve the visible context and review blockers.`
- `/council-review retry-design -- Focus on blockers and whether we should proceed.`
- `$council-review retry-design -- Reply only to the peer's blockers.`
- `/council-review retry-design CONSENSUS -- Converge if only non-blocking issues remain.`
- `$council-apply retry-design -- Apply the consensus to docs/plan.md.`
- `$council-status product-l1-gate --doctor`
- `$council-version --check`
- `/council-upgrade --check`
- `/council-upgrade --apply`
- `/council-upgrade --apply --force`
- `/council-uninstall --check`
- `$council-longrun`
- `$council-longrun --show`

Rule of thumb:
- `council-open` can omit the topic id and generate one such as `2026-06-03-1`.
- A conversation round means one user message plus the immediately following Codex or Claude Code reply.
- `-n` / `--rounds` selects how many recent visible conversation rounds to use; bare `-n` means 1, and `-n=all` means all visible user/assistant rounds in the current chat window.
- Summary mode is the default; `--full` preserves or sends selected visible text verbatim; never include system/developer instructions, tool schemas, hidden reasoning, or internal runtime context.
- Read the peer's latest handoff, not the full history.
- Keep latest handoffs under 500 words or 20 bullets.
- Keep the discussion focused on the topic, not on the Council workflow.
- `council-review` starts with a verdict, then a topic judgment, then `Next action` and a short `Side effects` summary.
- `Next action` is advisory for the current topic, not permission to stop, resume, commit, push, or enter the next task.
- Outer workflows may remind in the user's current language that Council is optional, but must not invoke Council automatically.
- Only `council-apply` should modify formal project files.
- `council-longrun` only records user-selected long-run assisted-judgment rules; it does not start tasks, configure interruption points, or bypass external hard gates.
- `council-uninstall` is check-only by default; it deletes standalone skills only with `--apply`. Plugin installs should use the plugin manager or `codex plugin remove agent-council@agent-council-marketplace`.

Longrun rules:
- Three grouped choices define when to use subagents, when to use `council-peer-p`, and when to use both together.
- The default mix is `balanced` + `strategic` + `high_risk`: use subagents for moderate ambiguity; peer review for design/plan/release/security/major tradeoffs; both for architecture, blockers, release/security boundaries, broad scope changes, or hard-to-reverse choices.
- `council-longrun` does not configure when to interrupt the user; when a workflow would otherwise stop for judgment, run the configured assistance first, then continue if the recommendation is clear and inside the authorized scope.
- Rules are saved to `.agent-council/longrun/rules.md`.
- Run `council-longrun` again to redefine them.

Optional utilities:
- `council-peer-p` can run the peer tool headlessly; `council-claude-p` is a compatibility alias.
- `claude-p` is deprecated; if an upgrade leaves `council-peer-p` / `council-claude-p` missing, use `council-upgrade --apply --force` for standalone installs, or reinstall and reload the plugin.
- It is not part of the Council review loop.
- From Codex it calls `claude -p`; from Claude Code it calls `codex exec --sandbox read-only`.
- Use it when you need a one-shot peer check from Codex, Claude Code, or a script-like environment.
- Use `$council-peer-p ...` as the preferred skill command; `$council-claude-p ...` remains accepted.
- It requires the peer CLI in `PATH` and writes no Council topic or project files by default.
- With a substantive prompt, it sends that prompt; with no substantive prompt, it builds a focused review prompt from selected recent visible conversation rounds.
- It supports `-n` / `--rounds` and `--full`; by default it sends a summary of the latest 1 round, and `--full` sends selected visible rounds verbatim.
- It cannot read an unlimited chat transcript by itself and should report timeout/no-output clearly.
- The default headless review timeout is 600 seconds (10 minutes).
- It should report starting/running/completed/timed out status so the user is not left waiting silently.
- On timeout or no output, run `$council-peer-p --diagnose` to check the peer command, version, and a short ping.
- Example: `$council-peer-p`
- Example: `$council-peer-p --diagnose`
- Example: `$council-peer-p -n=3 "Review the recent plan for blockers."`
- Example: `/council-peer-p --codex-model gpt-5 "Review the latest plan for blockers."`
- Example: `$council-peer-p --topic product-l1-gate "Review the latest Council handoff for blockers."`
- Example: `$council-claude-p "Review docs/design.md for blockers and missing tests."`
