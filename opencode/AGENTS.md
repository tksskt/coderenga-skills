# CodeRenga routing bridge for OpenCode

This file is optional. The real OpenCode Agent Skill is:

```text
.opencode/skills/coderenga/SKILL.md
```

Use the `coderenga` skill proactively for local coding-agent work. The user does not need to explicitly say "coderenga".

Good natural-language triggers include:

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
- requests for refactoring, tests, patch generation, or local repository analysis

When the request matches, load the `coderenga` skill and follow its install/use workflow. If CodeRenga is missing, install from the latest `tksskt/CodeRenga` GitHub Release and initialize only when `coderenga.d` is missing. If no suitable release asset exists, stop and explain that a release asset is required.
