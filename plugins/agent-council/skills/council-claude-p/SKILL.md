---
name: council-claude-p
description: Run Claude Code headless `claude -p` as an optional one-shot utility.
disable-model-invocation: true
---

# Council Claude P

Arguments:
`[--help] [--topic {topic_id}] [--output {path}] [--output-format {format}] [--allowed-tools "{tools}"] "{prompt}"`

Examples:
- `$council-claude-p "Review docs/design.md for blockers."`
- `$council-claude-p`
- `$council-claude-p --allowed-tools "Read,Grep,Glob,Bash(git diff *)" "Review current diff for rollback risk."`
- `$council-claude-p --output-format json "Summarize the current repository risks."`
- `$council-claude-p --topic product-l1-gate "Review the latest Council handoff for blockers."`

## Purpose

`council-claude-p` is an optional utility skill. It wraps the native Claude Code
headless command `claude -p`.

Important boundary:

- The user-facing skill command is `council-claude-p`.
- The underlying subprocess is Claude Code's native `claude -p`.
- `claude -p` comes from Claude Code / Anthropic, not Codex or OpenAI.
- This skill does not require Codex CLI.
- This skill requires Claude Code CLI to already be installed and `claude` to
  be available in `PATH`.
- Agent Council does not install Claude Code.
- This utility is not part of the Agent Council review loop.
- Do not treat its result as a Council consensus.
- `claude -p` receives only the prompt this skill sends to it. It does not
  independently see the current Codex chat, Claude Code chat, screenshots, or
  prior conversation unless this skill includes selected visible chat text in
  the prompt, the user includes context explicitly, or the user grants tools
  that let Claude read files.

## Invocation Boundary

Run this skill only when the user explicitly invokes `council-claude-p`.

Do not invoke it automatically from `council-open`, `council-review`,
`council-apply`, `council-status`, or any other Council command.

Do not automatically write `.agent-council/`.
Do not automatically modify formal project files.
Do not automatically trigger another Council round.
Do not automatically trigger `council-apply`.

## Prompt Handling

Parse the user input as the prompt for `claude -p`.

Whitespace-only input and punctuation-only input do not count as a prompt.

If the user passes `--help`, show short help and stop. Mention:

- usage: `$council-claude-p "{prompt}"` or `$council-claude-p`;
- optional flags: `--allowed-tools`, `--output-format`, `--output`, `--topic`;
- the local `claude` CLI must be installed and available in `PATH`;
- if no prompt is provided, the skill uses the most recent substantive visible
  chat message as context and asks Claude for a focused one-shot review;
- no files or Council topics are written by default.

If the user does not provide a substantive prompt, automatically build a prompt
from the most recent substantive visible chat message available to the current
agent. Ignore:

- empty text;
- whitespace;
- punctuation-only text;
- command-only text such as `council-claude-p` with no substantive content.

Prefer the latest substantive user request. If the latest user request is only
the `council-claude-p` invocation, use the previous substantive user request or
the latest substantive assistant result that the user appears to be asking
Claude to review. Do not scan files or Council state just to find context.

When building the fallback prompt, use the current conversation language when
it is clear. Keep the prompt compact and ask Claude for a useful review instead
of merely saying "summarize." A good default shape is:

```text
Review the following latest conversation item for blockers, missing assumptions,
risks, and whether it is reasonable to proceed. Be concise. Do not modify files.

Context:
{recent_substantive_chat_message}
```

Adapt the wording to the user's language and apparent intent. For example, if
the recent message is about a POC training plan, ask Claude to review it for
blockers before POC training. Do not treat that example as a fixed template.

If there is no substantive visible chat message available, show short help and
stop. Do not invent context.

If the user asks Claude to summarize "the above chat", "this conversation", or
"the previous messages", include only the relevant visible chat text you can
reliably select. If the needed transcript is not visible or is too large, ask
the user to paste the relevant text, save it to a file and reference that file,
or use a Council handoff topic.

## CLI Availability Check

Before running Claude, check whether the local command exists:

```sh
command -v claude
```

If it is not found, stop and tell the user:

- the current system did not find the `claude` command;
- install or configure Claude Code CLI first;
- this command comes from Claude Code, not Codex;
- Agent Council does not install Claude Code.

If `claude` exists, optionally run a cheap smoke check when debugging a hang:

```sh
claude --version
```

Do not treat a successful version check as proof that auth, network access, or
model access is working for `claude -p`.

## Execution

If `claude` is available, construct and execute one headless prompt:

```sh
claude -p "{prompt}"
```

Treat the command as an argv-style command, not a shell pipeline. Do not use
`eval`. Pass every user-controlled value as a separate argv element. This
includes the prompt, `--allowed-tools`, `--output-format`, `--output`, and
`--topic` values. If a shell must be used, quote every user-controlled value
safely.

Default behavior:

- do not add `--allowedTools`;
- do not grant Bash, Write, Edit, or other tools automatically;
- do not write files;
- do not write `.agent-council/`;
- do not modify project files;
- return the Claude output to the user.

