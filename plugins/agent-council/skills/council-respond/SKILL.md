---
name: council-respond
description: Compatibility alias for council-review.
---

# Council Respond

`council-respond` is kept for backward compatibility.

Use the same behavior as `council-review`:

- read the peer's latest handoff for the topic;
- review, respond, rebut, confirm, or converge;
- write the current agent's latest reply back to the topic;
- do not modify formal project files.

Arguments:
`<topic-id> [CONSENSUS] [-- review instruction]`

Recommended replacement:
`council-review <topic-id> [CONSENSUS] [-- review instruction]`

When this skill is invoked, execute the `council-review` behavior and mention once that `council-respond` is a compatibility alias.
