# 使用说明

Agent Council v2 是一个“最新一轮交接”桥梁。它适合 Claude Code 和 Codex 需要互相评审对方最新内容，但又不共享同一个聊天窗口的场景。

评审必须聚焦 topic 本身。除非 topic 本身就是 Agent Council，否则不要把讨论变成对 Council 协议或流程机制的评审。

agent id 和路径统一小写：`claude`、`codex`、`latest/claude.md`、`latest/codex.md`。

## 命令

    council-open <topic-id> [-- 交接说明]
    council-review <topic-id> [CONSENSUS] [-- 评审要求]
    council-apply <topic-id> [-- 应用要求]
    council-status [topic-id|all] [--doctor]
    council-help [zh|en]
    council-upgrade [--check] [--claude-only|--codex-only]

`council-respond` 已在 v2.0.2 移除。请改用 `council-review`。

使用 `council-upgrade` 可以从最新仓库版本更新 standalone 安装。

使用 `council-status <topic-id> --doctor` 可以检查大小写路径冲突、turn 连续性、过期 consensus、status/consensus 漂移。

## 开启话题

    $council-open retry-design -- 使用我最近一次回复作为交接内容，请对方判断下一步是否合理。

skill 会把交接内容写入 `.agent-council/active/retry-design/`。

## 评审对方最新内容

    /council-review retry-design -- 重点看是否存在阻塞问题，以及是否可以继续推进。

评审方会读取对方最新内容，并把自己的意见写回同一个 topic。

## 继续往返

    $council-review retry-design -- 只回应对方提出的阻塞问题。

## 收敛

    /council-review retry-design CONSENSUS -- 如果只剩非阻塞问题，请写出最终共识。

`CONSENSUS` 是要求工具判断互审是否可以停止，不是要求无条件宣布自然一致。仍有严重风险时，应根据用户指令写成 `BLOCKED` 或 `USER_FORCED_CONSENSUS`。

## 应用

    $council-apply retry-design -- 根据共识修改 docs/design.md。

只有 `council-apply` 应该修改正式项目文件。

默认必须存在 `consensus.md` 才能 apply。如果没有共识文件，用户必须显式要求 apply latest。

每个会写文件的命令都应该显示简短 `Side effects` 摘要。`council-review` 和 `council-open` 应报告没有修改正式项目文件。

## 说明

保持话题聚焦。除非 topic 本身就是 Agent Council，否则不要让工具分析 Council 工作流本身。
