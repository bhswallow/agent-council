# Agent Council

Agent Council 是一组用于 Claude Code 和 Codex 的协作评审 skills。

它适合这样的工作方式：一个工具先起草设计、计划、source brief 或代码 diff；另一个工具进行评审；双方可以多轮回应；最后由你指定某一方把共识写回正式产物。整个过程由你手动推进，不会自动无限互相调用。

English documentation: [README.md](README.md)

## 解决什么问题

Claude Code 和 Codex 不会自动共享同一个聊天上下文。一个工具里已经讨论清楚的需求、约束和假设，切换到另一个工具时往往需要手动复制，或者容易遗漏。

Agent Council 的做法是：把跨工具交接所需的最小上下文写入 `.agent-council/`，并按 topic-id 隔离。正式文档仍然保持干净；讨论记录、双方立场、未决问题、决策表和共识记录都放在 Council 工作区。

## 基本原理

每个讨论话题对应一个目录，例如：

`.agent-council/active/retry-design/`

这个目录记录：

- 当前评审的 artifact；
- 当前讨论范围；
- Claude Code 和 Codex 的最新立场；
- 未解决问题；
- 已接受、已拒绝、已延期的决策；
- 如果上下文还只在聊天里，则记录 `source-brief.md`；
- 最终共识或用户强制收敛结果。

只有 `council-apply` 应该修改正式 artifact。`council-open`、`council-review`、`council-respond`、`council-status` 只写 Council 状态文件。

## 包含的 skills

- `council-open`
- `council-review`
- `council-respond`
- `council-apply`
- `council-status`
- `council-help`

## 本地安装

克隆仓库后，把 standalone skills 安装到目标项目：

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

除非你明确想提交讨论状态，否则建议在目标项目的 `.gitignore` 中加入：

```text
.agent-council/
```

## Claude Code 安装

### 方式 A：项目内 standalone 安装

使用上面的本地安装方式。安装后在 Claude Code 中使用短命令：

```text
/council-help
/council-open retry-design docs/design.md -- 这是结构化工作流中的 design 阶段。
/council-review retry-design -- 检查这份设计是否可以进入计划阶段。
/council-respond retry-design
/council-apply retry-design
/council-status retry-design
```

### 方式 B：作为 Claude Code plugin 安装

把这个仓库作为 Claude Code marketplace 添加并安装 plugin：

```text
/plugin marketplace add OWNER/REPO
/plugin install agent-council@agent-council-marketplace
/reload-plugins
```

把 `OWNER/REPO` 替换成实际托管该包的仓库位置。

通过 plugin 安装后，Claude Code 会给 skill 加命名空间：

```text
/agent-council:council-help
/agent-council:council-open retry-design docs/design.md -- 这是结构化工作流中的 design 阶段。
/agent-council:council-review retry-design
/agent-council:council-respond retry-design
/agent-council:council-apply retry-design
/agent-council:council-status retry-design
```

## Codex 安装

### 方式 A：项目内 standalone 安装

使用上面的本地安装方式。安装后在 Codex 中显式调用 skills：

```text
$council-help
$council-open retry-design docs/design.md -- 这是结构化工作流中的 design 阶段。
$council-review retry-design -- 检查这份设计是否可以进入计划阶段。
$council-respond retry-design
$council-apply retry-design
$council-status retry-design
```

### 方式 B：作为 Codex plugin 安装

添加这个仓库作为 Codex marketplace：

```sh
codex plugin marketplace add OWNER/REPO
```

然后启动 Codex，运行 `/plugins`，在 Agent Council marketplace 下安装 `agent-council`。

安装后使用：

```text
$council-help
$council-open retry-design docs/design.md -- 这是结构化工作流中的 design 阶段。
$council-review retry-design
$council-respond retry-design
$council-apply retry-design
$council-status retry-design
```

## Source brief 模式

当有价值的上下文还停留在当前聊天里，尚未形成设计文档或计划文档时，使用 source brief 模式。

在 Claude Code 中：

```text
/council-open checkout-design brief docs/design.md design -- 请把当前头脑风暴内容压缩成 source-brief.md，先不要写正式 design。
```

在 Codex 中：

```text
$council-open checkout-design brief docs/design.md design -- 请把当前头脑风暴内容压缩成 source-brief.md，先不要写正式 design。
```

另一个工具随后可以评审这份 brief：

```text
/council-review checkout-design -- 检查 source brief 是否足以开始写 design。
```

## 常见流程

1. 工具 A 起草 artifact，或者把聊天上下文总结成 source brief。
2. 工具 A 执行 `council-open`。
3. 工具 B 执行 `council-review`。
4. 工具 A 执行 `council-respond`。
5. 只在有价值时继续 review/respond。
6. 想停止扩展讨论时，可以使用 `CONSENSUS`。
7. 你指定某一方执行 `council-apply`。
8. 如果正式 artifact 变化较大，再让另一方最终复审一次。

示例：

```text
$council-open retry-design docs/design.md -- 这份设计需要先确认，再进入计划阶段。
/council-review retry-design -- 请用架构师和高级开发工程师两个视角 review。
$council-respond retry-design -- 只回应 blocker 和 major concerns。
/council-respond retry-design CONSENSUS -- 如果只剩非阻塞问题，请收敛。
$council-apply retry-design -- 只应用已接受的决策。
```

## topic-id 怎么取

topic-id 是一个短名字，用来隔离不同讨论。建议使用小写 kebab-case。

推荐：

- `retry-design`
- `checkout-plan`
- `search-index-review`

不要把不同需求复用成同一个 topic-id。

## 仓库结构

```text
.claude-plugin/marketplace.json          Claude Code marketplace catalog
.agents/plugins/marketplace.json         Codex marketplace catalog
plugins/agent-council/                   Plugin package
plugins/agent-council/skills/            Shared skills
install.sh                               本地 standalone 安装脚本
uninstall.sh                             本地 standalone 卸载脚本
docs/                                    使用和协议说明
```

## 注意事项

- 这个流程是手动推进的，不会自动调用另一个工具。
- 它不能替代测试、人工判断和代码审查。
- 除非团队明确需要保存讨论记录，否则建议不要提交 `.agent-council/`。
