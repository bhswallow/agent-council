# 协议说明

Agent Council v2 使用“最近轮次交接”模型。

## 手动唤入边界

Council 必须由用户显式唤醒。它不能自动叫停任务、自动创建 topic，
也不能插入普通 task flow。

如果出现人机交互节点，外围工作流应先停在 human gate。
用户可以手动选择是否运行 Council，但 Council 不能自行判断“必须介入”。

当一个 topic 结束后，Council 不会自动串联到下一个任务。
控制权回到普通用户/工具工作流。

`council-longrun` 只是一个很窄的例外，因为它必须由用户显式调用来记录长跑规则。
它不会自行启动 task、创建普通 Council topic、commit、push、merge、deploy，
也不会绕过 human gate。

## 长跑规则

`council-longrun` 为后续用户已授权的连续工作配置规则。

它通过几个简短选择题写入：

    .agent-council/longrun/rules.md
    .agent-council/longrun/history.md

这些规则可以告诉后续工作什么时候：

- 自己判断并继续；
- 使用 subagents；
- 使用 `council-peer-p` / `council-claude-p`；
- 同时使用 subagents 和 `council-peer-p`；
- 暂停并交给人类判断。

这些规则只在用户已经授权连续工作的前提下生效。
它们不授权新的 scope，不授权 task 外的正式项目修改，也不授权不可逆操作。
再次运行 `council-longrun` 会重新定义规则。

## 对方 headless 工具

`council-peer-p` 是可选的一次性对方工具 headless 调用命令的推荐中性名称。
`council-claude-p` 作为兼容别名继续可用。

在 Codex 中运行时，它通过 `claude -p` 调 Claude Code。在 Claude Code 中运行时，
它通过 `codex exec --sandbox read-only` 调 Codex。

这个工具不是 Council 互审循环的一部分。它不声明 consensus，不触发
`council-apply`，默认不写 Council topic。它只能使用所选可见上下文或用户显式提供的上下文。

## Council 外的可选提醒

外层工作流说明可以在头脑风暴、design、plans、specs、一个 task batch 完成、
或遇到卡点后，提醒用户可以选择 Council。

提醒必须简短、可选，并使用用户当前语种。它不能调用 Council，不能停止工作流，
也不能暗示 Council 是必需的。如果用户没有要求 Council，就继续执行已批准工作流。

## 工作区

运行时状态统一放在：

    .agent-council/active/{topic_id}/

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

## 对话轮次

conversation round 指一条用户消息，加上紧随其后的 Codex 或 Claude Code
助手回复。如果最新可见用户消息后还没有助手回复，则视为未完成轮次。

这和 Council 目录里的 `turns/` 不同。`turns/` 是某个 agent 执行一次 Council
命令后写下的紧凑记录。

上下文范围只能选择当前聊天里可见的用户消息和助手回复。不要包含
system/developer 指令、tool schema、隐藏 chain-of-thought 或其他内部运行时上下文。

对支持上下文范围的命令：

- 不传 `-n` / `--rounds`：选择最近 1 个可见 conversation round；
- 单独传 `-n` 或 `--rounds`：选择最近 1 个可见 conversation round；
- `-n={N}` 或 `--rounds={N}`：选择最近 `N` 个可见 round；
- `-n=all` 或 `--rounds=all`：选择当前聊天窗口里全部可见的用户/助手 round。

不传 `--full` 时，会摘要所选轮次。传 `--full` 时，根据具体命令的写入策略，
保留或发送所选可见文本全文。

## Topic ids

`council-open` 可以不传 topic-id。

用户省略时，直接自动生成，不要追问：

- 默认格式：`{YYYY-MM-DD}-{n}`，例如 `2026-06-03-1`；
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

写入 `latest/{agent}.md` 或 `latest/for-peer.md` 时，控制在：

- 500 words 以内；或
- 20 bullets 以内。

原始内容较长时，压缩成 decisions、evidence、blockers、open questions
和 requested peer focus。

除非某个旧细节仍是下一步决策所必需，否则不要把它从上一轮 latest 继续滚动带入。

如果使用 `council-open --full`，latest 文件仍保持短摘要，全文可见源内容写入单独的
`turns/{turn_number}-{agent}-open-full-context.md` 附件。

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

`council-longrun` 只写 `.agent-council/longrun/` 下的长跑规则。
它不能创建普通 Council topic，也不能修改正式项目文件。

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

`Next action` 只是当前 Council topic 内的建议。它不是停止、恢复、
串联任务、commit、push、merge、deploy 或进入新阶段的授权。

如果状态是 `NEEDS_DISCUSSION`，给出对方工具应执行的精确命令。

如果状态是 `CONSENSUS` 或 `CONSENSUS_WITH_NITS`，说明不建议继续互审，
说明控制权回到普通工作流；只有正式项目文件需要修改时，才把
`council-apply` 作为可选下一步。

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

`council-status {topic_id} --doctor` 检查：

- `latest/CLAUDE.md` 这类大小写冲突路径；
- 是否缺少 `latest/for-peer.md`；
- 预期存在时是否缺少 peer latest 文件；
- turn 编号是否不连续；
- `status.md` state 是否和 `consensus.md` 不一致；
- consensus 是否落后于最新记录的 turn；
- review 轮次是否有修改正式项目文件的迹象。

doctor 应输出简短 `OK` 和 `Warnings` 列表，不应强制实现重型状态机。

doctor 不能因为任务在没有 Council 的情况下继续执行，就建议 Council 介入。
Council 是 opt-in 工具。
