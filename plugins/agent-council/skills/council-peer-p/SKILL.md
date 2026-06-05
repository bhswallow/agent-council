---
name: council-peer-p
description: Run the peer tool headlessly: Claude Code from Codex, or Codex from Claude Code.
disable-model-invocation: true
---

# Council Peer P

Arguments:
`[--help] [--diagnose] [-n[=N|all]|--rounds[=N|all]] [--full] [--topic {topic_id}] [--output {path}] [--output-format {format}] [--allowed-tools "{tools}"] [--codex-model {model}] [--codex-profile {profile}] [--codex-sandbox {mode}] "{prompt}"`

Examples:
- `$council-peer-p "Review docs/design.md for blockers."`
- `$council-peer-p`
- `$council-peer-p --diagnose`
- `$council-peer-p -n=3 "Review the recent plan for blockers."`
- `$council-peer-p --rounds=all --full "Summarize the visible conversation and call out risks."`
- `$council-peer-p --allowed-tools "Read,Grep,Glob,Bash(git diff *)" "Review current diff for rollback risk."`
- `/council-peer-p --codex-model gpt-5 "Review the latest plan for blockers."`
- `$council-peer-p --output-format json "Summarize the current repository risks."`
- `$council-peer-p --topic product-l1-gate "Review the latest Council handoff for blockers."`
- `$council-claude-p "Review docs/design.md for blockers."`

## Purpose

`council-peer-p` is the preferred neutral name for this optional utility skill.
`council-claude-p` is a backward-compatible historical alias.

The utility runs the peer tool headlessly:

- If running in Codex, call Claude Code through `claude -p`.
- If running in Claude Code, call Codex through `codex exec --sandbox read-only`.

Important boundary:

- The user-facing skill command is `council-peer-p` or `council-claude-p`.
- From Codex, the underlying subprocess is Claude Code's native `claude -p`.
- From Claude Code, the underlying subprocess is Codex CLI's
  `codex exec --sandbox read-only`.
- `claude -p` comes from Claude Code / Anthropic, not Codex or OpenAI.
- `codex exec` comes from Codex / OpenAI, not Claude Code or Anthropic.
- This skill requires the peer CLI to already be installed and available in
  `PATH`: `claude` when running from Codex, `codex` when running from Claude
  Code.
- Agent Council does not install Claude Code or Codex.
- This utility is not part of the Agent Council review loop.
- Do not treat its result as a Council consensus.
- The peer command receives only the prompt this skill sends to it. It does not
  independently see the current Codex chat, Claude Code chat, screenshots, or
  prior conversation unless this skill includes selected visible chat text in
  the prompt, the user includes context explicitly, or the user grants tools or
  sandbox access that let the peer read files.

## Invocation Boundary

Run this skill only when the user explicitly invokes `council-peer-p` or
`council-claude-p`.

Do not invoke it automatically from `council-open`, `council-review`,
`council-apply`, `council-status`, or any other Council command.

Do not automatically write `.agent-council/`.
Do not automatically modify formal project files.
Do not automatically trigger another Council round.
Do not automatically trigger `council-apply`.

## Prompt Handling

Parse the user input as the prompt for the peer headless command.

Whitespace-only input and punctuation-only input do not count as a prompt.

If the user passes `--help`, show short help and stop. Mention:

- usage: `$council-peer-p "{prompt}"`, `$council-peer-p`, or the historical
  alias `$council-claude-p`;
- shared flags: `--diagnose`, `--output`, `--topic`, `-n` / `--rounds`,
  `--full`;
- Claude-from-Codex flags: `--allowed-tools`, `--output-format`;
- Codex-from-Claude flags: `--codex-model`, `--codex-profile`,
  `--codex-sandbox`;
- from Codex, the local `claude` CLI must be installed and available in `PATH`;
- from Claude Code, the local `codex` CLI must be installed and available in
  `PATH`;
- if no prompt is provided, the skill uses selected recent visible conversation
  rounds as context and asks the peer for a focused one-shot review;
- no files or Council topics are written by default.

## Conversation Round Selection

A conversation round means one user message plus the immediately following
Codex or Claude Code assistant response. If the latest visible round has no
assistant response yet, treat it as an unfinished round and mark the assistant
response as missing.

