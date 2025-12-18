---
# Required Fields
name: {{PLAYBOOK_NAME}}
title: {{PLAYBOOK_TITLE}}
description: |
  {{PLAYBOOK_DESCRIPTION}}
  Use when {{TRIGGER_PHRASES}}.

# Optional Fields
version: 1.0.0
# license: MIT

# Restrict available tools (optional)
# allowed_tools:
#   - Bash
#   - Read
#   - Write

# Reference other playbooks (optional, composable)
# references:
#   - playbooks/docker-build
#   - playbooks/health-check
---

# {{PLAYBOOK_TITLE}}

## Overview

Brief description of what this playbook accomplishes.

## Prerequisites

- Prerequisite 1
- Prerequisite 2

## Instructions

### Step 1: {{STEP_1_TITLE}}

Description of step 1.

```bash
bash scripts/step1.sh
```

### Step 2: {{STEP_2_TITLE}}

Description of step 2.

### Step 3: Verify

Verify the setup is complete.

For troubleshooting, see [troubleshooting guide](references/troubleshooting.md).

## Validation Criteria

- [ ] Criterion 1
- [ ] Criterion 2
