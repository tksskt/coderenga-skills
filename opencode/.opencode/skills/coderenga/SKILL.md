---
name: coderenga
description: Use CodeRenga for local repository inspection, review, debugging, implementation, refactoring, tests, and natural-language coding-agent work. Also install and initialize CodeRenga from tksskt/CodeRenga GitHub Releases when the user asks for setup.
compatibility: opencode
---

# CodeRenga Skill for OpenCode

Use this skill when the user asks for practical coding work that benefits from CodeRenga, even when the user does not explicitly say "CodeRenga".

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

## Install and initialize

Before using CodeRenga, check whether `coderenga` or `coderenga.exe` already exists.

If CodeRenga is missing, install it from the latest GitHub Release for `tksskt/CodeRenga` and run initialization in the target project directory.

From the repository root, prefer:

```bash
bash .opencode/skills/coderenga/scripts/install-coderenga.sh
```

On Windows PowerShell, prefer:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.opencode\skills\coderenga\scripts\install-coderenga.ps1
```

The installer should create or reuse `.local/bin/` by default, then run:

```bash
coderenga --init
```

Confirm that `coderenga.d/` exists after initialization.

If no GitHub Release or suitable binary asset exists, stop and explain the missing release asset. Do not silently build from source unless the user asks for that fallback.

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

## Safety and reporting

- Check the git working tree before destructive operations.
- Prefer review/planning behavior when the task is ambiguous.
- Summarize what CodeRenga did, changed files, commands/tests run, failures, and remaining manual steps.