Visible conversation context means user messages and Codex/Claude Code
assistant replies that are visible in the current chat transcript. It must not
include system/developer instructions, tool schemas, hidden chain-of-thought,
or other internal runtime context. If a tool result is not visible as ordinary
chat text, do not include it just because it exists in the model context.

Parse context selection flags before the quoted prompt:

- no `-n` / `--rounds`: select the latest 1 visible conversation round;
- bare `-n` or bare `--rounds`: select the latest 1 visible conversation round;
- `-n=1`, `-n 1`, `--rounds=1`, or `--rounds 1`: select the latest 1 round;
- `-n=10` or `--rounds=10`: select the latest 10 rounds;
- `-n=all` or `--rounds=all`: select all visible user/assistant rounds in the
  current chat window, not hidden runtime context.

Reject `0`, negative numbers, non-integers other than `all`, and values that
cannot be interpreted reliably. Ask the user to rerun with a valid value.

Without `--full`, summarize the selected visible rounds before sending them to
the peer. Keep the context compact and focused on decisions, evidence,
blockers, open questions, and requested review focus.

With `--full`, include the selected visible rounds as full source text in the
prompt sent to the peer. If the selected full text is too large for reliable
headless execution, tell the user to reduce `-n`, omit `--full`, paste or save
a narrower transcript, or reference a file.

`--diagnose` ignores `-n`, `--rounds`, `--full`, prompt text, and topic/output
save options. It only runs the diagnostic sequence.

If the user does not provide a substantive prompt, automatically build a prompt
from the selected visible conversation rounds available to the current agent.
Ignore:

- empty text;
- whitespace;
- punctuation-only text;
- command-only text such as `council-peer-p` or `council-claude-p` with no
  substantive content.

Prefer the latest selected substantive user request. If the latest user request
is only the `council-peer-p` or `council-claude-p` invocation, use the previous
substantive user request or the latest substantive assistant result that the
user appears to be asking the peer to review. Do not scan files or Council state just to find
context.

When building the fallback prompt, use the current conversation language when
it is clear. Keep the prompt compact and ask the peer for a useful review instead
of merely saying "summarize." A good default shape is:

```text
Review the following selected conversation context for blockers, missing
assumptions, risks, and whether it is reasonable to proceed. Be concise. Do not
modify files.

Context:
{selected_recent_conversation_rounds}
```

Adapt the wording to the user's language and apparent intent. For example, if
the recent message is about a POC training plan, ask the peer to review it for
blockers before POC training. Do not treat that example as a fixed template.

If the user provides a substantive prompt, treat the selected rounds as
`Context` and the explicit prompt as `Task`. If no useful selected context is
visible, send only the explicit prompt and say the context was explicit prompt
only.

If there is no substantive visible chat message or prompt available, show short
help and stop. Do not invent context.

If the user asks the peer to summarize "the above chat", "this conversation", or
"the previous messages", include only the relevant visible chat text you can
reliably select. If the needed transcript is not visible or is too large, ask
the user to paste the relevant text, save it to a file and reference that file,
or use a Council handoff topic.

## Host And Peer Detection

Detect the current host tool first:

- If running in Codex, use `codex` as the host and `claude` as the peer CLI.
- If running in Claude Code, use `claude` as the host and `codex` as the peer
  CLI.
- Determine the host from the current assistant/runtime, not from which CLI
  happens to exist in `PATH`.
- If both `claude` and `codex` are installed, still call the opposite tool for
  the current host.
- If the host cannot be determined reliably, stop and ask the user to run the
  neutral command from Codex or Claude Code. Do not guess and accidentally call
  the same tool.

Before running the peer, check whether the required local command exists.

From Codex:

```sh
command -v claude
```

From Claude Code:

```sh
command -v codex
```

If the peer CLI is not found, stop and tell the user:

- which peer command was missing;
- install or configure the peer CLI first;
- from Codex, the peer command is Claude Code's `claude`;
- from Claude Code, the peer command is Codex CLI's `codex`;
- Agent Council does not install Claude Code or Codex.

If the peer command exists, optionally run a cheap smoke check when debugging a
hang:

```sh
claude --version
codex --version
```

Do not treat a successful version check as proof that auth, network access, or
model access is working for `claude -p` or `codex exec`.

## Diagnose Mode

If the user passes `--diagnose`, do not run the normal review prompt. Run a
short read-only diagnostic sequence for the detected peer CLI and report each
step.

