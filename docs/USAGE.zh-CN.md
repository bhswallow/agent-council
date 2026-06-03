# 使用说明

Agent Council v2 是一个“最新一轮交接”桥梁。它适合 Claude Code 和 Codex 需要互相评审对方最新内容，但又不共享同一个聊天窗口的场景。

## 命令

    council-open <topic-id> [-- 交接说明]
    council-review <topic-id> [CONSENSUS] [-- 评审要求]
    council-apply <topic-id> [-- 应用要求]
    council-status [topic-id|all]
    council-help [zh|en]

`council-respond` 已在 v2.0.2 移除。请改用 `council-review`。

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

## 应用

    $council-apply retry-design -- 根据共识修改 docs/design.md。

只有 `council-apply` 应该修改正式项目文件。

## 说明

保持话题聚焦。除非 topic 本身就是 Agent Council，否则不要让工具分析 Council 工作流本身。
