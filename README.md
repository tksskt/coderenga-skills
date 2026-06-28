# CodeRenga skills pack v2

This pack provides CodeRenga integrations for Codex, Claude Code, OpenCode, and Cursor.

The important correction in v2 is that OpenCode and Cursor now use real Agent Skill directories, not only always-on rule files.

## Layout

```text
coderenga-skills-v2/
├─ codex/
│  └─ .agents/skills/coderenga/
│     ├─ SKILL.md
│     └─ scripts/
│        ├─ install-coderenga.sh
│        └─ install-coderenga.ps1
├─ claude-code/
│  └─ .claude/skills/coderenga/
│     ├─ SKILL.md
│     └─ scripts/
│        ├─ install-coderenga.sh
│        └─ install-coderenga.ps1
├─ opencode/
│  ├─ .opencode/skills/coderenga/
│  │  ├─ SKILL.md
│  │  └─ scripts/
│  │     ├─ install-coderenga.sh
│  │     └─ install-coderenga.ps1
│  └─ AGENTS.md
└─ cursor/
   ├─ .cursor/skills/coderenga/
   │  ├─ SKILL.md
   │  └─ scripts/
   │     ├─ install-coderenga.sh
   │     └─ install-coderenga.ps1
   └─ .cursor/rules/coderenga-skill-bridge.mdc
```

## Correct placement

### Codex

Copy this into the target repo or your global skills directory:

```text
.agents/skills/coderenga/SKILL.md
```

### Claude Code

Project-local:

```text
.claude/skills/coderenga/SKILL.md
```

Global:

```text
~/.claude/skills/coderenga/SKILL.md
```

### OpenCode

Project-local Agent Skill:

```text
.opencode/skills/coderenga/SKILL.md
```

Global Agent Skill:

```text
~/.config/opencode/skills/coderenga/SKILL.md
```

Optional, but recommended for more aggressive natural-language routing:

```text
AGENTS.md
```

If the project already has `AGENTS.md`, merge the CodeRenga section rather than replacing the file.

### Cursor

Project-local Agent Skill:

```text
.cursor/skills/coderenga/SKILL.md
```

Global Agent Skill:

```text
~/.cursor/skills/coderenga/SKILL.md
```

Optional, but recommended for more aggressive natural-language routing:

```text
.cursor/rules/coderenga-skill-bridge.mdc
```

This bridge rule is intentionally small. The procedural workflow lives in the skill.

## Release asset naming recommendation

The installers fetch from `tksskt/CodeRenga` GitHub Releases. Publish assets with names like:

```text
coderenga-windows-amd64.zip
coderenga-linux-amd64.tar.gz
coderenga-darwin-arm64.tar.gz
```

Each archive should contain `coderenga` or `coderenga.exe`.

If no release exists, the installers fail clearly instead of guessing or building from source.

## Installer behavior

All four tool integrations, Codex, Claude Code, OpenCode, and Cursor, use the same basic installer behavior:

- If CodeRenga is not installed, the installer calls the latest GitHub Release API for `tksskt/CodeRenga`, selects a matching platform/arch asset, and installs `coderenga` or `coderenga.exe` into `.local/bin` / `.local\bin` by default.
- If CodeRenga already exists on `PATH` or in `.local/bin` / `.local\bin`, the installer reuses that binary and does not download it again.
- After resolving the binary, the installer runs `--init` in the target init directory every time.
- Existing `coderenga.d` is user configuration. The installers do not delete or recreate it; `--init` is expected to be idempotent and preserve existing settings.
