---
name: coderenga
description: Use CodeRenga for local repository inspection, review, debugging, implementation, refactoring, tests, natural-language coding-agent work, or as a local child coding agent. Also install and initialize CodeRenga from tksskt/CodeRenga GitHub Releases when the user asks for setup.
---

# CodeRenga Skill for Cursor

Use this skill when the user asks for practical coding work that benefits from CodeRenga, even when the user does not explicitly say "CodeRenga".

CodeRenga is a local CLI coding agent. It can run in modes such as `coder`, `debug`, `architect`, and `reviewer`. Cursor may also operate it as a subprocess worker for scoped implementation, debugging, review, architecture, or mode-policy verification tasks.

The user can also invoke this manually with `/coderenga` in Cursor Agent chat.

The optional `.cursor/rules/coderenga-skill-bridge.mdc` bridge can route more natural-language requests toward this skill. Keep the detailed workflow here and use the bridge rule only as a small routing hint.

## Good triggers

Use this skill for requests like:

- `coderengaをインストールして`
- `リポジトリを見て`
- `レビューして`
- `実装して`
- `修正して`
- `デバッグして`
- `inspect this repo`
- `review this change`
- `fix this bug`
- `implement this`
- requests for refactoring, test generation, local repository analysis, or patch production
- `CodeRengaに委譲して`
- `coderenga.exeを実行して`
- `CodeRengaのモード挙動を検証して`
- testing CodeRenga behavior, prompts, modes, tool policy, `--init`, `--dry-run`, `--no-persist`, or `--non-interactive`

## Install and initialize

Before using CodeRenga, check whether `coderenga` or `coderenga.exe` already exists.

Common Windows locations in a project:

```powershell
.\coderenga.exe
.\.local\bin\coderenga.exe
```

Recommended discovery:

```powershell
Get-ChildItem -Recurse -Force -Filter coderenga.exe | Select-Object FullName,Length,LastWriteTime
```

If multiple binaries exist, prefer the one the user explicitly mentions. Otherwise prefer the newest binary in the active test directory or `.local\bin`.

If CodeRenga is missing, install it from the latest GitHub Release for `tksskt/CodeRenga` and run initialization in the target project directory. The installers use the GitHub Releases latest release API and choose an asset for the current platform. For Windows x64, the expected asset name is like `coderenga-windows-amd64.zip`.

If CodeRenga is already installed on `PATH` or in `.local/bin` / `.local\bin`, the installers reuse that binary and do not download it again.

After resolving the binary, the installers run `coderenga --init` or `coderenga.exe --init` only when `INIT_DIR/coderenga.d` does not exist. If `coderenga.d` already exists, the installers skip init and preserve the directory completely. To explicitly re-run init, use `FORCE_INIT=1` with the Bash installer or `-ForceInit` with the PowerShell installer. The installers never delete or recreate an existing `coderenga.d`.

From the repository root, prefer:

```bash
bash .cursor/skills/coderenga/scripts/install-coderenga.sh
```

On Windows PowerShell, prefer:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.cursor\skills\coderenga\scripts\install-coderenga.ps1
```

If no GitHub Release or suitable binary asset exists, stop and explain the missing release asset. Do not silently build from source unless the user asks for that fallback.

If `coderenga.d` does not exist, initialize CodeRenga:

```bash
coderenga --init
```

On Windows, use the discovered executable path:

```powershell
.\coderenga.exe --init
```

If `coderenga.d` already exists, do not delete it unless the user asks. Existing settings are user configuration. The installer does not remove existing `coderenga.d`; it skips `--init` by default. Use `FORCE_INIT=1` for Bash or `-ForceInit` for PowerShell only when the user explicitly wants to re-run init over an existing configuration.

Expected generated files include `coderenga.d/config.json`, `llm.json`, `mcp.json`, `tools.json`, `coderenga.db`, prompts, and modes.

## Recommended commands

Inspection or review:

```bash
coderenga --cwd . --mode reviewer "inspect this repository and report key issues"
```

Implementation:

```bash
coderenga --cwd . --mode coder --non-interactive "implement the requested change"
```

Debugging:

```bash
coderenga --cwd . --mode debug "debug the failing behavior and propose the smallest safe fix"
```

Safe one-off inspection:

```bash
coderenga --cwd . --no-persist "inspect this repository"
```

Delegated implementation from Cursor:

```bash
coderenga --cwd . --mode coder --non-interactive "implement the requested change"
```

Safe write preview:

```bash
coderenga --cwd . --mode coder --dry-run "preview the requested change"
```

Planning:

```bash
coderenga --cwd . --mode architect "investigate and propose an implementation plan"
```

Use `--non-interactive` when Cursor calls CodeRenga as a child worker. This prevents confirmation prompts from hanging the parent agent.

## Mode policy expectations

Expected CodeRenga mode behavior:

- `coder`: `write: allow`; can write/apply patches without interactive confirmation, while still obeying cwd sandbox, dry-run, no-persist, dangerous path blocking, and shell/tool policy.
- `debug`: `write: confirm`; write/apply operations require confirmation.
- `architect`: `write: false`; should investigate, design, and plan without editing files.
- `reviewer`: `write: false`; should report findings, risks, missing tests, and suggested fixes without editing files.

Never treat `--non-interactive` as automatic yes:

- `allow`: execute.
- `block`: reject.
- `confirm` or `unknown`: fail with a clear error containing the tool name.

Under `--non-interactive`, confirm-required operations must fail instead of prompting or auto-approving.

## LLM configuration

CodeRenga reads LLM profiles from `coderenga.d/llm.json`.

If a run fails with a model/profile error, inspect `llm.json`. Common issues:

- `profile "local" was not found`
- `could not find suitable inference handler for local-model`
- connection refused at `http://127.0.0.1:8080/v1/chat/completions`
- timeout while awaiting headers

Do not invent credentials. Ask the user or use existing local config.

## Verification

When validating a new CodeRenga binary, check these worker-style core behaviors:

- Fresh init: use a disposable init directory without `coderenga.d`, run the installer or `coderenga.exe --init`, and confirm config, LLM, MCP, tools, database, prompt, and mode files are generated. Also confirm the installer skips init when `coderenga.d` exists, unless `FORCE_INIT=1` or `-ForceInit` is supplied.
- Normal chat: run `hello` in default, `coder`, `reviewer`, and `--no-persist`; expect no write tool, no prompt, and no tool loop.
- Mode write policy: confirm `coder --non-interactive` can write, `debug` prompts for writes, `debug --non-interactive` fails clearly for confirm-required writes, and `reviewer` / `architect` do not write.
- Tool calls: ask CodeRenga to read a test README and summarize it; expect the final answer to reflect the content without raw tool-call markup.
- Dry run: confirm `--mode coder --dry-run` previews writes without creating files or claiming they were written.
- No persist: compare `coderenga.d/coderenga.db` timestamp and length before and after `--no-persist`; expect no change.

## Safety and reporting

- Check the git working tree before destructive operations.
- Prefer review/planning behavior when the task is ambiguous.
- Preserve user `coderenga.d` unless the user explicitly asks to recreate it.
- For failures, identify whether the cause is CodeRenga, the local LLM server, config, or mode policy.
- Summarize the exact command run, whether it was interactive or non-interactive, files created/changed, commands/tests run, mode-policy behavior, failures, and remaining manual steps.
