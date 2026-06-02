# Protocol

Agent Council stores intermediate state under `.agent-council/active/<topic-id>/`.

Default read set:

- `manifest.md`
- `focus.md`
- `source-brief.md` when present
- `context-pack.md`
- latest peer turn
- latest user request
- `positions/*.md`
- `decisions.md`
- `open-questions.md`
- `consensus.md` when present
- the bound artifact when it exists

Default non-read set:

- other topics
- `archive/`
- full old turn history
- unrelated project files

Only `council-apply` should change formal artifacts.
