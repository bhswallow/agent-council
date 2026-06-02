---
name: council-help
description: Show help for the Agent Council workflow in English or Chinese.
---

# Council Help

Arguments:
`[zh|en] [skill-name]`

Examples:
- `/council-help`
- `$council-help zh`
- `/council-help en council-review`

This skill is read-only. Do not write `.agent-council/` files and do not modify formal artifacts.

## Output policy

If the user asks in Chinese or passes `zh`, answer in Chinese. If the user passes `en`, answer in English. Keep help concise and practical.

## Chinese help content

Agent Council 用来让 Claude Code 和 Codex 围绕同一个产物进行手动、多轮、可追踪的评审和回应。

解决的问题：
- 不再复制粘贴长上下文。
- 正式文档只保存最终结论。
- 讨论记录放在 `.agent-council/`，按 topic 隔离。
- 你决定是否继续下一轮、谁修改正式产物、何时进入下一阶段。

命令：
- `council-open <topic-id> <artifact> [-- 说明]`
- `council-open <topic-id> brief <target-artifact> [stage] -- 从当前聊天总结 source brief`
- `council-review <topic-id> [CONSENSUS] [-- 本轮要求]`
- `council-respond <topic-id> [CONSENSUS] [-- 本轮要求]`
- `council-apply <topic-id> [-- 应用要求]`
- `council-status [topic-id|all] [compact|archive|abandon|close]`
- `council-help [zh|en] [skill-name]`

常用示例：
- `$council-open retry-design docs/design.md -- 这是结构化设计流程中的 design 阶段。`
- `/council-review retry-design -- 请用架构师和高级开发工程师两个视角 review。`
- `$council-respond retry-design -- 只回应 blocker 和 major concerns。`
- `/council-respond retry-design CONSENSUS -- 如果只剩非阻塞问题，请收敛。`
- `$council-apply retry-design -- 只应用 consensus 中已接受的结论。`

规则：review 和 respond 不改正式文件。只有 apply 可以改正式 artifact。默认只读当前 topic，不读其他 topic，不递归读取 archive。

## English help content

Agent Council lets Claude Code and Codex manually review, respond, converge, and apply decisions around the same artifact.

It solves:
- less context copying between tools;
- cleaner design and plan documents;
- isolated topic state under `.agent-council/`;
- user-controlled review rounds and apply ownership.

Commands:
- `council-open <topic-id> <artifact> [-- note]`
- `council-open <topic-id> brief <target-artifact> [stage] -- summarize current chat into a source brief`
- `council-review <topic-id> [CONSENSUS] [-- turn instruction]`
- `council-respond <topic-id> [CONSENSUS] [-- turn instruction]`
- `council-apply <topic-id> [-- apply instruction]`
- `council-status [topic-id|all] [compact|archive|abandon|close]`
- `council-help [zh|en] [skill-name]`

Rule of thumb: review and respond write only Council files. Apply is the only Council action that may change the formal artifact.
