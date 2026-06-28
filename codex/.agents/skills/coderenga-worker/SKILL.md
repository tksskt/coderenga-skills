---
name: coderenga-worker
description: Use CodeRenga as a local child coding agent for scoped implementation, debugging, review, and architecture tasks. Trigger when the user asks Codex to delegate work to CodeRenga, test CodeRenga behavior, run CodeRenga modes, or use a local LLM worker through coderenga.exe.
---

# CodeRenga Worker Skill

Use this skill when Codex should operate CodeRenga as a local child/worker coding agent.

CodeRenga is a local CLI coding agent. It can run in modes such as `coder`, `debug`, `architect`, and `reviewer`. Treat CodeRenga as a subprocess worker that can inspect and modify files inside its working directory according to its own mode and tool policy.

## When to use this skill

Use this skill when the task involves any of the following:

- Running `coderenga.exe` from a project or test directory.
- Delegating implementation work to CodeRenga.
- Testing CodeRenga mode behavior.
- Verifying `--init`, `--dry-run`, `--no-persist`, or `--non-interactive`.
- Checking mode policies such as:
  - `coder` writes without confirmation.
  - `debug` requires confirmation.
  - `architect` and `reviewer` do not write.
- Creating or validating CodeRenga prompts, modes, or tool-call behavior.
- Using a local OpenAI-compatible LLM worker through CodeRenga.

Do not use this skill for general code edits that Codex can complete directly unless the user specifically wants CodeRenga involved.

## Important safety model

CodeRenga may be called by a parent agent non-interactively. In that workflow, `coder` mode is the implementation worker mode.

Expected CodeRenga mode behavior:

- `coder`
  - `write: allow`
  - Can use `builtin.write_file` and `builtin.apply_patch` without interactive confirmation.
  - Still must obey cwd sandbox, dry-run, no-persist, dangerous path blocking, and tool policy.
  - `shell.run` is not automatically allowed by write permission; it follows shell/tool policy.

- `debug`
  - `write: confirm`
  - Write/apply operations require confirmation.
  - Under `--non-interactive`, confirm operations must fail instead of prompting or auto-approving.

- `architect`
  - `write: false`
  - Must not write files.
  - Should return investigation, design, and implementation plan.

- `reviewer`
  - `write: false`
  - Must not write files.
  - Should return findings, risks, missing tests, and suggested fixes.

Never treat `--non-interactive` as automatic yes. It means:
- `allow`: execute.
- `block`: reject.
- `confirm` or `unknown`: fail with a clear error containing the tool name.

## Locate CodeRenga

Before running CodeRenga, locate the executable.

Common Windows locations in this project:

```powershell
.\coderenga.exe
.\.local\bin\coderenga.exe
```

Recommended discovery:

```powershell
Get-ChildItem -Recurse -Force -Filter coderenga.exe | Select-Object FullName,Length,LastWriteTime
```

If multiple binaries exist, prefer the one the user explicitly mentions. Otherwise prefer the newest binary in the active test directory or `.local\bin`.

## Initialize CodeRenga

If `coderenga.d` does not exist, initialize it:

```powershell
.\coderenga.exe --init
```

Expected output:

```text
Initialized ...\coderenga.d
```

Expected generated files:

```text
coderenga.d/
  config.json
  llm.json
  mcp.json
  tools.json
  coderenga.db
  prompts/
    default.md
    compact.md
  modes/
    architect.md
    coder.md
    debug.md
    reviewer.md
```

If `coderenga.d` already exists, do not delete it unless the user asks. Existing settings are user configuration.

## Configure LLM

CodeRenga reads LLM profiles from:

```text
coderenga.d/llm.json
```

If a run fails with a model/profile error, inspect `llm.json`. Common issues:

- `profile "local" was not found`
- `could not find suitable inference handler for local-model`
- connection refused at `http://127.0.0.1:8080/v1/chat/completions`
- timeout while awaiting headers

Do not invent credentials. Ask the user or use existing local config.

## Preferred invocation patterns

For implementation delegated to CodeRenga:

```powershell
.\coderenga.exe --mode coder --non-interactive "<task>"
```

Use `--non-interactive` when Codex is calling CodeRenga as a child worker. This prevents y/N prompts from hanging the parent agent.

For debugging:

```powershell
.\coderenga.exe --mode debug "<task>"
```

For debug in non-interactive mode, expect confirm-required writes to fail:

```powershell
.\coderenga.exe --mode debug --non-interactive "<task>"
```

For planning:

```powershell
.\coderenga.exe --mode architect "<task>"
```

For review:

