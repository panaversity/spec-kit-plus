---
description: CAPS - Create reusable Intelligence Packages bundling skills, commands, and agents.
scripts:
  sh: scripts/bash/caps.sh "{ARGS}"
  ps: scripts/powershell/caps.ps1 "{ARGS}"
---

## User Input

```text
$ARGUMENTS
```

<caps_context>
CAPS Playbooks are **Reusable Intelligence Packages** that bundle:
- **Skills** - Domain knowledge and instructions
- **Commands** - Slash commands for specific workflows
- **Agents** - Specialized subagents for parallel work

```
playbooks/deploy-workflow/
├── playbook.md      →  .claude/skills/deploy-workflow/SKILL.md
├── commands/*.md    →  .claude/commands/
└── agents/*.md      →  .claude/agents/
```

Claude gets the full package. Other agents (Goose, Gemini, Qwen) get skills with progressive disclosure to commands/agents.
</caps_context>

<default_to_action>
When user mentions an existing skill path, run import immediately.
When user asks to create a playbook, run new immediately.
Do not explain - just do it, then report results.
</default_to_action>

<investigate_before_acting>
Before editing any playbook.md, read it first.
Before suggesting changes, read the sample at `playbooks/internal-comms/`.
</investigate_before_acting>

## Commands

### new - Create playbook

```bash
{SCRIPT} new <name>
```

Creates `playbooks/<name>/` with full structure. Help user fill in files.

### validate - Check structure

```bash
{SCRIPT} validate playbooks/<name>
{SCRIPT} validate playbooks/<name> --check-references
```

### lint - Quality check

```bash
{SCRIPT} lint playbooks/<name>
```

### compile - Generate Claude format

```bash
{SCRIPT} compile playbooks/<name>              # Compile single playbook
{SCRIPT} compile playbooks/<name> --dry-run    # Preview without writing
{SCRIPT} compile playbooks/                    # Batch compile all
```

### import - Convert existing skill

```bash
{SCRIPT} import .claude/skills/<name>
```

## Playbook Structure

```
playbooks/<name>/
├── playbook.md         # Main skill (YAML frontmatter + markdown)
├── commands/           # Slash commands (optional)
│   └── <cmd>.md        # → .claude/commands/<cmd>.md
├── agents/             # Subagents (optional)
│   └── <agent>.md      # → .claude/agents/<agent>.md
├── scripts/            # Helper scripts
└── references/         # Documentation
```

## File Formats

### playbook.md (Skill)

```yaml
---
name: deploy-workflow
title: Deploy Workflow
description: |
  Deploys applications to production.
  Use when deploying, setting up CI/CD, or configuring environments.
version: "1.0"
allowed_tools:
  - Bash
  - Read
  - Write
references:
  - playbooks/docker-build
---

# Deploy Workflow

Instructions here...
```

### commands/<cmd>.md

```yaml
---
description: Deploy to production environment
---

## Context

$ARGUMENTS

## Instructions

Detailed workflow steps...
```

### agents/<agent>.md

```yaml
---
name: security-reviewer
description: Reviews code for security issues
model: haiku
skills: deploy-workflow
---

# Security Reviewer

You are a security specialist...
```

## Output (Claude)

```
.claude/
├── skills/<name>/
│   ├── SKILL.md           # With disclosure sections
│   ├── scripts/
│   └── references/
├── commands/<cmd>.md      # Slash commands
└── agents/<agent>.md      # Subagents
```

SKILL.md automatically includes:
- **## Commands** - Lists available slash commands
- **## Subagents** - Lists available agents
- **## Related Skills** - Links to referenced playbooks

## Locations

- **Playbooks**: `playbooks/`
- **Sample**: `playbooks/internal-comms/`
- **Templates**: `.specify/templates/caps/`
- **Output**: `.claude/skills/`, `.claude/commands/`, `.claude/agents/`
