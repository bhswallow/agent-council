# Release And Discovery Checklist

Use this when preparing a public release, plugin-directory submission, or
community announcement.

## Local Release Readiness

- Run `./validate.sh`.
- Confirm `VERSION`, README files, plugin manifests, and marketplace catalogs
  use the same version.
- Reinstall into a temporary project and confirm standalone skills appear under
  `.claude/skills/` and `.agents/skills/`.
- Confirm old `council-respond` and `claude-p` standalone directories are not
  left behind after upgrade/uninstall tests.
- Review `SECURITY.md` and keep the trust-boundary language current.
- Create a stable tag such as `v2.10.0`.

## Demo

Recommended title:

```text
Claude Code and Codex can hand off without copy-paste.
```

Recommended 60 second path:

```text
$council-open checkout-design -- Please ask Claude Code to review this latest design decision.
/council-review checkout-design -- Review only blockers.
$council-review checkout-design CONSENSUS -- If no blockers remain, converge.
```

Show the resulting file:

```text
.agent-council/active/checkout-design/consensus.md
```

## GitHub Topics

Suggested topics:

```text
claude-code
codex
codex-plugin
claude-plugin
ai-coding
ai-agents
developer-tools
workflow
multi-agent
agent-workflow
skills
plugin-marketplace
```

## Claude Plugin Directory Submission

Prepare:

- stable tag;
- concise README first screen;
- demo GIF or short video;
- `validate.sh` result;
- `SECURITY.md`;
- issue templates and PR template;
- compatibility notes for Claude Code plugin install.

Positioning:

```text
Manual recent-round bridge for Claude Code + Codex users.
```

Avoid framing it as automatic orchestration or as a replacement for official
tools.

## Codex Marketplace And Community

Confirm:

- `.agents/plugins/marketplace.json` points to `./plugins/agent-council`;
- `plugins/agent-council/.codex-plugin/plugin.json` is current;
- every skill has `agents/openai.yaml`;
- `allow_implicit_invocation: false` remains consistent;
- README install path fits within three steps.

Community post title:

```text
Agent Council: a manual recent-round bridge for Claude Code + Codex workflows
```

Keep the post specific: handoff, consensus, topic isolation, and user control.

## Article Outline

Suggested title:

```text
How I use Claude Code and Codex together without copy-pasting context
```

Structure:

- problem: Claude Code and Codex do not share chat context;
- failed approaches: automatic loops, every-task gates, long copied prompts;
- solution: a manual recent-round bridge;
- boundaries: no automatic calls, no hidden execution, no formal file changes
  until apply;
- demo: three commands and the consensus file;
- when not to use it: ordinary low-risk tasks.
