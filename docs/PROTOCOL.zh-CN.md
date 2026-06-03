# 协议说明

Agent Council v2 使用“最新一轮交接”模型。

## 工作区

运行时状态统一放在：

    .agent-council/active/<topic-id>/

推荐文件：

    topic.md
    status.md
    latest/codex.md
    latest/claude.md
    latest/for-peer.md
    latest/user-request.md
    turns/0001-codex-open.md
    turns/0002-claude-review.md
    consensus.md
    applied/0003-apply.md

## 读取策略

默认只读取：

- `topic.md`
- `status.md`
- `latest/` 下对方最新内容
- `latest/for-peer.md`
- 如存在，则读取 `consensus.md`

默认不读取其他 topic，也不读取 archive 或完整历史。

## 聚焦策略

主题是用户指定的 topic。除非用户明确要求，否则 Council 机制本身不是讨论主题。

如果对方内容里包含流程性文字，只提取其中实际的技术或产品内容进行评审。

## 写入策略

`council-open`、`council-review`、`council-respond`、`council-status` 只写 Council 状态。

`council-apply` 可以修改正式项目文件，但必须有用户的 apply 要求，或目标文件非常明确。

## 共识

双方一致，或用户传入 `CONSENSUS` 时，写入 `consensus.md`。

如果用户在仍有实质风险时强制收敛，必须清楚记录这些风险。