From Codex, diagnose Claude Code:

1. `command -v claude`
2. `claude --version`
3. a short ping prompt through `claude -p`, such as:

```sh
claude -p "Reply with exactly: council-claude-p-ok"
```

From Claude Code, diagnose Codex:

1. `command -v codex`
2. `codex --version`
3. a short ping prompt through `codex exec --sandbox read-only`, such as:

```sh
codex exec --sandbox read-only "Reply with exactly: council-peer-ok"
```

Use a shorter timeout for the ping prompt, such as 30 seconds.

Do not add `--allowedTools` in diagnose mode. Do not pass Codex write-capable
sandbox modes in diagnose mode. Do not write files. Do not write Council
topics. Do not modify project files.

Diagnose output should be concise:

```text
Council Peer P diagnose:
- host: codex | claude
- peer command: claude | codex
- peer path: {path_or_missing}
- peer version: {version_or_error}
- ping: passed | timed out | failed | no output
- likely issue: auth/login | network/model availability | CLI hang | unknown

Next step:
- ...
```

If the ping times out or returns no output, suggest running Claude Code
or Codex interactively once to confirm login/auth, then retrying:

```sh
claude
codex
```

Also suggest trying a direct shell ping outside the skill:

```sh
claude -p "Reply with exactly: council-claude-p-ok"
codex exec --sandbox read-only "Reply with exactly: council-peer-ok"
```

## Execution

If the peer CLI is available, construct and execute one headless prompt.

From Codex:

```sh
claude -p "{prompt}"
```

From Claude Code:

```sh
codex exec --sandbox read-only "{prompt}"
```

Treat the command as an argv-style command, not a shell pipeline. Do not use
`eval`. Pass every peer CLI value as a separate argv element. This includes the
prompt, Claude-specific `--allowed-tools` / `--output-format` values, and
Codex-specific `--model` / `--profile` / `--sandbox` values. `--output` and
`--topic` are skill-local save options; do not pass them to `claude -p` or
`codex exec`. If a shell must be used, quote every user-controlled value
safely, including local save paths before writing.

Default behavior:

- from Codex, do not add `--allowedTools`;
- from Claude Code, run `codex exec --sandbox read-only`;
- do not grant Bash, Write, Edit, or other tools automatically;
- do not write files;
- do not write `.agent-council/`;
- do not modify project files;
- return the peer output to the user.

Codex-specific option handling when running from Claude Code:

- `--codex-model {model}` maps to `codex exec --model {model}`;
- `--codex-profile {profile}` maps to `codex exec --profile {profile}`;
- `--codex-sandbox {mode}` maps to `codex exec --sandbox {mode}`;
- default `--codex-sandbox` is `read-only`;
- if `--codex-sandbox` is `workspace-write` or `danger-full-access`, stop and
  warn that this exceeds the default one-shot review utility. Continue only if
  the user explicitly confirms.

Claude-specific option handling when running from Codex:

- `--allowed-tools "{tools}"` maps to Claude Code's allowed-tools flag;
- `--output-format {format}` maps to Claude Code's output format flag.

If running from Claude Code, do not pass `--allowed-tools` or
`--output-format` to `codex exec`; explain that those are Claude Code-specific
flags and suggest `--codex-model`, `--codex-profile`, or `--codex-sandbox` if
needed.

Prompt construction:

- include a compact header that says whether context is summary or full;
- include the selected round range, such as `latest 1`, `latest 10`, or `all
  visible`;
- if `--full` is not used, include a concise summary of selected rounds;
- if `--full` is used, include the selected visible source text directly;
- include the explicit user prompt as `Task` when one was provided;
- if no explicit prompt was provided, ask the peer for a focused one-shot review.

Use a bounded timeout for the subprocess. Default timeout: 600 seconds (10 minutes).
If the user explicitly requests a longer run, use the requested limit and show
it in the response.

## Status Updates

Do not leave the user waiting silently while the peer headless command runs.

Before starting the subprocess, send a short status message:

```text
Council Peer P status: starting
- Skill command: council-peer-p | council-claude-p "{short_prompt_summary}"
- Host: codex | claude
- Peer command: claude -p | codex exec --sandbox read-only
- Underlying command: {argv_style_command_summary}
- Timeout: 600s
- Context: explicit prompt | selected visible conversation rounds
- Rounds: latest 1 | latest N | all visible
- Context mode: summary | full
- Output: chat only
```

