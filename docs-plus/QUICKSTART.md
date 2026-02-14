# ⚡ Quickstart Guide — SpecifyPlus (Spec-Kit Plus)

> **Go from zero to your first Spec-Driven Development project in under 10 minutes.**

This guide walks you through the full SDD workflow end-to-end: install SpecifyPlus, initialize a project, and run every core slash command in order. By the end, you will have a working project built with the **Constitution → Specify → Clarify → Plan → Tasks → Implement** pipeline.

---

## Prerequisites

Before you begin, make sure you have these installed:

| Tool | Minimum Version | Check Command |
|------|----------------|---------------|
| Python | 3.12+ | `python --version` |
| Git | Any recent | `git --version` |
| AI Coding Agent | — | Claude Code, Gemini CLI, Copilot, Cursor, etc. |

> **Important:** SpecifyPlus is a *framework*, not an AI tool. It works **with** your AI assistant (Claude Code, Gemini CLI, etc.). You need both.

---

## Step 1 — Install SpecifyPlus

```bash
# Install using pip
pip install specifyplus

# Verify installation
specifyplus --version
```

**Alternative (using uv):**

```bash
uv tool install specify-cli --from git+https://github.com/panaversity/spec-kit-plus.git
```

---

## Step 2 — Initialize Your Project

```bash
# Create a new project (replace "claude" with your AI agent)
specifyplus init my-first-project --ai claude

# Navigate into the project
cd my-first-project
```

**Supported `--ai` options:** `claude`, `gemini`, `copilot`, `cursor-agent`, `qwen`, `opencode`, `codex`, `windsurf`, `kilocode`, `auggie`, `codebuddy`

After initialization, your project structure looks like this:

```text
my-first-project/
├── .claude/                    # (or .gemini/, .github/prompts/, etc.)
│   └── commands/               # Slash commands for SDD workflow
│       ├── sp.constitution.md
│       ├── sp.specify.md
│       ├── sp.clarify.md
│       ├── sp.plan.md
│       ├── sp.tasks.md
│       ├── sp.implement.md
│       ├── sp.analyze.md
│       ├── sp.adr.md
│       ├── sp.phr.md
│       ├── sp.checklist.md
│       └── sp.git.commit_pr.md
├── .specify/
│   ├── memory/
│   │   └── constitution.md     # Project-wide rules (populated in Step 3)
│   ├── scripts/bash/           # Automation scripts
│   └── templates/              # Templates for specs, plans, tasks
├── CLAUDE.md                   # Agent instructions
├── README.md
└── .gitignore
```

---

## Step 3 — The SDD Workflow (6 Phases)

Now launch your AI assistant inside the project directory. All `/sp.*` commands are available as slash commands.

### Phase 1: Constitution — Set Project-Wide Rules

The Constitution defines the standards that apply to **all** features in the project. You write it once.

```text
/sp.constitution

Project principles and standards:
- Write tests first (TDD approach)
- Use Python 3.12+ with type hints everywhere
- Keep code clean and readable
- Document important decisions with ADRs
Technical stack:
- Python 3.12+ with UV package manager
- FastAPI for the web framework
- pytest for testing
Quality requirements:
- All tests must pass before merging
- Minimum 80% code coverage
```

This populates `.specify/memory/constitution.md`, which every future command will respect.

### Phase 2: Specify — Describe What You Want to Build

Focus on the **what** and **why**, not the technical details.

```text
/sp.specify

Build a REST API that manages a personal reading list.
Users can add books with title, author, and status (to-read, reading, finished).
Users can list, update, and delete books.
The API should return JSON responses with proper HTTP status codes.
```

**Output:** A specification file is created in `specs/<feature>/spec.md`.

### Phase 3: Clarify — Refine the Specification

This command asks targeted clarification questions to fill gaps in your spec.

```text
/sp.clarify
```

The AI will ask up to 5 focused questions. Your answers are recorded in a **Clarifications** section within the spec, reducing rework downstream.

### Phase 4: Plan — Generate a Technical Plan

Now you get specific about the tech stack and implementation approach.

