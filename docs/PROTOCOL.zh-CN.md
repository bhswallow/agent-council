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

agent id 统一使用小写。内置合法值是 `claude` 和 `codex`。路径只能使用小写 agent id。

## Topic ids

`council-open` 可以不传 topic-id。

用户省略时，直接自动生成，不要追问：

- 默认格式：`<YYYY-MM-DD>-<n>`，例如 `2026-06-03-1`；
- 选择 active 或 archive 中尚未使用的第一个正整数；
- 如果用户说明里有明显短主题，也可以使用类似 `review-l1-spike` 的简短 slug。

不要让命名变成阻塞步骤。

## 读取策略

默认只读取：

- `topic.md`
- `status.md`
- `latest/` 下对方最新内容
- `latest/for-peer.md`
- 如存在，则读取 `consensus.md`

默认不读取其他 topic，也不读取 archive 或完整历史。

## Handoff 大小预算

写入 `latest/<agent>.md` 或 `latest/for-peer.md` 时，控制在：

- 500 words 以内；或
- 20 bullets 以内。

原始内容较长时，压缩成 decisions、evidence、blockers、open questions
和 requested peer focus。

除非某个旧细节仍是下一步决策所必需，否则不要把它从上一轮 latest 继续滚动带入。

## 聚焦策略

主题是用户指定的 topic。除非用户明确要求，否则 Council 机制本身不是讨论主题。

如果对方内容里包含流程性文字，只提取其中实际的技术或产品内容进行评审。

除非 topic 本身就是 Agent Council，否则不要评审 Agent Council 协议、文件结构、skill 行为或工作流机制。

`council-review` 面向用户的输出应该保持紧凑：

- 先给 verdict；
- 再给简短 topic 判断；
- 只在有价值时列出 blockers 或 must-preserve nits；
- 输出 `Next action`；
- 输出 `Side effects`。

正常 topic review 不要长篇解释 Council 协议。

## 轻量 metadata

`turns/*` 和 `consensus.md` 可以使用简短 YAML frontmatter：

```yaml
topic: product-l1-gate
agent: claude
turn: 5
state: CONSENSUS_WITH_NITS
formal_files_modified: false
```

默认不要添加大段 metadata。bridge 应该保持低读取成本。

## status.md 结构

使用稳定结构：

```yaml
topic: product-l1-gate
state: REVIEW_REQUESTED
turn: 1
last_agent: codex
next_agent: claude
updated_at: 2026-06-03T12:00:00Z
latest_handoff: latest/for-peer.md
consensus:
```

合法 `state` 值：

- `REVIEW_REQUESTED`
- `DISCUSSION`
- `NEEDS_DISCUSSION`
- `CONSENSUS`
- `CONSENSUS_WITH_NITS`
- `USER_FORCED_CONSENSUS`
- `USER_DECISION_NEEDED`
- `BLOCKED`
- `APPLIED`
- `CLOSED`
- `ABANDONED`

## 写入策略

`council-open`、`council-review`、`council-status` 只写 Council 状态。

`council-apply` 可以修改正式项目文件，但必须有用户的 apply 要求，或目标文件非常明确。

## 共识

双方自然一致时，写入 `CONSENSUS`。

双方方向一致、只剩非阻塞小问题时，写入 `CONSENSUS_WITH_NITS`。

如果用户传入 `CONSENSUS` 但仍有实质风险，写入 `USER_FORCED_CONSENSUS`，并清楚记录风险。

不要把用户强制停止写成双方自然一致。

使用简短共识模板：

- verdict；
- decision / ready-for；
- forbidden actions；
- blockers；
- must-preserve nits；
- side effects。

## 下一步动作

每次 `council-review` 面向用户的回复都必须以 `Next action` 结束。

如果状态是 `NEEDS_DISCUSSION`，给出对方工具应执行的精确命令。

如果状态是 `CONSENSUS` 或 `CONSENSUS_WITH_NITS`，说明不建议继续互审，并把 `council-apply` 作为可选下一步。

如果状态是 `USER_DECISION_NEEDED`，列出需要用户拍板的问题，不要继续交给另一个 agent。

如果状态是 `BLOCKED`，说明除非用户明确覆盖风险，否则不能 apply。

## 副作用摘要

每个会写文件的命令都应该包含简短副作用摘要：

- 修改了哪些 Council 文件；
- 修改了哪些正式项目文件；
- 是否产生代码变更；
- 下一步动作。

对 `council-open` 和 `council-review` 来说，正式项目文件和代码变更应为 `none`。

## doctor 检查

`council-status <topic-id> --doctor` 检查：

- `latest/CLAUDE.md` 这类大小写冲突路径；
- 是否缺少 `latest/for-peer.md`；
- 预期存在时是否缺少 peer latest 文件；
- turn 编号是否不连续；
- `status.md` state 是否和 `consensus.md` 不一致；
- consensus 是否落后于最新 turn；
- review 轮次是否有修改正式项目文件的迹象。

doctor 应输出简短 `OK` 和 `Warnings` 列表，不应强制实现重型状态机。
