# Usage

Agent Council uses topic ids to keep discussions separate. A topic should be short and stable, for example `retry-design` or `checkout-plan`.

## Commands

- `council-open`: start a topic and bind it to an artifact or source brief.
- `council-review`: review the topic without changing the formal artifact.
- `council-respond`: answer the peer review and update the current position.
- `council-apply`: apply accepted decisions to the formal artifact.
- `council-status`: inspect, compact, archive, close, or abandon a topic.
- `council-help`: show help.

## Extra instructions

Use `--` for per-turn instructions:

```text
/council-review retry-design -- Use architect and senior engineer perspectives.
```

Use `sticky:` when an instruction should remain part of the topic focus:

```text
/council-open retry-design docs/design.md -- sticky: Review this as a design-stage artifact before planning.
```

## Consensus

Add `CONSENSUS` when you want the current agent to stop expanding the discussion and converge based on the current information:

```text
/council-respond retry-design CONSENSUS -- Converge if no blockers remain.
```

If both agents already agree, the topic is natural consensus. If disagreement remains and you force convergence, the topic records user-forced consensus.
