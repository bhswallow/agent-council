# 协议说明

Agent Council 的中间状态保存在 `.agent-council/active/<topic-id>/`。

默认读取：

- `manifest.md`
- `focus.md`
- 存在时读取 `source-brief.md`
- `context-pack.md`
- 对方最新一轮输出
- 用户当前轮要求
- `positions/*.md`
- `decisions.md`
- `open-questions.md`
- 存在时读取 `consensus.md`
- 存在时读取绑定的正式 artifact

默认不读取：

- 其他 topic
- `archive/`
- 全量旧轮次历史
- 无关项目文件

只有 `council-apply` 应该修改正式 artifact。