If the result will be saved to a file or Council topic, include the destination
path in the starting status.

While the subprocess is running, provide progress updates at least every 15 to
30 seconds:

```text
Council Peer P status: running ({elapsed_seconds}s/{timeout_seconds}s)
- The peer command has not returned output yet.
- Still waiting for the headless process.
```

Use an execution mode that can be polled or streamed. If the available tool call
would block until completion, prefer starting an ongoing process/session and
polling it so the user gets status updates.

When the subprocess completes with output, send:

```text
Council Peer P status: completed ({elapsed_seconds}s)
```

When the subprocess times out or exits with no useful output, send:

```text
Council Peer P status: timed out ({elapsed_seconds}s/{timeout_seconds}s)
```

or:

```text
Council Peer P status: no output ({elapsed_seconds}s)
```

Then explain that no peer analysis result was produced.

If `claude -p` or `codex exec` times out or returns no output:

- stop the process;
- do not report a peer analysis result;
- say that the headless run timed out or returned no output;
- include the elapsed timeout;
- include whether the process exited, was killed by timeout, or returned a
  non-zero exit code if that information is available;
- include stderr or the last useful diagnostic line if available, but do not
  paste huge logs;
- suggest checking peer CLI login/auth, network access, model availability, or
  reducing the prompt;
- remind the user that this utility only sends the selected prompt/context,
  not an unlimited chat transcript;
- suggest `$council-peer-p --diagnose` or `$council-claude-p --diagnose` as
  the next check;
- report that no Council files and no formal project files were modified.

If the user explicitly passes `--allowed-tools "{tools}"`, pass the tools
through to Claude Code using the installed CLI's allowed-tools flag only when
running from Codex. Do not add extra tools beyond what the user requested.

If the requested tools include file-mutating or shell-capable tools such as
`Write`, `Edit`, `MultiEdit`, `Bash`, or any `Bash(...)` pattern, stop and warn
that this exceeds the default one-shot review utility. Continue only if the user
explicitly confirms that they want to grant those tools to Claude Code. Never
add those tools automatically.

If the user explicitly passes `--output-format {format}`, pass the output
format through to Claude Code only when running from Codex.

Do not turn the user's prompt into a complex shell command, pipe, or redirect
unless the user explicitly requested that shell behavior. If shell behavior is
requested, show the exact command before running it.

If the prompt asks the peer to write files or modify the project, warn that
this is beyond the default one-shot review utility and recommend using the
official interactive peer environment for file-changing work.

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
  and write only `.agent-council/active/{topic_id}/latest/council-peer-p.md`.

If the user explicitly asks to save the result to a Council topic, require an
explicit topic id:

```text
$council-peer-p --topic product-l1-gate "Review the latest handoff for blockers."
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
.agent-council/active/{topic_id}/latest/council-peer-p.md
```

If the user invoked the historical alias `council-claude-p`, keep the
compatibility save path instead:

```text
.agent-council/active/{topic_id}/latest/council-claude-p.md
```

When saving to a Council topic:

- create parent directories if needed;
- write only `latest/council-peer-p.md` for `council-peer-p`, or
  `latest/council-claude-p.md` for the historical alias;
- never update Council governance files such as `status.md`, `consensus.md`,
  `latest/for-peer.md`, `topic.md`, `index.md`, or `turns/` from this utility;
- state that this is a peer-headless external review result, not the same thing
  as an interactive Council review;
- do not declare `CONSENSUS`;
- do not trigger `council-apply`;
- do not trigger another Council round.

## Output Shape

Keep the user-facing response short:

```text
Peer headless result:
{result}

Side effects:
- Skill command: council-peer-p | council-claude-p "{short_prompt_summary}"
- Host: codex | claude
- Peer command: claude -p | codex exec --sandbox read-only
- Underlying command: {peer_command_summary}
- Timeout: 600s default unless explicitly overridden
- Final status: completed | timed out | no output
- Council files modified: none
- Formal project files modified: none
```

If saved to a file, include the exact path under `Side effects`.

If saved to a Council topic, include:

```text
Saved external peer-headless review:
.agent-council/active/{topic_id}/latest/council-peer-p.md

This is not a Council consensus and not an interactive Council review.
```
