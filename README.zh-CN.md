# Agent Council

当前版本：2.10.5

Agent Council 是 Claude Code 与 Codex 之间的轻量手动交接板，按最近可见对话轮次交接上下文。

当一个工具希望另一个工具评审最新理由、风险提醒或共识时使用它。

它不会自动调用另一个工具，只会把很小的 topic 状态写入 `.agent-council/`，
并把控制权留给用户。

## 60 秒演示

```text
# Codex 开启一个给 Claude Code 的交接。
$council-open checkout-design -- 请让 Claude Code 评审这个最新设计决策。

# Claude Code 只评审 blocker。
/council-review checkout-design -- 只评审阻塞问题。

# Codex 判断能否收敛。
$council-review checkout-design CONSENSUS -- 如果没有 blocker，请收敛成共识。
```

结果会保存到：

```text
.agent-council/active/checkout-design/consensus.md
```

## 快速安装

standalone 项目安装：

```sh
./install.sh /path/to/your/project
```

Claude Code plugin：

```text
/plugin marketplace add bhswallow/agent-council
/plugin install agent-council@agent-council-marketplace
/reload-plugins
```

Codex plugin：

```sh
codex plugin marketplace add bhswallow/agent-council
```

然后打开 Codex，执行 `/plugins`，选择 Agent Council marketplace，安装
`agent-council`。

## 什么时候用

适合在阶段边界、卡点、或某个决策需要另一个工具评审时使用。不要每个 task 都用。

它不是流程引擎，而是一个带少量防错护栏的共享记事板。
它必须由用户显式唤醒，不应自动叫停任务、自动创建 topic，或插入普通 task 步骤之间。

更多细节见 [docs/USAGE.zh-CN.md](docs/USAGE.zh-CN.md) 和
[docs/PROTOCOL.zh-CN.md](docs/PROTOCOL.zh-CN.md)。

## 安全模型

Agent Council：

- 不收集 token；
- 不上传代码；
- 不默认执行远程命令；
- 不自动调用 Claude Code 或 Codex；
- 把本地 topic 状态保存在 `.agent-council/`；
- 只有用户显式运行可选工具时，才会使用 `council-peer-p` /
  `council-claude-p`。

报告问题和信任边界见 [SECURITY.md](SECURITY.md)。

## 仓库健康文件

