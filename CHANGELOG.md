# Changelog

## 2.3.0

- Added lightweight guardrails: canonical lowercase agent ids, side effects summaries, and `council-status --doctor`.
- Added short consensus templates with must-preserve nits and forbidden actions.
- Added lightweight frontmatter guidance for turn records and consensus files.

## 2.2.0

- Defined stable Council status states and `status.md` schema.
- Required `council-review` responses to end with a `Next action`.
- Tightened `council-apply` so formal consensus is required unless the user explicitly applies latest.
- Added validation for invocation policies, version consistency, status docs, and deprecated aliases.

## 2.1.0

- Added `council-upgrade` to update standalone installs from the latest repository version.
- Documented plugin upgrade guidance in the upgrade skill.

## 2.0.3

- Added explicit v1 upgrade cleanup for stale `council-respond` standalone installs.
- Documented the safest v1-to-v2 upgrade path.

## 2.0.2

- Removed the deprecated `council-respond` compatibility alias.
- Use `council-review` for review, response, rebuttal, confirmation, and consensus.

## 2.0.1

- Show the Agent Council version in `council-help` output.

## 2.0.0

- Simplified Agent Council into a latest-turn bridge.
- Simplified `council-open` to `council-open <topic-id> [-- handoff note]`.
- Unified review and response around `council-review`.
- Kept `council-respond` as a compatibility alias.
- Removed artifact, stage, and brief arguments from the primary flow.
- Updated README and protocol docs in English and Chinese.

## 1.2.0

- Added separate English and Chinese README files.
- Added local install and marketplace install documentation.
- Added source brief support for chat-only context.
