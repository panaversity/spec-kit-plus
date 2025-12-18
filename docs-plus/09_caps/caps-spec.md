# CAPS: Coding Agent Playbook Spec

**Version:** 1.0.0
**Status:** Draft
**Authors:** Panaversity

---

## Overview

CAPS (Coding Agent Playbook Spec) is a vendor-neutral format for writing instructions that AI coding agents can follow. Write once, compile to multiple agent formats.

### Supported Targets

| Target | Output Format | Documentation |
|--------|---------------|---------------|
| Claude Code | `SKILL.md` (YAML frontmatter + Markdown) | [Skills Docs](https://code.claude.com/docs/en/skills) |
| Goose | `recipe.yaml` (YAML) | [Recipes Docs](https://block.github.io/goose/docs/guides/recipes/) |

---

## Design Principles

1. **Scripts are universal** — Both platforms execute shell/Python scripts via bash
2. **Instructions are the core** — The playbook content is what gets compiled
3. **Progressive disclosure** — Reference files loaded on-demand, not upfront
4. **Graceful degradation** — Platform-specific features compile only where supported

---

## Playbook Structure

A CAPS playbook is a **folder** containing:

```
playbooks/
└── <playbook-name>/
    ├── playbook.md              # Required: Main CAPS file
    ├── references/              # Optional: Documentation loaded on-demand
    │   ├── guide.md
    │   └── troubleshooting.md
    ├── scripts/                 # Optional: Executable scripts (universal)
    │   ├── setup.sh
    │   └── validate.py
    └── templates/               # Optional: Template files
        └── config.yaml.tmpl
```

---

## playbook.md Format

The main playbook file uses YAML frontmatter followed by Markdown content.

### YAML Frontmatter

```yaml
---
# Required Fields
name: playbook-name                    # Lowercase, hyphens only (must match folder)
title: Human Readable Title            # Display name
description: |
  What this playbook does and when to use it.
  Include trigger phrases for discoverability.

# Optional Fields
version: 1.0.0                         # Semantic version
license: MIT                           # License identifier

# Tool/Extension Configuration
allowed_tools:                         # Claude: restricts available tools
  - Bash
  - Read
  - Write

extensions:                            # Goose: MCP extensions to load
  - type: builtin
    name: developer
  - type: stdio
    name: my-mcp-server
    cmd: uvx
    args: ["my-mcp-server"]

# Parameters (Goose-only, ignored by Claude)
parameters:
  - key: project_name
    input_type: string
    requirement: required
    description: Name of the project to create
  - key: environment
    input_type: string
    requirement: optional
    default: development
    description: Target environment

# Reference other playbooks (composable, all first-class)
references:
  - playbooks/docker-build
  - playbooks/health-check

# Desktop UI (Goose-only)
activities:
  - "Set up {{ project_name }} project"
  - "Deploy to {{ environment }}"

# Model Settings (Goose-only)
settings:
  goose_provider: anthropic
  goose_model: claude-sonnet-4-20250514
---
```

### Markdown Body

The body contains instructions in standard Markdown:

```markdown
# Playbook Title

## Overview
Brief description of what this playbook accomplishes.

## Prerequisites
- Requirement 1
- Requirement 2

## Instructions

### Step 1: Setup
Detailed instructions...

Run the setup script:
```bash
bash scripts/setup.sh
```

### Step 2: Validate
For detailed validation steps, see [validation guide](references/guide.md).

Run validation:
```bash
python scripts/validate.py
```

## Validation Criteria
- [ ] Criterion 1
- [ ] Criterion 2
```

---

## Field Reference

### Required Fields

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| `name` | string | `^[a-z0-9-]+$`, max 64 chars | Unique identifier, must match folder name |
| `title` | string | max 128 chars | Human-readable display name |
| `description` | string | max 1024 chars | What it does AND when to use it |

### Optional Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `version` | string | `1.0.0` | Semantic version |
| `license` | string | — | License identifier |
| `allowed_tools` | array | — | Claude: restrict available tools |
| `extensions` | array | — | Goose: MCP extensions to load |
| `parameters` | array | — | Goose: dynamic parameters |
| `references` | array | — | Other playbooks to compose |
| `activities` | array | — | Goose Desktop: clickable bubbles |
| `settings` | object | — | Goose: model/provider override |

### Extension Object Schema

```yaml
extensions:
  - type: stdio | sse | builtin      # Required
    name: string                      # Required: unique identifier
    cmd: string                       # Required for stdio: command to run
    args: array                       # Optional: command arguments
    timeout: number                   # Optional: seconds before timeout
    env_keys: array                   # Optional: environment variables
    description: string               # Optional: what it does
```

### Parameter Object Schema

```yaml
parameters:
  - key: string                       # Required: unique identifier
    input_type: string | number | boolean | date | file | select
    requirement: required | optional | user_prompt
    description: string               # Required: human-readable explanation
    default: any                      # Required if optional, forbidden if required
    options: array                    # Required if input_type is select
```

### References Schema

```yaml
references:                           # List of playbook paths
  - playbooks/docker-build            # Relative path to playbook directory
  - playbooks/health-check
```

---

## Compilation Rules

### To Claude Code Skill

**Output Structure:**
```
.claude/skills/<name>/
├── SKILL.md                          # Compiled from playbook.md
├── references/                       # Copied as-is
│   └── *.md
├── scripts/                          # Copied as-is
│   └── *
└── templates/                        # Copied as-is
    └── *
```

**SKILL.md Generation:**

```yaml
---
name: {{ name }}
description: {{ description }}
{% if allowed_tools %}
allowed-tools: {{ allowed_tools | join(", ") }}
{% endif %}
{% if license %}
license: {{ license }}
{% endif %}
---

{{ markdown_body }}
```

**Field Mapping:**

| CAPS Field | Claude Skill Field | Notes |
|------------|-------------------|-------|
| `name` | `name` | Direct |
| `title` | `# Heading` | First heading in body |
| `description` | `description` | Direct |
| `allowed_tools` | `allowed-tools` | Comma-separated |
| `license` | `license` | Direct |
| `extensions` | — | **Ignored** (use MCP config) |
| `parameters` | — | **Ignored** (not supported) |
| `references` | Related Skills section | Links to sibling skills |
| `activities` | — | **Ignored** (not supported) |
| `settings` | — | **Ignored** (not supported) |

### To Goose Recipe

**Output Structure:**
```
recipes/<name>/
├── recipe.yaml                       # Compiled from playbook.md
├── references/                       # Copied as-is (referenced in instructions)
│   └── *.md
├── scripts/                          # Copied as-is
│   └── *
└── templates/                        # Copied as-is
    └── *
```

**recipe.yaml Generation:**

```yaml
version: "1.0.0"
title: {{ title }}
description: {{ description }}

{% if parameters %}
parameters:
{{ parameters | to_yaml }}
{% endif %}

instructions: |
{{ markdown_body | indent(2) }}

{% if extensions %}
extensions:
{{ extensions | to_yaml }}
{% endif %}

{% if activities %}
activities:
{{ activities | to_yaml }}
{% endif %}

{% if settings %}
settings:
{{ settings | to_yaml }}
{% endif %}
```

**Field Mapping:**

| CAPS Field | Goose Recipe Field | Notes |
|------------|-------------------|-------|
| `name` | filename | `<name>.yaml` or `<name>/recipe.yaml` |
| `title` | `title` | Direct |
| `description` | `description` | Direct |
| `allowed_tools` | — | **Ignored** (use extensions) |
| `extensions` | `extensions` | Direct |
| `parameters` | `parameters` | Direct |
| `references` | `sub_recipes` | Smart compilation with paths |
| `activities` | `activities` | Direct |
| `settings` | `settings` | Direct |

---

## Playbook Composition (Recursive to N Levels)

Playbooks reference other playbooks via the `references` field. All playbooks are **first-class and peers** at the directory level, but the compiler generates appropriate linking for each target.

### Directory Structure (Flat)

```
playbooks/                        # All at same level
├── kafka-setup/playbook.md       # references: [docker-build, health-check]
├── docker-build/playbook.md      # references: [base-container]
├── health-check/playbook.md
└── base-container/playbook.md    # Recursion works to N levels
```

### Frontmatter

```yaml
references:
  - playbooks/docker-build
  - playbooks/health-check
```

### Smart Compilation

**For Claude Code:** Generates a "Related Skills" section with links to sibling skills:

```markdown
## Related Skills

This skill works with the following skills (invoke as needed):

- **docker-build** - See [`.claude/skills/docker-build/SKILL.md`](../docker-build/SKILL.md)
- **health-check** - See [`.claude/skills/health-check/SKILL.md`](../health-check/SKILL.md)
```

**For Goose:** Generates `sub_recipes` array pointing to compiled recipes:

```yaml
sub_recipes:
  - name: docker-build
    path: "{{ recipe_dir }}/../docker-build/recipe.yaml"
  - name: health-check
    path: "{{ recipe_dir }}/../health-check/recipe.yaml"
```

### Benefits

| Aspect | Design Choice |
|--------|---------------|
| Directory structure | Flat - all playbooks are peers |
| Reusability | Maximum - any playbook can reference any other |
| Goose sub_recipes | Full support via smart compilation |
| Claude linking | Related Skills section with links |
| Recursion | N levels deep (kafka → docker → base-container → ...) |
| Discoverability | All playbooks visible at top level |

---

## Reference Files

Files in `references/` are documentation loaded on-demand:

- **Claude:** Linked in SKILL.md, Claude reads when needed
- **Goose:** Can be referenced in instructions, or added to `.goosehints`

**Best Practice:** Keep each reference file focused (<2000 lines).

---

## Scripts

Files in `scripts/` are executable by both platforms:

- **Claude:** Executed via `Bash` tool
- **Goose:** Executed via `developer` extension (shell)

**Best Practices:**
- Include shebang (`#!/bin/bash`, `#!/usr/bin/env python3`)
- Make scripts idempotent where possible
- Document required environment variables
- Use relative paths with `{{ recipe_dir }}` (Goose) or script's directory (Claude)

---

## Validation Rules

A valid CAPS playbook must satisfy:

1. **Folder name** matches `name` field
2. **Required fields** present: `name`, `title`, `description`
3. **Name format:** lowercase alphanumeric + hyphens only
4. **File references** exist (scripts, references, templates)
5. **Parameter defaults:** optional parameters must have defaults
6. **Referenced playbooks:** paths in `references` should point to valid playbooks

---

## CLI Commands

```bash
# Validate a playbook
caps validate playbooks/my-playbook/

# Compile to Claude Code Skill
caps compile playbooks/my-playbook/ --target claude --output .claude/skills/

# Compile to Goose Recipe
caps compile playbooks/my-playbook/ --target goose --output recipes/

# Compile to all targets
caps compile playbooks/my-playbook/ --target all

# Watch and recompile on changes
caps watch playbooks/ --target all

# Convert existing Claude Skill to CAPS
caps import .claude/skills/my-skill/ --from claude --output playbooks/

# Convert existing Goose Recipe to CAPS
caps import recipes/my-recipe.yaml --from goose --output playbooks/
```

---

## Example: Kafka K8s Setup

### playbooks/kafka-k8s-setup/playbook.md

```yaml
---
name: kafka-k8s-setup
title: Kafka Kubernetes Setup
description: |
  Deploy and configure Apache Kafka on Kubernetes using Helm.
  Use when setting up Kafka, message queues, or event streaming on K8s.
version: 1.0.0
license: MIT

allowed_tools:
  - Bash
  - Read

extensions:
  - type: builtin
    name: developer

parameters:
  - key: namespace
    input_type: string
    requirement: optional
    default: kafka
    description: Kubernetes namespace for Kafka
  - key: replicas
    input_type: number
    requirement: optional
    default: 1
    description: Number of Kafka replicas

activities:
  - "Deploy Kafka to {{ namespace }} namespace"
  - "Verify Kafka installation"
---

# Kafka Kubernetes Setup

## Overview
This playbook deploys Apache Kafka on Kubernetes using the Bitnami Helm chart.

## Prerequisites
- Kubernetes cluster running (`kubectl cluster-info`)
- Helm installed (`helm version`)
- Sufficient resources (4GB RAM, 2 CPU minimum)

## Instructions

### Step 1: Add Helm Repository
```bash
bash scripts/add-helm-repo.sh
```

### Step 2: Create Namespace
```bash
kubectl create namespace kafka --dry-run=client -o yaml | kubectl apply -f -
```

### Step 3: Install Kafka
```bash
bash scripts/install-kafka.sh
```

### Step 4: Verify Installation
```bash
bash scripts/verify-kafka.sh
```

For troubleshooting, see [troubleshooting guide](references/troubleshooting.md).

## Validation Criteria
- [ ] All pods in Running state
- [ ] Kafka service accessible within cluster
- [ ] Can create and list topics
```

### playbooks/kafka-k8s-setup/scripts/install-kafka.sh

```bash
#!/bin/bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-kafka}"
REPLICAS="${REPLICAS:-1}"

helm install kafka bitnami/kafka \
  --namespace "$NAMESPACE" \
  --set replicaCount="$REPLICAS" \
  --set zookeeper.replicaCount=1 \
  --wait --timeout 5m

echo "Kafka installed successfully in namespace: $NAMESPACE"
```

### playbooks/kafka-k8s-setup/references/troubleshooting.md

```markdown
# Kafka Troubleshooting Guide

## Common Issues

### Pods Stuck in Pending
- Check resource requests: `kubectl describe pod -n kafka`
- Verify PVC binding: `kubectl get pvc -n kafka`

### Connection Refused
- Verify service: `kubectl get svc -n kafka`
- Check pod logs: `kubectl logs -n kafka kafka-0`
```

---

## Appendix: Platform Feature Support

| Feature | Claude Code | Goose | CAPS Field |
|---------|-------------|-------|------------|
| Instructions | ✅ | ✅ | Markdown body |
| Scripts | ✅ (Bash tool) | ✅ (developer ext) | `scripts/` |
| References | ✅ (on-demand) | ✅ (instructions) | `references/` |
| Tool restrictions | ✅ | ❌ | `allowed_tools` |
| MCP extensions | Via config | ✅ | `extensions` |
| Parameters | ❌ | ✅ | `parameters` |
| Composition | ✅ (auto-compose) | ✅ (separate recipes) | `references` |
| Desktop UI | ❌ | ✅ | `activities` |
| Model override | ❌ | ✅ | `settings` |

---

## References

- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills)
- [Anthropic Skills Repository](https://github.com/anthropics/skills)
- [Goose Recipe Reference Guide](https://block.github.io/goose/docs/guides/recipes/recipe-reference/)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Agentic AI Foundation](https://aaif.io/)
