# 使用说明

Agent Council 使用 topic-id 隔离不同讨论。topic-id 应该简短稳定，例如 `retry-design` 或 `checkout-plan`。

## 命令

- `council-open`：开启讨论，并绑定 artifact 或 source brief。
- `council-review`：评审当前 topic，不修改正式 artifact。
- `council-respond`：回应对方评审并更新当前立场。
- `council-apply`：把已接受的决策写入正式 artifact。
- `council-status`：查看、压缩、归档、关闭或放弃 topic。
- `council-help`：查看帮助。

## 附加说明

使用 `--` 添加当前轮要求：

```text
/council-review retry-design -- 请用架构师和高级开发工程师两个视角 review。
```

如果某条说明需要成为 topic 长期规则，使用 `sticky:`：

```text
/council-open retry-design docs/design.md -- sticky: 这是进入计划阶段前的设计评审。
```

## 收敛

如果你希望当前工具停止扩展讨论，并基于现有信息收敛，可以加入 `CONSENSUS`：

```text
/council-respond retry-design CONSENSUS -- 如果没有 blocker，请收敛。
```

如果双方已经同意，就是自然共识。如果仍有分歧但你要求停止讨论，会记录为用户强制收敛。
