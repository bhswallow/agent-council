# 使用说明

Agent Council v2.10.9 是一个“最近轮次交接”桥梁。
它适合 Claude Code 和 Codex 需要互相评审对方最新内容，但又不共享同一个聊天窗口的场景。

Agent Council 是 Claude Code 与 Codex 之间的轻量手动交接板。
它不自动调用另一个工具，只负责把当前工具的最新观点、评审请求和最终共识落盘，
让另一个工具可以接住。

Council 只能由用户显式唤醒。它不能自动叫停任务、创建 topic，
也不能在 topic 结束后自动串联到下一个 task。

外层工作流可以在头脑风暴、design、plans、specs、task batch 完成或卡点后，
简短提醒用户可以选择 Council。提醒应匹配用户当前语种，是可选提示，
不能调用 Council，也不能停止执行。

评审必须聚焦 topic 本身。
除非 topic 本身就是 Agent Council，否则不要把讨论变成对 Council 协议或流程机制的评审。

agent id 和路径统一小写：`claude`、`codex`、`latest/claude.md`、`latest/codex.md`。

## 命令

    council [zh|en] [command]
    council-open [topic-id] [--overwrite] [-n[=N|all]|--rounds[=N|all]] [--full] [-- 交接说明]
    council-review {topic_id} [CONSENSUS] [-- 评审要求]
    council-apply {topic_id} [-- 应用要求]
    council-status [topic-id|all] [--doctor]
    council-help [zh|en]
    council-version [--check]
    council-upgrade [--check|--apply] [--force] [--ref {git_ref}] [--claude-only|--codex-only]
    council-uninstall [--check|--apply] [--claude-only|--codex-only] [--remove-state]
    council-longrun [--show|--reset|--template] [--superpowers|--no-superpowers]

如果你不确定该用哪个 Council 命令，可以先运行 `council` 查看顶层命令索引。

使用 `council-upgrade` 可以检查 standalone 安装版本。
它默认只检查不修改。使用 `council-upgrade --apply` 才会更新。
如果 standalone 安装很脏，比如还残留旧目录或缺少当前命令，使用
`council-upgrade --apply --force` 整理并重装。只有需要指定 branch、tag 或 commit
时才加 `--ref {git_ref}`。

使用 `council-version` 确认当前实际生效的安装版本。

如果 `council-upgrade` 完成后 `council-help` 仍显示旧版本，
通常说明当前命令来自另一个 standalone 位置或 plugin 缓存。

使用 `council-uninstall --check` 可以预览 standalone 卸载目标。
只有带 `--apply` 才会删除。只有你也想删除 `.agent-council/` 讨论状态时，
才加 `--remove-state`。Codex plugin 安装应使用：

```sh
codex plugin remove agent-council@agent-council-marketplace
```

使用 `council-status {topic_id} --doctor` 可以检查大小写路径冲突、
turn 连续性、过期 consensus、status/consensus 漂移。

`council-open` 可以省略 topic-id。省略时会自动生成类似 `2026-06-03-1`
的日期序号名称。

使用 `council-longrun` 可以配置显式长跑辅助判断规则。它会在 chat 里用三组规整选项表
询问：subagents、peer review、combined assistance，并生成
`.agent-council/longrun/rules.md`。默认组合是 `balanced` subagents、`strategic`
peer review、以及 `high_risk` combined assistance：中等不确定时用 subagents，
设计/发布/安全/重大取舍时用 peer headless review，架构、blocker、发布/安全边界、
大范围变更或难回滚选择时两者一起用。`council-longrun` 不配置什么时候打断你；
辅助判断结论清楚、仍在授权 scope 内、且没有外部 hard gate 时，就继续往下执行。

    $council-longrun
    $council-longrun --show
    $council-longrun --template

使用 `council-longrun --template` 可以输出一段可复用的长跑任务启动 prompt。
模板可以在安装了 Superpowers 或项目说明要求 Superpowers 时默认按 Superpowers 流程走，
并要求后续执行在需要判断、取舍或额外信心时，按已保存的 `council-longrun`
辅助判断规则使用本地技术判断、peer review 或两者一起判断。

## 可选工具：council-peer

`council-peer` 不是 Council 主流程的一部分。它是一次性工具，用来 headless
调用对方工具。

在 Codex 中运行时，它通过 `claude -p` 调 Claude Code。在 Claude Code 中运行时，
它通过 `codex exec --sandbox read-only` 调 Codex。

