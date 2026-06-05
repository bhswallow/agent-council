# Contributing

Thanks for helping improve Agent Council. The project is intentionally small:
it should remain a manual bridge for Claude Code and Codex handoffs, not a
hidden orchestration engine.

## Before Opening Work

- Check existing issues and recent changes.
- Keep changes topic-scoped.
- Preserve the manual invocation boundary.
- Do not add automatic Claude Code or Codex calls to the core Council loop.
- Keep `.agent-council/` local state out of formal project files unless the
  user explicitly applies or commits it.

## Development

Run validation before proposing a change:

```sh
./validate.sh
```

For install-script changes, also test a temporary project install:

```sh
tmpdir="$(mktemp -d)"
./install.sh "$tmpdir"
./uninstall.sh "$tmpdir"
./uninstall.sh "$tmpdir" --apply
rm -rf "$tmpdir"
```

## Pull Requests

Good pull requests usually include:

- the user problem or workflow gap;
- the changed commands, docs, or skill rules;
- validation results;
- any security or trust-boundary impact.

Avoid unrelated refactors in the same PR. If a change affects both English and
Chinese docs, update both.

## Community Standards

Be practical, specific, and respectful. Critique behavior and risk clearly,
especially around security or data loss, without making it personal.