```text
/sp.plan

Use FastAPI with SQLite for the database.
Keep it simple — no authentication for now.
Include Swagger/OpenAPI docs out of the box.
```

**Output:** An implementation plan with directory structures, API contracts, and file creation order is generated in `specs/<feature>/plan.md`.

### Phase 5: Tasks — Break the Plan into Atomic Tasks

```text
/sp.tasks
```

**Output:** The plan is decomposed into small, implementable tasks in `specs/<feature>/tasks.md`. Each task maps to a specific user story and has clear acceptance criteria.

### Phase 6: Implement — Build It

```text
/sp.implement
```

The AI executes the tasks one by one, creating files, writing tests, and building your project. After implementation, **validate the output:**

- Review the generated code — do you understand it?
- Run the test suite: `pytest`
- Check for anything the spec didn't mention
- Verify type hints: `mypy .`

---

## Optional but Recommended Commands

| Command | Purpose |
|---------|---------|
| `/sp.analyze` | Run a cross-artifact consistency check (spec vs. plan vs. tasks) |
| `/sp.adr` | Record an Architecture Decision Record for significant choices |
| `/sp.phr` | Save a Prompt History Record of prompts that worked well |
| `/sp.checklist` | Generate a custom checklist for any workflow step |
| `/sp.git.commit_pr` | Commit changes and create a pull request |

---

## Full Workflow at a Glance

```text
/sp.constitution   →  Set project-wide rules (once per project)
       ↓
/sp.specify        →  Describe WHAT to build
       ↓
/sp.clarify        →  Refine gaps in the spec
       ↓
/sp.plan           →  Generate HOW to build it
       ↓
/sp.tasks          →  Break plan into atomic tasks
       ↓
/sp.implement      →  AI builds it, you validate
       ↓
/sp.analyze        →  (Optional) Cross-artifact consistency check
```

---

## Upgrading an Existing Project

If you already have a project and want to add SpecifyPlus to it:

```bash
# Navigate to your existing project
cd my-existing-project

# Initialize SpecifyPlus in the current directory
specifyplus init --here --ai claude
```

> **Note:** Your existing files are preserved. SpecifyPlus templates are merged alongside them. However, back up `.specify/memory/constitution.md` before upgrading if you have customized it, as `--force` may overwrite it.

To upgrade the CLI itself:

```bash
uv tool install specify-cli --force --from git+https://github.com/panaversity/spec-kit-plus.git
```

---

## Common Issues

| Problem | Solution |
|---------|----------|
| `pip install specifyplus` fails | Ensure Python 3.12+. Run `python --version` to check. |
| Slash commands don't appear | Re-run `specifyplus init --here --ai <your-agent>` to regenerate command files. |
| Constitution overwritten after upgrade | Back up `constitution.md` before running `init --here --force`. Restore with `git restore .specify/memory/constitution.md`. |
| "I installed Claude Code, so I have Spec-Kit Plus" | They are separate tools. Claude Code is the AI; SpecifyPlus is the framework. You need both. |

---

## What's Next?

- **Read the full README:** [README.md](../README.md)
- **Learn the methodology:** [spec-driven.md](../spec-driven.md) — deep dive into Spec-Driven Development
- **Contributing:** [CONTRIBUTING.md](../CONTRIBUTING.md) — how to add new commands, templates, and docs
- **Changelog:** [CHANGELOG.md](../CHANGELOG.md) — latest features and fixes

---

## Key Concept: Two Outputs

Every SpecifyPlus project produces **two distinct outputs:**

1. **Working Code** — the feature you built (could be rewritten anytime)
2. **Reusable Intelligence** — the specs, ADRs, PHRs, and decisions that captured *why* you built it that way

The code is disposable. The intelligence compounds over time. That's the power of Spec-Driven Development.

---

*This quickstart covers the essentials. For advanced topics like multi-agent orchestration, Kubernetes deployment patterns, and Dapr integration, see the [docs-plus](../docs-plus/) directory and the [protocol-templates](../protocol-templates/) folder.*
