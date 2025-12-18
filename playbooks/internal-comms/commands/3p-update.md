---
description: Generate a 3P (Progress, Plans, Problems) team status update
---

## Context

$ARGUMENTS

## Instructions

Generate a concise 3P update for the specified team or project.

### Format

```
[emoji] [Team Name] (Date Range)
Progress: [1-3 sentences on what was accomplished]
Plans: [1-3 sentences on upcoming work]
Problems: [1-3 sentences on blockers or risks]
```

### Guidelines

1. Keep it readable in 30-60 seconds
2. Be data-driven and matter-of-fact
3. Use specific metrics where possible
4. Flag blockers that need escalation

### Example

```
🚀 Platform Team (Dec 9-15)
Progress: Shipped v2.3 with 40% faster API responses. Completed Redis migration.
Plans: Starting GraphQL federation next week. Planning Q1 roadmap.
Problems: CI pipeline flaky - investigating. Need design review for auth changes.
```