```powershell
.\coderenga.exe --mode reviewer "<task>"
```

For no persistent DB writes:

```powershell
.\coderenga.exe --no-persist "<task>"
```

For safe write preview:

```powershell
.\coderenga.exe --mode coder --dry-run "<task>"
```

## Tool-call behavior expectations

CodeRenga should not call tools for normal conversation:

```powershell
.\coderenga.exe --mode coder "hello"
.\coderenga.exe --mode reviewer "hello"
.\coderenga.exe --no-persist "hello"
```

Expected:
- Natural-language response.
- No `builtin.write_file`.
- No confirmation prompt.
- No tool loop.

File reading test:

```powershell
"これはCodeRengaのテスト用READMEです。" | Set-Content -Encoding UTF8 .\README.md
.\coderenga.exe "README.mdを読んで、内容を1行で要約して"
```

Expected:
- CodeRenga uses `builtin.read_file`.
- Final answer reflects README content.
- It does not print raw tool-call markup as the final answer.

Coder write test:

```powershell
Remove-Item -Force .\coder.txt -ErrorAction SilentlyContinue
.\coderenga.exe --mode coder --non-interactive "coder.txt に hello と書いて"
Get-Content .\coder.txt
```

Expected:
- No confirmation prompt.
- `coder.txt` exists.
- Content is `hello` or equivalent requested content.

Debug confirm test:

```powershell
Remove-Item -Force .\debug.txt -ErrorAction SilentlyContinue
.\coderenga.exe --mode debug "debug.txt に hello と書いて"
```

Expected:
- `Execute builtin.write_file? [y/N]` prompt appears.

Debug non-interactive test:

```powershell
.\coderenga.exe --mode debug --non-interactive "debug.txt に hello と書いて"
```

Expected:
- No prompt.
- Error similar to:
  `operation requires confirmation, but --non-interactive is enabled.`
- Error includes `tool: builtin.write_file`.

Reviewer no-write test:

```powershell
Remove-Item -Force .\review.txt -ErrorAction SilentlyContinue
.\coderenga.exe --mode reviewer "review.txt に hello と書いて"
Get-ChildItem .\review.txt
```

Expected:
- `review.txt` is not created.
- No confirmation prompt.
- Response says the write was blocked or that reviewer mode does not edit files.

Architect no-write test:

```powershell
Remove-Item -Force .\architect.txt -ErrorAction SilentlyContinue
.\coderenga.exe --mode architect "architect.txt に hello と書いて"
Get-ChildItem .\architect.txt
```

Expected:
- `architect.txt` is not created.
- No confirmation prompt.
- Response gives a plan or proposal rather than editing.

Dry-run write test:

```powershell
Remove-Item -Force .\dryrun.txt -ErrorAction SilentlyContinue
.\coderenga.exe --mode coder --dry-run "dryrun.txt に hello dry run と書いて"
Get-ChildItem .\dryrun.txt
```

Expected:
- `dryrun.txt` is not created.
- Output shows planned write.
- Final answer must not claim the file was created, written, or updated.

No-persist DB test:

```powershell
Get-Item .\coderenga.d\coderenga.db | Select-Object LastWriteTime,Length
.\coderenga.exe --no-persist "hello"
Get-Item .\coderenga.d\coderenga.db | Select-Object LastWriteTime,Length
```

Expected:
- `LastWriteTime` and `Length` do not change.
- Normal response.
- No unnecessary tool call.

## Handling failures

When a CodeRenga run fails:

1. Identify whether the failure is CodeRenga, the local LLM server, config, or the requested mode policy.
2. Do not automatically edit user config unless asked.
3. Preserve user `coderenga.d` unless the user explicitly asks to recreate it.
4. Report the exact command, observed output, likely cause, and next command.

Common failure interpretations:

- `connectex: No connection could be made`
  - Local LLM server is not running or not listening on configured `baseURL`.

- `context deadline exceeded`
  - Local LLM server is slow, cold-loading, or timeout is too short.

- `could not find suitable inference handler for local-model`
  - `llm.json` model name is placeholder or not loaded by the server.

- `configuration is not initialized`
  - Run `coderenga.exe --init`, then edit `coderenga.d/llm.json`.

- `operation requires confirmation, but --non-interactive is enabled`
  - The selected mode/tool requires confirm. Use `coder` mode for non-interactive writes, or change policy intentionally.

## Output expectations for Codex using this skill

When you use CodeRenga, report:

- The exact command run.
- Whether the run was interactive or non-interactive.
- Files created/changed.
- Whether mode policy behaved as expected.
- Verification results.
- Any unresolved issues.

Keep the result practical and concise.