它要求对方 CLI 已安装并在 `PATH` 中可用：从 Codex 调用时需要 `claude`，从
Claude Code 调用时需要 `codex`。默认不写 Council topic，也不修改项目文件。

如果提供了实质 prompt，它会发送该 prompt。如果没有提供实质 prompt，它会取所选最近可见
conversation rounds 作为上下文，让对方工具做一次聚焦 review。只有空白或标点不算 prompt。

conversation round 指一条用户消息，加上紧随其后的 Codex 或 Claude Code 回复。
默认使用最近 1 轮摘要。用 `-n` / `--rounds` 可以选择更多可见轮次；只有希望对方
收到所选可见文本全文时，才加 `--full`。

范围选择只使用可见的用户/助手聊天文本，不包含 system/developer 指令、tool schema、
隐藏推理或其他内部运行时上下文。

它不能自己读取无限制的 Codex 或 Claude 聊天记录。普通 headless review 默认 timeout 是
600 秒（10 分钟）。超时或无输出时要明确说明没有拿到分析结果。

运行中也应输出状态，包括 starting、已等待时间、completed、timed out 或
no-output 状态。

如果对方命令超时或没有有用输出，运行 `$council-peer --diagnose`。
诊断模式会检查检测到的对方命令、版本，以及一个只读短 ping。它不会写文件。

示例：

    $council-peer
    $council-peer --diagnose
    $council-peer -n=3 "Review the recent plan for blockers."
    /council-peer --codex-model gpt-5 "Review the latest plan for blockers."
    $council-peer --rounds=all --full "Summarize the visible conversation and call out risks."
    $council-peer "Review docs/design.md for blockers."
    $council-peer --topic product-l1-gate "Review the latest Council handoff for blockers."

## 开启话题

    $council-open retry-design -- 使用最近一个可见对话轮次作为交接内容。

也可以让 Council 自动选择 topic-id：

    $council-open -- 使用最近一个可见对话轮次作为交接内容。

skill 会把交接内容写入 `.agent-council/active/retry-design/`。

conversation round 指一条用户消息，加上紧随其后的 Codex 或 Claude Code 回复。
默认使用最近 1 个可见 round。用 `-n` / `--rounds` 可以选择更多可见轮次：

    $council-open -n=10 -- Review the recent plan changes.
    $council-open retry-design --rounds=all --full -- Preserve the visible context and review blockers.

latest handoff 应控制在 500 words 或 20 bullets 以内。不传 `--full` 时，
把所选轮次压缩成 decisions、evidence、blockers、open questions 和 requested peer
focus。传 `--full` 时，把可见源文本全文写入单独的
`turns/{turn_number}-{agent}-open-full-context.md` 附件，latest handoff 仍保持短摘要。

即使使用 `--full`，附件里也只允许包含可见的用户/助手聊天文本。

## 评审对方最新内容

    /council-review retry-design -- 重点看是否存在阻塞问题，以及是否可以继续推进。

评审方会读取对方最新内容，并把自己的意见写回同一个 topic。

## 继续往返

    $council-review retry-design -- 只回应对方提出的阻塞问题。

## 收敛

    /council-review retry-design CONSENSUS -- 如果只剩非阻塞问题，请写出最终共识。

`CONSENSUS` 是要求工具判断互审是否可以停止，不是要求无条件宣布自然一致。
仍有严重风险时，应根据用户指令写成 `BLOCKED` 或 `USER_FORCED_CONSENSUS`。

## 应用

    $council-apply retry-design -- 根据共识修改 docs/plan.md。

只有 `council-apply` 应该修改正式项目文件。

默认必须存在 `consensus.md` 才能 apply。如果没有共识文件，用户必须显式要求 apply latest。

每个会写文件的命令都应该显示简短 `Side effects` 摘要。
`council-review` 和 `council-open` 应报告没有修改正式项目文件。

`council-review` 应先输出 verdict，再给简短 topic 判断，
最后输出 `Next action` 和 `Side effects`。
除非 topic 本身就是 Agent Council，否则不要长篇解释 Council 工作流。

`Next action` 只是当前 topic 内建议，不是停止、恢复、commit、push、
merge、deploy 或进入下一 task 的授权。

## 说明

保持话题聚焦。除非 topic 本身就是 Agent Council，否则不要让工具分析 Council 工作流本身。