Use a bounded timeout for the subprocess. Default timeout: 120 seconds.
If the user explicitly requests a longer run, use the requested limit and show
it in the response.

## Status Updates

Do not leave the user waiting silently while `claude -p` runs.

Before starting the subprocess, send a short status message:

```text
Council Claude P status: starting
- Skill command: council-claude-p "{short_prompt_summary}"
- Underlying command: claude -p "{short_prompt_summary}"
- Timeout: 120s
- Context: explicit prompt | fallback from recent visible chat
- Output: chat only
```

If the result will be saved to a file or Council topic, include the destination
path in the starting status.

While the subprocess is running, provide progress updates at least every 15 to
30 seconds:

```text
Council Claude P status: running ({elapsed_seconds}s/{timeout_seconds}s)
- Claude has not returned output yet.
- Still waiting for the headless process.
```

Use an execution mode that can be polled or streamed. If the available tool call
would block until completion, prefer starting an ongoing process/session and
polling it so the user gets status updates.

When the subprocess completes with output, send:

```text
Council Claude P status: completed ({elapsed_seconds}s)
```

When the subprocess times out or exits with no useful output, send:

```text
Council Claude P status: timed out ({elapsed_seconds}s/{timeout_seconds}s)
```

or:

```text
Council Claude P status: no output ({elapsed_seconds}s)
```

Then explain that no Claude analysis result was produced.

If `claude -p` times out or returns no output:

- stop the process;
- do not report a Claude analysis result;
- say that the headless run timed out or returned no output;
- include the elapsed timeout;
- suggest checking Claude Code login/auth, network access, model availability,
  or reducing the prompt;
- remind the user that `council-claude-p` only sends the selected prompt/context,
  not an unlimited chat transcript;
- report that no Council files and no formal project files were modified.

If the user explicitly passes `--allowed-tools "{tools}"`, pass the tools
through to Claude Code using the installed CLI's allowed-tools flag. Do not add
extra tools beyond what the user requested.

If the requested tools include file-mutating or shell-capable tools such as
`Write`, `Edit`, `MultiEdit`, `Bash`, or any `Bash(...)` pattern, stop and warn
that this exceeds the default one-shot review utility. Continue only if the user
explicitly confirms that they want to grant those tools to Claude Code. Never
add those tools automatically.

If the user explicitly passes `--output-format {format}`, pass the output
format through to Claude Code.

Do not turn the user's prompt into a complex shell command, pipe, or redirect
unless the user explicitly requested that shell behavior. If shell behavior is
requested, show the exact command before running it.

If the prompt asks Claude to write files or modify the project, warn that this
is beyond the default one-shot review utility and recommend using the official
interactive Claude Code environment for file-changing work.

## Saving Results

By default, do not save the result.

If the user explicitly asks to save the result to a file:

- save only to the requested path;
- clearly report the save path;
- do not write any other files.
- reject paths that contain `..`, are empty, or would resolve outside the
  current workspace unless the user explicitly gives an absolute external path
  and confirms it.
- do not write `.agent-council/` paths through `--output`;
- if the user wants to save under a Council topic, require `--topic {topic_id}`
  and write only `.agent-council/active/{topic_id}/latest/council-claude-p.md`.

If the user explicitly asks to save the result to a Council topic, require an
explicit topic id:

```text
$council-claude-p --topic product-l1-gate "Review the latest Codex handoff for blockers."
```

Validate the topic id before writing:

- allowed characters: lowercase letters, numbers, and hyphens;
- must match `{topic_id}` shape such as `product-l1-gate`, `checkout-review`,
  or `retry-plan`;
- reject empty values;
- reject `/`, `\`, `.`, `..`, spaces, shell metacharacters, and absolute paths;
- do not normalize a rejected value into a different topic id without telling
  the user.

Save the result to:

```text
.agent-council/active/{topic_id}/latest/council-claude-p.md
```

When saving to a Council topic:

- create parent directories if needed;
- write only `latest/council-claude-p.md`;
- never update Council governance files such as `status.md`, `consensus.md`,
  `latest/for-peer.md`, `topic.md`, `index.md`, or `turns/` from this utility;
- state that this is a `council-claude-p` external review result, not the same thing as
  Claude Code interactive Council review;
- do not declare `CONSENSUS`;
- do not trigger `council-apply`;
- do not trigger another Council round.

## Output Shape

Keep the user-facing response short:

```text
Claude Code headless result:
{result}

Side effects:
- Skill command: council-claude-p "{short_prompt_summary}"
- Underlying command: claude -p "{short_prompt_summary}"
- Timeout: 120s default unless explicitly overridden
- Final status: completed | timed out | no output
- Council files modified: none
- Formal project files modified: none
```

If saved to a file, include the exact path under `Side effects`.

If saved to a Council topic, include:

```text
Saved external council-claude-p review:
.agent-council/active/{topic_id}/latest/council-claude-p.md

This is not a Council consensus and not an interactive Claude Code Council review.
```
