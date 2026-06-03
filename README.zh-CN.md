# Agent Council

当前版本：2.1.0

Agent Council 是一个小型工作流包，适合在同一个仓库中同时使用 Claude Code 和 Codex 的场景。

它提供一个轻量、手动的沟通桥梁。一个工具可以写出方案、计划、评审或下一步建议；另一个工具可以直接读取最新交接内容进行评审，而不需要拥有原始聊天上下文。

Agent Council 的目标是保持简单：

- `council-open` 开启一个话题，并记录当前交接内容。
- `council-review` 读取对方最新交接内容并给出评审或回应。
- `council-apply` 是唯一应该修改项目正式文件的动作。
- `council-status` 查看当前状态。
- `council-help` 查看帮助。
- `council-upgrade` 更新 standalone 安装。

`council-respond` 已在 v2.0.2 移除。请统一使用 `council-review` 完成评审、回应、反驳、确认和收敛。安装脚本会清理旧版残留的 standalone `council-respond`。

## 解决什么问题

Claude Code 和 Codex 不共享同一个聊天窗口。工作在两个工具之间切换时，最近一次结论、理由或下一步建议很容易丢失。

Agent Council 会把最新交接内容写入 `.agent-council/active/<topic-id>/`。另一个工具只需要读取这个 topic 下的最新内容，就可以继续评审和回应。

正式项目文件保持干净。`.agent-council/` 只作为沟通桥梁。

## 工作方式

一个 topic 是一次独立讨论，例如：

    .agent-council/active/retry-design/

一个 topic 通常包含：

- `topic.md`：话题说明和初始交接内容。
- `latest/codex.md`：Codex 给 Claude Code 的最新内容。
- `latest/claude.md`：Claude Code 给 Codex 的最新内容。
- `latest/for-peer.md`：当前应由对方读取的交接内容。
- `turns/`：最近轮次记录，方便追溯。
- `consensus.md`：最终共识。
- `status.md`：当前状态。

默认只读取当前 topic 和对方最新内容。除非你明确要求，不应该扫描全部历史。

## 本地安装

把 standalone skills 安装到项目仓库：

    ./install.sh /path/to/your/project

如果你已经在目标项目根目录：

    ./install.sh .

只安装 Claude Code skills：

    ./install.sh /path/to/your/project --claude-only

只安装 Codex skills：

    ./install.sh /path/to/your/project --codex-only

安装脚本会复制 skills 到：

- Claude Code：`.claude/skills/`
- Codex：`.agents/skills/`

从 v1 升级时，直接重新运行安装脚本即可。它会覆盖当前 skills，并清理 `.claude/skills/` 和 `.agents/skills/` 下旧版残留的 standalone `council-respond` 目录。

安装到 v2.1.0 之后，standalone 用户后续可以用升级命令：

    /council-upgrade
    $council-upgrade

除非团队明确想保留本地讨论状态，否则建议在目标项目的 `.gitignore` 中加入：

    .agent-council/

## Claude Code 安装

### 方式 A：项目本地安装

使用上面的本地安装脚本。安装后在 Claude Code 中使用短命令：

    /council-help
    /council-open retry-design -- 使用最近一次回复作为给对方评审的交接内容。
    /council-review retry-design -- 判断当前下一步是否合理。
    /council-review retry-design CONSENSUS -- 如果只剩非阻塞问题，请收敛成共识。
    /council-apply retry-design -- 将共识应用到相关文件。
    /council-status retry-design
    /council-upgrade --check

### 方式 B：作为 Claude Code plugin 安装

把本仓库作为 Claude Code marketplace 添加并安装 plugin：

    /plugin marketplace add bhswallow/agent-council
    /plugin install agent-council@agent-council-marketplace
    /reload-plugins

从旧版 plugin 升级时，如果 plugin 管理器里仍能看到 `council-respond`，请先卸载旧的 `agent-council` plugin，再重新安装并 reload。

通过 plugin 安装后，Claude Code 会给 skill 加命名空间：

    /agent-council:council-help
    /agent-council:council-open retry-design -- 使用最近一次回复作为给对方评审的交接内容。
    /agent-council:council-review retry-design
    /agent-council:council-apply retry-design
    /agent-council:council-status retry-design
    /agent-council:council-upgrade --check

## Codex 安装

### 方式 A：项目本地安装

使用上面的本地安装脚本。安装后在 Codex 中显式调用 skills：

    $council-help
    $council-open retry-design -- 使用最近一次回复作为给对方评审的交接内容。
    $council-review retry-design -- 判断当前下一步是否合理。
    $council-review retry-design CONSENSUS -- 如果只剩非阻塞问题，请收敛成共识。
    $council-apply retry-design -- 将共识应用到相关文件。
    $council-status retry-design
    $council-upgrade --check

### 方式 B：作为 Codex plugin 安装

添加本仓库作为 Codex marketplace：

    codex plugin marketplace add bhswallow/agent-council

然后打开 Codex，执行 `/plugins`，选择 Agent Council marketplace，安装 `agent-council` plugin。

从旧版 plugin 升级时，如果 `/plugins` 里仍列出 `council-respond`，请先删除旧的 `agent-council` plugin，再从 marketplace 重新安装。

安装后显式调用内置 skills：

    $council-help
    $council-open retry-design -- 使用最近一次回复作为给对方评审的交接内容。
    $council-review retry-design
    $council-apply retry-design
    $council-status retry-design
    $council-upgrade --check

## 基本流程

工具 A 开启话题：

    $council-open retry-design -- 我调整了重试方案，请让对方判断下一步是否合理。

工具 B 读取最新交接内容并评审：

    /council-review retry-design -- 重点判断风险和是否可以继续推进。

工具 A 再读取工具 B 的意见并回应：

    $council-review retry-design -- 只回应对方提出的阻塞问题。

准备停止讨论时：

    /council-review retry-design CONSENSUS -- 如果只剩非阻塞问题，请写出最终共识。

然后选择一个工具应用共识：

    $council-apply retry-design -- 根据共识修改 docs/design.md。

## topic-id

`topic-id` 是一次独立讨论的短名称。建议使用小写 kebab-case。

推荐示例：

- `retry-design`
- `checkout-plan`
- `search-index-review`

不要把同一个 topic-id 用在不相关的事情上。

## 原则

- 讨论重点应该是具体话题，而不是 Council 流程本身。
- 默认只读对方最新交接内容，不读完整历史。
- 正式项目文件和 Council 状态分开。
- 只有 `council-apply` 用于修改项目文件。
- 当你想停止扩展讨论时，使用 `CONSENSUS`。

## 仓库结构

    .claude-plugin/marketplace.json          Claude Code marketplace 目录
    .agents/plugins/marketplace.json         Codex marketplace 目录
    plugins/agent-council/                   Plugin 包
    plugins/agent-council/skills/            共享 skills
    install.sh                               本地 standalone 安装脚本
    uninstall.sh                             本地 standalone 卸载脚本
    docs/                                    使用说明和协议说明

## 说明

这个工作流是手动的。它不会自动调用另一个工具。

它不能替代人的判断、测试或正常代码审查。
