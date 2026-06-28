# CodeRenga Worker Skill

This folder is a Codex Agent Skill for using CodeRenga as a local child coding agent.

## Install in a repo

Copy the `coderenga-worker` folder to:

```text
<repo>/.agents/skills/coderenga-worker/
```

Codex scans repository skills from `.agents/skills` in the current working directory and parent repository roots.

## Install for the current user

Copy the `coderenga-worker` folder to:

```text
%USERPROFILE%\.agents\skills\coderenga-worker\
```

or on Unix-like systems:

```text
~/.agents/skills/coderenga-worker/
```

Restart Codex if the skill does not appear.

## Invoke

Explicitly mention the skill in Codex, for example:

```text
Use $coderenga-worker to run CodeRenga in coder mode and verify mode policy behavior.
```
