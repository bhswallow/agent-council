# Security Policy

Agent Council is a manual local handoff bridge. It is designed to keep trust
boundaries visible:

- It does not collect tokens.
- It does not upload code.
- It does not automatically call Claude Code, Codex, or remote services.
- It stores topic state locally under `.agent-council/`.
- `council-open`, `council-review`, and `council-status` write only Council
  state.
- `council-apply` is the explicit command that may modify formal project files.
- `council-peer-review` is an optional utility. It calls the peer CLI only when the
  user explicitly invokes it.

## Reporting

Please report suspected security issues privately if possible. If you do not
have a private contact path for the maintainers, open a GitHub issue with a
minimal description and avoid posting secrets, tokens, private repository
content, or exploit details.

Useful reports include:

- the Agent Council version;
- whether the install is standalone, Claude Code plugin, or Codex plugin;
- the exact command that caused concern;
- which files changed unexpectedly, if any;
- the smallest reproduction steps you can share safely.

## Supported Versions

Security fixes target the latest tagged release and the current `main` branch.
Older standalone installs should upgrade by reinstalling or by running
`council-upgrade --apply` from an explicitly trusted checkout.

## Local State

`.agent-council/` may contain user prompts, peer review notes, and consensus
records. Add it to project `.gitignore` unless your team intentionally wants to
commit that discussion state.