- 贡献指南：[CONTRIBUTING.md](CONTRIBUTING.md)
- 行为规范：[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- Issue 模板：[.github/ISSUE_TEMPLATE](.github/ISSUE_TEMPLATE)
- PR 模板：[.github/PULL_REQUEST_TEMPLATE.md](.github/PULL_REQUEST_TEMPLATE.md)
- release 和目录提交清单：[docs/RELEASE_AND_DISCOVERY.md](docs/RELEASE_AND_DISCOVERY.md)

## 命令

Agent Council 的评审环路刻意保持简单：

- `council-open` 开启一个 topic，并记录所选最近轮次交接内容。
  topic-id 可以省略。
- `council-review` 读取对方最新交接内容并给出评审或回应。
- `council-apply` 把已经达成一致的结果应用到正式项目文件。
- `council-status` 查看 topic 状态，也可以执行 `--doctor` 检查。

支持命令也必须显式调用：

- `council` 查看顶层命令索引。
- `council-help` 查看简短帮助。
- `council-version` 输出当前安装版本。
- `council-upgrade` 检查更新；只有显式使用 `--apply` 时才更新 standalone 安装。
- `council-uninstall` 预览或显式移除 standalone 安装。
- `council-longrun` 配置显式长跑辅助判断规则：什么时候用 subagents、
  peer headless review，或两者一起辅助判断后继续。

`council-respond` 已在 v2.0.2 移除。
请统一使用 `council-review` 完成评审、回应、反驳、确认和收敛。
安装脚本也会清理旧版残留的 standalone `council-respond` 目录。

Agent Council 应始终聚焦用户当前话题。
除非 topic 本身就是 Agent Council，否则不要评审 Council 协议、文件结构、skill 行为或工作流机制。

## 解决什么问题

Claude Code 和 Codex 不共享同一个聊天窗口。
工作在两个工具之间切换时，最近一次结论、理由或下一步建议很容易丢失。

Agent Council 会把最新交接内容写入：

```text
.agent-council/active/{topic_id}/
```

另一个工具读取这个 topic 下的最新内容，继续评审和回应实际话题。

正式项目文件保持干净，直到你显式执行 `council-apply`。

## 手动唤入边界

Council 是 opt-in 工具。agent 和工作流不应该自动打开 Council，
即使它们发现了风险。出现需要人机交互的节点时，应先停在 human gate；
用户可以再手动决定是否让 Council 介入。

Council 可以：

- 在用户执行 `council-open` 时记录交接；
- 在用户执行 `council-review` 时评审当前 topic；
- 保存该 topic 的共识；
- 仅在用户执行 `council-apply` 时应用已同意的修改。

Council 禁止：

- 作为自动 task gate；
- 自行叫停或阻塞无关任务执行；
- 为每个 task 自动创建 Council topic；
- 断定某个人机交互点必须使用 Council；
- 在一个 topic 结束后自动串联到下一个任务。

`council-longrun` 只有一个很窄的例外：当用户显式运行它时，它可以记录用户批准的
长跑规则。它仍然不会自行启动 task、创建 Council topic、commit、push、merge、
deploy，或覆盖 human gate。

当 topic 进入 consensus、blocked、closed、abandoned 或 applied 状态后，
控制权回到普通用户/工具工作流。后续 task 只能来自用户的普通任务指令，
不能由 Council 自动连接。

## 可选工作流提醒

外层工作流，例如 `CLAUDE.md`、`AGENTS.md`、Superpowers 或项目 memory，
可以在合适的阶段边界简短提醒用户可以选择 Council：

- 头脑风暴结束后；
- 写完 design 后；
- 写完 plans 后；
- 写完 specs 后；
- 一个计划内 task batch 全部完成后；
- 工作流卡住或需要用户决策时。

这些提醒是可选的，并且必须匹配用户当前语种。用户正在用中文，就用中文提醒；
用户正在用英文，就用英文提醒。

提醒不能自动调用 Council，不能自行停止执行，也不能暗示 Council 是必需的。
如果用户没有要求 Council 介入，就按已批准工作流继续。

示例：

```text
Design 已完成。
可选：如果你希望让另一个工具评审，可以手动运行 Council：
$council-open checkout-design -- 请评审这个 design。

如果你不要求 Council 介入，我会按已批准流程继续。
```

## 长跑规则

当你希望后续已授权的长时间工作先用辅助判断、再自动继续，减少反复人工确认时，可以运行：

```text
$council-longrun
```

这个 skill 会用三组规整选择题生成规则，并保存到：

```text
.agent-council/longrun/rules.md
```

规则会定义后续工作什么时候使用：

- subagents 做本地/技术辅助判断；
- `council-peer-p` / `council-claude-p` 做独立 peer 辅助判断；
- subagents 和 `council-peer-p` 一起处理复杂或高风险判断。

`council-longrun` 不配置什么时候打断你。打断点仍归外围 workflow、用户指令、
tool policy、凭据、sandbox、发布流程或其他外部 hard gate 管。原本 workflow 可能要停下来
做人为判断时，先按这里的规则运行辅助判断；如果结论清楚、仍在用户授权 scope 内、且没有外部
hard gate，就继续往下执行。

推荐默认值是：

- subagents: `balanced`：中等不确定、跨文件、覆盖不清、实现路径不确定时用
  subagents；
- peer review: `strategic`：design、plan、发布前、安全/权限边界、重大取舍时跑
  `council-peer-p`，不用于普通小改动；
- combined assistance: `high_risk`：架构、发布、安全边界、blocker、重大取舍、大范围变更、
  难回滚选择时同时用 subagents 和 `council-peer-p`。

其他选项也会明确说明：

- subagents `light`：只在明显复杂或不清楚时用 subagents；
- subagents `thorough`：多数非平凡实现和测试策略都先用 subagents；
- peer review `implementation`：代码层面的实现风险也交给 peer review；
- peer review `manual`：除非你明确要求，否则不跑 peer review；
- combined assistance `escalation`：先走单一路线，只有发现未解决风险、意见冲突或证据不足时
  再两者一起用；
- combined assistance `intensive`：多数跨模块、迁移、数据/并发、弱覆盖、复杂回滚风险都同时用两者。

旧规则里可能会看到 `human_pause_policy`、`pause_for_human` 或 `git_finalization`。
这些是旧版 longrun 字段。新规则使用 `version: 3`，不再配置打断或 git 收尾策略。

再次运行 `council-longrun` 可以重新定义规则。
运行 `council-longrun --show` 可以查看当前规则。

这些规则只适用于用户已经授权的连续工作，不授权新的 scope，也不授权越过人类确认去执行
危险 git、发布、删除数据、公开副作用、凭据访问或安全边界变更。

## 如何选择工具

Agent Council 是直接调用工具的补充，不是替代品。

| 工具 | 解决什么 | 优点 | 取舍 | 适合场景 |
| --- | --- | --- | --- | --- |
| Agent Council | 手动 recent-round 交接、互评、共识保存 | 文件显式、设置轻、不隐藏调用、`council-apply` 前不污染项目文件 | 需要用户手动切到另一个工具；不是即时互调；不自动获取对方回答 | 需要可追溯决策记录和明确 apply 边界 |
| Claude Code 中的 Codex 插件 | 在 Claude Code 里直接问 Codex，做一次性 review 或替代方案 | 快速获得第二意见，不必离开 Claude Code | 需要额外配置；可能有 token/API 成本；除非写记录，否则不如 Council 可追溯 | 速度比可审计交接更重要 |
| 通过 `council-peer-p` 调对方工具 | 从 Codex 调 Claude，或从 Claude Code 调 Codex | 适合脚本化检查、JSON review、类似 CI 的单轮任务 | 需要打包 prompt/context；对方工具的认证、计费和限制独立 | 任务天然是一次性脚本调用 |

可以组合使用：先用直接调用快速探路，只有当结果需要成为共享决策时，再用 Agent Council 落盘。

参考：

- Codex 内置 `/plugins` 和已安装 Codex app 中的 plugin 文档。
- [Claude Code CLI reference](https://code.claude.com/docs/en/cli-usage)
- [Run Claude Code programmatically](https://code.claude.com/docs/en/headless)

## 可选工具：council-peer-p

`council-peer-p` 是 optional utility（可选工具），不是 Agent Council 主流程的一部分。
`council-claude-p` 作为历史兼容别名继续可用。Council 主流程仍然是
`council-open`、`council-review`、`council-apply`、`council-status` 和
`council-help`。

这个工具会 headless 调用“对方工具”：

- 在 Codex 中运行时，调用 Claude Code 的 `claude -p`。
- 在 Claude Code 中运行时，调用 Codex 的 `codex exec --sandbox read-only`。

使用前提和边界：

- 新调用推荐使用 `council-peer-p`；`council-claude-p` 仍然兼容。
- 对方 CLI 必须已经安装并在 `PATH` 中可用。
- 从 Codex 调用时，对方命令是 `claude`。
- 从 Claude Code 调用时，对方命令是 `codex`。
- Agent Council 不负责安装或配置 Claude Code 或 Codex。
- 对方工具只会收到 skill 选中的 prompt/context，不能自己读取无限制的 Codex 或 Claude Code 聊天记录。
- 支持用 `-n` / `--rounds` 选择最近可见 conversation rounds，并用 `--full`
  发送所选可见文本全文。
- 默认不写 Council topic。
- 默认不修改项目文件；从 Claude Code 调 Codex 时默认使用 `--sandbox read-only`。
- 不会声明 consensus，也不会触发 `council-apply`。
- 应使用有界 timeout；超时时要明确说明没有拿到对方分析结果。
- 普通 headless review 默认 timeout 是 600 秒（10 分钟）。
- `--diagnose` 会对当前检测到的对方 CLI 做短诊断。
- 运行时应输出状态：`starting`、`running`、`completed`、`timed out` 或
  `no output`。

示例：

```text
$council-peer-p
$council-peer-p --diagnose
$council-peer-p -n=3 "Review the recent plan for blockers."
/council-peer-p --codex-model gpt-5 "Review the latest plan for blockers."
$council-claude-p
$council-claude-p --rounds=all --full "Summarize the visible conversation and call out risks."
$council-claude-p "Review docs/design.md for blockers and missing tests."
$council-claude-p --output-format json "Summarize the current repository risks."
$council-claude-p --allowed-tools "Read,Grep,Glob" "Review docs/design.md for blockers."
$council-peer-p --topic product-l1-gate "Review the latest Council handoff for blockers."
```

如果 `$council-peer-p` 后面没有实质文字，只有空白或标点也会被视为没有
prompt。此时 skill 会取所选最近可见 conversation rounds 作为上下文，自动组织一个
适合对方工具的单轮 review 问题，例如检查 blocker、遗漏假设、风险，以及是否适合继续
推进。它应根据当前 topic 和语种调整问题，而不是套固定模板。

conversation round 指一条用户消息，加上紧随其后的 Codex 或 Claude Code 回复。
默认使用最近 1 个可见 round 的摘要。用 `-n` / `--rounds` 可以选择更多可见轮次；
只有希望对方收到所选可见文本全文时，才加 `--full`。`--allowed-tools` 和
`--output-format` 只在从 Codex 调 Claude 时有效；Codex 分支可用
`--codex-model`、`--codex-profile` 和 `--codex-sandbox`。

只有当你明确希望保存到 Council topic 时，才使用 `--topic {topic_id}`。
保存路径是：

```text
.agent-council/active/{topic_id}/latest/council-peer-p.md
```

历史兼容别名 `council-claude-p` 继续使用兼容路径：

```text
.agent-council/active/{topic_id}/latest/council-claude-p.md
```

这个文件只是保存在 topic 下的外部 peer-headless 附件，不等同于交互式 Council
review。若要进入标准 Council 互审循环，仍需手动运行 `council-open` /
`council-review`。

如果你希望对方工具总结更长的历史聊天，请把相关内容粘贴到 prompt，或保存成文件后在
prompt 中引用该文件。headless 对方命令只会收到 skill 选中的 prompt/context，
不能自己读取无限制的当前聊天记录。

`council-peer-p` 不应该让用户盯着空白等待。它应该在 headless 进程启动时提示，
运行中报告已等待时间，结束时明确说明是完成、超时，还是没有输出。

如果它超时或没有有用输出，可以运行：

```text
$council-peer-p --diagnose
```

诊断模式会检查检测到的对方命令路径、版本，以及一个只读短 ping：`claude -p` 或
`codex exec --sandbox read-only`。它不会写 Council topic，也不会修改项目文件。

## Topic 文件

一个 topic 是一次独立讨论，例如：

```text
.agent-council/active/retry-design/
```

常见文件包括：

- `topic.md`：话题说明和初始交接内容。
- `latest/codex.md`：Codex 给 Claude Code 的最新内容。
- `latest/claude.md`：Claude Code 给 Codex 的最新内容。
- `latest/for-peer.md`：当前应由对方读取的交接内容。
- `latest/user-request.md`：当前轮用户的最新要求。
- `turns/`：简短轮次记录，方便追溯。
- `consensus.md`：最终共识。
- `status.md`：当前状态。

默认只读取当前 topic 和对方最新内容。
除非你明确要求，不应该扫描全部 turns、archive 或无关项目文件。

## 对话轮次

conversation round 指一条用户消息，加上紧随其后的 Codex 或 Claude Code 回复。
这和 Council 目录里的 `turns/` 不同：`turns/` 是某个 agent 执行一次 Council
命令后的紧凑记录文件。

支持上下文范围的命令使用：

- 不传 `-n` / `--rounds`：最近 1 个可见 conversation round；
- 单独传 `-n` 或 `--rounds`：最近 1 个可见 conversation round；
- `-n=10` 或 `--rounds=10`：最近 10 个可见 round；
- `-n=all` 或 `--rounds=all`：当前聊天窗口里全部可见的用户/助手 round。

默认使用摘要。`--full` 才保留或发送所选可见文本全文。全文模式也只使用可见的
用户/助手聊天文本，不包含 system/developer 指令、tool schema、隐藏推理或其他内部
运行时上下文。

## 轻量护栏

Agent Council 保持轻量，但使用少量高收益护栏：

- `council-open` 可以在用户省略 topic-id 时自动生成。
- `council-open` 支持 `-n` / `--rounds` 和 `--full`，用于选择最近可见
  conversation rounds。
- agent id 统一为小写：`claude` 和 `codex`。
- 文件路径使用小写 agent id：
  `latest/claude.md`、`latest/codex.md`、`turns/0005-claude-review.md`。
- latest handoff 应控制在 500 words 或 20 bullets 以内。
- `council-open` 和 `council-review` 只能写 `.agent-council/`。
- 只有 `council-apply` 可以修改正式项目文件。
- 命令回复包含简短 `Side effects` 摘要。
- `council-status {topic_id} --doctor` 检查常见一致性问题。

目标是低摩擦交接桥梁加少量防错，而不是严格状态机。

## 自动 Topic Id

你可以自己给 topic 命名：

```text
$council-open product-l1-gate -- 请评审当前 gate 标准。
```

也可以省略 topic-id：

```text
$council-open -- 请评审最新方案。
```

没有提供 topic-id 时，`council-open` 会直接自动生成，不再追问。
默认格式是日期加序号：

```text
2026-06-03-1
2026-06-03-2
```

如果交接说明里有明显短主题，也可以使用类似 `review-l1-spike` 的简短 slug。
起名不应该成为阻塞步骤。

## Handoff 大小预算

bridge 默认读取最近 1 个可见 conversation round，因此 latest 文件必须保持短。

写入 `latest/{agent}.md` 和 `latest/for-peer.md` 时，控制在：

- 500 words 以内；或
- 20 bullets 以内。

不传 `--full` 时，如果所选轮次更长，只保留：

- decisions；
- evidence；
- blockers；
- open questions；
- requested peer focus。

不要因为旧 latest 里有很多细节，就把它们继续滚动带到下一轮。

使用 `council-open --full` 时，把可见源文本全文写入单独的
`turns/{turn_number}-{agent}-open-full-context.md` 附件，`latest/{agent}.md`
和 `latest/for-peer.md` 仍保持短摘要。

## Topic 状态

`status.md` 使用一组小而稳定的状态：

- `REVIEW_REQUESTED`：交接内容已准备好，等待对方评审。
- `DISCUSSION`：双方仍在交换实质意见。
- `CONSENSUS`：双方自然达成一致。没有 blocker，也没有 disputed decision，可以停止互审。
- `CONSENSUS_WITH_NITS`：方向一致，只剩非阻塞小问题。
  默认不建议继续互审，可以进入 apply 或下一阶段。
- `USER_FORCED_CONSENSUS`：用户显式传入 `CONSENSUS` 要求停止讨论，但仍可能有未解决问题。
  必须记录这是用户强制收敛，不得写成双方自然一致。
- `NEEDS_DISCUSSION`：仍有需要对方回应的问题。
  输出时必须告诉用户下一步应该让哪个工具执行哪条 `council-review` 命令。
- `USER_DECISION_NEEDED`：双方无法判断或存在取舍，需要用户拍板。
  不要继续让两个 agent 无限互审。
- `BLOCKED`：存在安全、数据丢失、不可回滚、需求缺失或证据不足等阻塞问题。
  除非用户明确覆盖风险，否则不能进入 apply。
- `APPLIED`：共识已经被应用到正式产物。
- `CLOSED`：话题已经关闭，除非用户显式 reopen，否则不应继续 review。
- `ABANDONED`：话题已经放弃，除非用户显式 reopen，否则不应继续 review。

稳定的 `status.md` 结构如下：

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

合法 `state` 至少包括：

```text
REVIEW_REQUESTED
DISCUSSION
NEEDS_DISCUSSION
CONSENSUS
CONSENSUS_WITH_NITS
USER_FORCED_CONSENSUS
USER_DECISION_NEEDED
BLOCKED
APPLIED
CLOSED
ABANDONED
```

## CONSENSUS 用法

当你希望工具判断讨论是否可以停止时，使用 `CONSENSUS`：

```text
$council-review product-l1-gate CONSENSUS -- \
  If you agree there are no blockers, converge and preserve the status/evidence matrix requirement.
```

这不是要求模型无条件宣布自然共识。

- 如果确实没有 blocker，应输出 `CONSENSUS` 或 `CONSENSUS_WITH_NITS`。
- 如果还有分歧但用户要求停止，应输出 `USER_FORCED_CONSENSUS`。
- 如果仍有严重 blocker，必须明确提示风险，并要求用户确认是否强制推进。

`council-review` 每次结束时都必须给出 `Next action`。

如果状态是 `NEEDS_DISCUSSION`，必须给出让对方执行的精确命令。

如果状态是 `CONSENSUS` 或 `CONSENSUS_WITH_NITS`，必须明确说：

```text
No further peer-review round is recommended.
```

并可以给出可选下一步：

```text
$council-apply {topic_id} -- Apply the consensus.
```

如果状态是 `USER_DECISION_NEEDED`，必须列出用户需要拍板的问题。
不要让另一个 agent 继续 review。

如果状态是 `BLOCKED`，必须说明不能 apply，除非用户明确覆盖风险。

Codex skill metadata 使用 `allow_implicit_invocation: false`，确保 Council 命令只能由用户显式唤醒，
不会自动触发。不要给 Council skills 使用 `disable-model-invocation: true`，
因为这会让 `$council-peer-p` 这类显式命令从 Codex 可用 skill 列表里消失。
下一步命令由 `council-review` 的输出规则决定。

Council 的 next-step guidance 只是当前 topic 内的建议。
它不是停止、恢复、串联、commit、push、merge、deploy 或进入下一 task 的授权。
这些决定仍属于普通用户/工具工作流。

共识文件应该短而稳定：

```markdown
---
topic: product-l1-gate
state: CONSENSUS_WITH_NITS
agent: codex
turn: 6
formal_files_modified: false
---

# Consensus

Verdict: CONSENSUS_WITH_NITS

## Decision

Ready for:
- writing-plans

Not authorized:
- code changes
- completion claim

## Blockers

None.

## Must-Preserve Nits

1. Keep owner decisions separate from implementation tasks.
2. Preserve abnormal-case terminal semantics.

## Side Effects

Formal project files modified:
- none
```

`turns/*` 和 `consensus.md` 可以使用轻量 YAML frontmatter。
默认流程里保持简短即可：`topic`、`agent`、`turn`、`state` 或 `verdict`、以及是否修改了正式文件。

## 安装

把 standalone skills 安装到项目仓库：

```sh
./install.sh /path/to/your/project
```

如果你已经在目标项目根目录：

```sh
./install.sh .
```

只安装 Claude Code skills：

```sh
./install.sh /path/to/your/project --claude-only
```

只安装 Codex skills：

```sh
./install.sh /path/to/your/project --codex-only
```

安装脚本会复制 skills 到：

- Claude Code：`.claude/skills/`
- Codex：`.agents/skills/`

从 v1 升级时，直接重新运行安装脚本即可。
它会覆盖当前 standalone skills，并清理旧版残留的 standalone `council-respond` 目录。

除非团队明确想保留本地讨论状态，否则建议在目标项目的 `.gitignore` 中加入：

```gitignore
.agent-council/
```

## 检查版本

安装或升级后，运行：

```text
/council-version
$council-version
```

使用 `--check` 对比当前安装版本和仓库最新版本：

```text
/council-version --check
$council-version --check
```

如果 `council-upgrade` 执行完成后，`council-help` 仍显示旧版本，
通常说明当前命令来自另一个安装位置或 plugin 缓存。
请在同一个工具里运行 `council-version` 确认当前实际生效的版本。

standalone 安装中，`council-upgrade` 默认只检查不修改。
需要更新时，请从当前项目或 home 安装位置再次执行 `council-upgrade --apply`。
如果 standalone 安装已经很脏，使用 `council-upgrade --apply --force` 删除
`claude-p` / `council-respond` 等废弃命令、重装当前完整 skill 集，并验证
`council-peer-p` 与 `council-claude-p` 都存在。只有当你明确想使用某个 branch、
tag 或 commit 时，才需要加 `--ref {git_ref}`。

`claude-p` 已废弃。新调用使用 `council-peer-p`；`council-claude-p` 作为兼容别名
保留。如果 `claude-p` 消失了但两个替代命令都没有出现，通常说明升级打到了另一个
standalone 位置，或者当前实际生效的是 plugin 缓存，需要重新安装/reload。

plugin 安装需要从 marketplace 重新安装 `agent-council` plugin，并 reload plugins 或重启工具。

## 卸载

预览 standalone 卸载目标：

```sh
./uninstall.sh /path/to/your/project
```

删除 standalone skills：

```sh
./uninstall.sh /path/to/your/project --apply
```

默认保留 `.agent-council/` 讨论状态。只有你也想删除本地 Council 历史时，才加
`--remove-state`。从已安装的 standalone skill 中可使用：

```text
/council-uninstall --check
/council-uninstall --apply
```

Codex plugin 安装使用：

```sh
codex plugin remove agent-council@agent-council-marketplace
```

Claude Code plugin 安装请在 plugin 管理器里移除 `agent-council`，然后 reload plugins。

## Claude Code

### 项目本地安装

使用上面的安装脚本。安装后在 Claude Code 中使用短命令：

```text
/council-help
/council
/council-version
/council-open -- 使用最近一个可见对话轮次作为给对方评审的交接内容。
/council-open retry-design -- 使用最近一个可见对话轮次作为给对方评审的交接内容。
/council-review retry-design -- 判断当前下一步是否合理。
/council-review retry-design CONSENSUS -- 如果只剩非阻塞问题，请收敛成共识。
/council-apply retry-design -- 将共识应用到相关文件。
/council-status retry-design
/council-status retry-design --doctor
/council-upgrade --check
/council-upgrade --apply
/council-upgrade --apply --force
/council-uninstall --check
```

### Claude Code Plugin

把本仓库作为 Claude Code marketplace 添加并安装 plugin：

```text
/plugin marketplace add bhswallow/agent-council
/plugin install agent-council@agent-council-marketplace
/reload-plugins
```

通过 plugin 安装后，Claude Code 会给 skill 加命名空间：

```text
/agent-council:council-help
/agent-council:council
/agent-council:council-version
/agent-council:council-open -- 使用最近一个可见对话轮次作为给对方评审的交接内容。
/agent-council:council-open retry-design -- 使用最近一个可见对话轮次作为给对方评审的交接内容。
/agent-council:council-review retry-design
/agent-council:council-apply retry-design
/agent-council:council-status retry-design
/agent-council:council-upgrade --check
/agent-council:council-uninstall --check
```

从旧版 plugin 升级时，如果 plugin 管理器里仍能看到 `council-respond`，
请先删除旧的 `agent-council` plugin，再重新安装并 reload。

## Codex

### 项目本地安装

使用上面的安装脚本。安装后在 Codex 中显式调用 skills：

```text
$council-help
$council
$council-version
$council-open -- 使用最近一个可见对话轮次作为给对方评审的交接内容。
$council-open retry-design -- 使用最近一个可见对话轮次作为给对方评审的交接内容。
$council-review retry-design -- 判断当前下一步是否合理。
$council-review retry-design CONSENSUS -- 如果只剩非阻塞问题，请收敛成共识。
$council-apply retry-design -- 将共识应用到相关文件。
$council-status retry-design
$council-status retry-design --doctor
$council-upgrade --check
$council-upgrade --apply
$council-upgrade --apply --force
$council-uninstall --check
```

### Codex Plugin

添加本仓库作为 Codex marketplace：

```sh
codex plugin marketplace add bhswallow/agent-council
```

然后打开 Codex，执行 `/plugins`，选择 Agent Council marketplace，安装 `agent-council` plugin。

安装后显式调用内置 skills：

```text
$council-help
$council
$council-version
$council-open -- 使用最近一个可见对话轮次作为给对方评审的交接内容。
$council-open retry-design -- 使用最近一个可见对话轮次作为给对方评审的交接内容。
$council-review retry-design
$council-apply retry-design
$council-status retry-design
$council-upgrade --check
$council-uninstall --check
```

从旧版 plugin 升级时，如果 `/plugins` 里仍列出 `council-respond`，
请先删除旧的 `agent-council` plugin，再重新安装并重启或 reload Codex。

## 基本流程

工具 A 开启话题：

```text
$council-open retry-plan -- 我调整了重试方案，请让对方判断下一步是否合理。
```

也可以让 Council 自动生成 topic-id：

```text
$council-open -- 我调整了重试方案，请让对方判断下一步是否合理。
```

工具 B 读取最新交接内容并评审：

```text
/council-review retry-plan -- 重点判断风险和是否可以继续推进。
```

工具 A 再读取工具 B 的意见并回应：

```text
$council-review retry-plan -- 只回应对方提出的阻塞问题。
```

准备停止讨论时：

```text
/council-review retry-plan CONSENSUS -- 如果只剩非阻塞问题，请写出最终共识。
```

然后选择一个工具应用共识：

```text
$council-apply retry-plan -- 根据共识修改 docs/plan.md。
```

## Topic Id

`topic-id` 是一次独立讨论的短名称。对 `council-open` 来说它可以省略。

手动提供时，建议使用小写 kebab-case。

推荐示例：

- `retry-design`
- `product-l1-gate`
- `checkout-design`
- `search-index-review`
- `retry-plan`
- `2026-06-03-1`

不要把同一个 topic-id 用在不相关的事情上。

## 原则

- 讨论重点应该是具体话题，而不是 Council 流程本身。
- 默认只读对方最新交接内容，不读完整历史。
- 正式项目文件和 Council 状态分开。
- 只有 `council-apply` 用于修改项目文件。
- 用 `council-version` 确认当前实际生效的安装版本。
- 当你想停止扩展讨论时，使用 `CONSENSUS`。

## 仓库结构

```text
.claude-plugin/marketplace.json          Claude Code marketplace 目录
.agents/plugins/marketplace.json         Codex marketplace 目录
plugins/agent-council/                   Plugin 包
plugins/agent-council/skills/            共享 skills
install.sh                               本地 standalone 安装脚本
uninstall.sh                             本地 standalone 卸载脚本，默认 dry-run，带 --apply 才删除
docs/                                    使用说明和协议说明
```

## 说明

这个工作流是手动的。它不会自动调用另一个工具。

它不能替代人的判断、测试或正常代码审查。
