# 使用说明

Agent Council v2.7.2 是一个“最新一轮交接”桥梁。
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

    council-open [topic-id] [-- 交接说明]
    council-review {topic_id} [CONSENSUS] [-- 评审要求]
    council-apply {topic_id} [-- 应用要求]
    council-status [topic-id|all] [--doctor]
    council-help [zh|en]
    council-version [--check]
    council-upgrade [--check|--apply] [--ref {git_ref}] [--claude-only|--codex-only]

`council-respond` 已在 v2.0.2 移除。请改用 `council-review`。

使用 `council-upgrade` 可以检查 standalone 安装版本。
它默认只检查不修改。使用 `council-upgrade --apply` 才会更新；
只有需要指定 branch、tag 或 commit 时才加 `--ref {git_ref}`。

使用 `council-version` 确认当前实际生效的安装版本。

如果 `council-upgrade` 完成后 `council-help` 仍显示旧版本，
通常说明当前命令来自另一个 standalone 位置或 plugin 缓存。

使用 `council-status {topic_id} --doctor` 可以检查大小写路径冲突、
turn 连续性、过期 consensus、status/consensus 漂移。

`council-open` 可以省略 topic-id。省略时会自动生成类似 `2026-06-03-1`
的日期序号名称。

## 可选工具：council-claude-p

`council-claude-p` 不是 Council 主流程的一部分。它是一次性工具，用于在本机已经安装
Claude Code CLI 且 `claude` 在 `PATH` 中可用时，运行 Claude Code 原生
headless 命令 `claude -p`。

用户输入 `$council-claude-p ...` 作为 skill 命令。底层子进程才是 Claude Code
原生命令 `claude -p`。

它不依赖 Codex CLI。默认不写 Council topic，也不修改项目文件。

它只会收到显式 prompt，不能自动读取当前 Codex 或 Claude 聊天记录。
执行时应使用有界 timeout，并在超时或无输出时明确说明没有拿到分析结果。

运行中也应输出状态，包括 starting、已等待时间、completed、timed out 或
no-output 状态。

示例：

    $council-claude-p "Review docs/design.md for blockers."
    $council-claude-p --topic product-l1-gate "Review the latest Council handoff for blockers."

## 开启话题

    $council-open retry-design -- 使用我最近一次回复作为交接内容。

也可以让 Council 自动选择 topic-id：

    $council-open -- 使用我最近一次回复作为交接内容。

skill 会把交接内容写入 `.agent-council/active/retry-design/`。

latest handoff 应控制在 500 words 或 20 bullets 以内。原始内容较长时，
只保留 decisions、evidence、blockers、open questions 和 requested peer focus。

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
