# Changelog

<!-- markdownlint-disable MD024 -->

All notable changes to the Specify CLI and templates are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Google Anti-Gravity Agent Support**
  - Added official support for Google Anti-Gravity IDE agent with Google IDX integration
  - Implemented split-config approach for Google IDX/Firebase Studio compatibility:
    - `.idx/dev.nix` - Runtime environment setup (Python 3.11, uv, mcp library)
    - `.idx/mcp.json` - MCP server registration for Google IDX
    - `.idx/specify_mcp.py` - FastMCP server with specify and plan prompts
  - Agent configuration in `src/specify_cli/__init__.py` with folder `.idx/`
  - Build scripts updated to generate antigravity release packages with template copying
  - Agent context update scripts (bash and PowerShell) support antigravity
  - Template files created in `templates/antigravity/`
  - Documentation updated with Anti-Gravity in supported agents table
  - Slash commands work via MCP server integration in Google IDX

## [0.0.17] - 2025-10-28

### Changed

- **Consistent Feature Directory Naming Across All Locations**
  - Feature directories now use the **same name** across branch, specs, and prompts locations
  - Example: Feature `001-auth` uses:
    - Branch name: `001-auth`
    - Specs directory: `specs/001-auth/`
    - Prompts directory: `history/prompts/001-auth/` (was `history/prompts/auth/`)
  - **Why this matters**: Large teams benefit from predictable, consistent naming:
    - Sorted ordering: `001`, `002`, `003`, etc. sort naturally
    - Unified grep patterns: Single search finds feature across all locations
    - No parsing overhead: Teams use same identifier everywhere
    - Automation-friendly: CI/CD scripts need no name extraction logic
  - Updated `scripts/bash/create-phr.sh` routing logic to use full branch name
  - Updated `scripts/bash/create-new-feature.sh` and `scripts/powershell/create-new-feature.ps1` auto-creation logic

## [0.0.16] - 2025-10-28

### Changed

- **Auto-create PHR Directories When Specifying Features**
  - When `/sp.specify` creates a new feature, it now automatically creates the corresponding `history/prompts/<branch-name>/` directory
  - **Consistent naming**: Feature directories now use the same name across all three locations:
    - Branch: `001-auth`
    - Specs: `specs/001-auth/`
    - Prompts: `history/prompts/001-auth/`
  - Eliminates manual directory creation and "first PHR surprise"
  - Improves team efficiency with predictable, sorted directory structures
  - Users can immediately start documenting their feature work after specification
  - Updated both `scripts/bash/create-new-feature.sh` and `scripts/powershell/create-new-feature.ps1`

- **Reorganized Prompt History Record (PHR) Directory Structure**
  - All prompts now consolidated under `history/prompts/` with logical subdirectories:
    - `history/prompts/constitution/` - Constitution stage prompts (project principles)
    - `history/prompts/<branch-name>/` - Feature-specific prompts (spec, plan, tasks, red, green, refactor, explainer, misc)
    - `history/prompts/general/` - General/catch-all prompts for non-feature work
  - **Consistent naming across project**: Feature directories use the same name everywhere (e.g., `001-auth` in branch, specs, and prompts)
  - **Rationale:** Developers reported confusion with prompts split between `history/` and `specs/<feature>/prompts/`. Consolidating under `history/prompts/` with consistent naming provides a single, clear, predictable location for all prompt history.
  - Directory structure is predictable and team-friendly (numbered directories sort chronologically)
  - Updated `scripts/bash/create-phr.sh` with new routing logic
  - Updated `templates/commands/phr.md` with new directory mapping
  - Updated `protocol-templates/AGENTS.md` with new routing documentation
  - Updated `memory/command-rules.md` with new routing rules

- **Fixed AGENTS.md Redundancy in Template Generation**
  - Removed generic `AGENTS.md` from project root in release packages
  - Agent-specific rule files (CLAUDE.md, GEMINI.md, QWEN.md, etc.) now contain all AGENTS.md content with agent-specific preface
  - Eliminates duplicate files while preserving all protocol information
  - Added missing AMP agent support to `generate_agent_rules()` function
  - Updated `.github/workflows/scripts/create-release-packages.sh` to properly generate agent-specific rule files for all 14 supported agents

### Fixed

- `create-release-packages.sh` now properly generates rule files for AMP agent (previously missing from generate_agent_rules)

### Optimized

- **Reduced package bloat**: Removed redundant files from release packages:
  - Generic `AGENTS.md` no longer shipped (replaced by agent-specific files: CLAUDE.md, GEMINI.md, etc.)
  - `command-rules.md` no longer shipped as standalone file (automatically appended to all commands during build)
  - Result: Cleaner packages, only user-facing files included

## [0.0.20] - 2025-10-14

### Added

- **Intelligent Branch Naming**: `create-new-feature` scripts now support `--short-name` parameter for custom branch names
  - When `--short-name` provided: Uses the custom name directly (cleaned and formatted)
  - When omitted: Automatically generates meaningful names using stop word filtering and length-based filtering
  - Filters out common stop words (I, want, to, the, for, etc.)
  - Removes words shorter than 3 characters (unless they're uppercase acronyms)
  - Takes 3-4 most meaningful words from the description
  - **Enforces GitHub's 244-byte branch name limit** with automatic truncation and warnings
  - Examples:
    - "I want to create user authentication" → `001-create-user-authentication`
    - "Implement OAuth2 integration for API" → `001-implement-oauth2-integration-api`
    - "Fix payment processing bug" → `001-fix-payment-processing`
    - Very long descriptions are automatically truncated at word boundaries to stay within limits
  - Designed for AI agents to provide semantic short names while maintaining standalone usability

### Changed

- Enhanced help documentation for `create-new-feature.sh` and `create-new-feature.ps1` scripts with examples
- Branch names now validated against GitHub's 244-byte limit with automatic truncation if needed

## [0.0.19] - 2025-10-10

### Added

- **Intelligent Branch Naming**: `create-new-feature` scripts now support `--short-name` parameter for custom branch names
  - When `--short-name` provided: Uses the custom name directly (cleaned and formatted)
  - When omitted: Automatically generates meaningful names using stop word filtering and length-based filtering
  - Filters out common stop words (I, want, to, the, for, etc.)
  - Removes words shorter than 3 characters (unless they're uppercase acronyms)
  - Takes 3-4 most meaningful words from the description
  - **Enforces GitHub's 244-byte branch name limit** with automatic truncation and warnings
  - Examples:
    - "I want to create user authentication" → `001-create-user-authentication`
    - "Implement OAuth2 integration for API" → `001-implement-oauth2-integration-api`
    - "Fix payment processing bug" → `001-fix-payment-processing`
    - Very long descriptions are automatically truncated at word boundaries to stay within limits
  - Designed for AI agents to provide semantic short names while maintaining standalone usability

### Changed

- Fixed the path to the constitution in `plan.md` (thank you to [@lyzno1](https://github.com/lyzno1) for spotting).
- Fixed backslash escapes in generated TOML files for Gemini (thank you to [@hsin19](https://github.com/hsin19) for the contribution).
- Implementation command now ensures that the correct ignore files are added (thank you to [@sigent-amazon](https://github.com/sigent-amazon) for the contribution).

## [0.0.18] - 2025-10-06

### Added

- Support for using `.` as a shorthand for current directory in `specify init .` command, equivalent to `--here` flag but more intuitive for users.
- Use the `/speckit.` command prefix to easily discover Spec Kit-related commands.
- Refactor the prompts and templates to simplify their capabilities and how they are tracked. No more polluting things with tests when they are not needed.
- Ensure that tasks are created per user story (simplifies testing and validation).
- Add support for Visual Studio Code prompt shortcuts and automatic script execution.

### Changed

- All command files now prefixed with `speckit.` (e.g., `speckit.specify.md`, `speckit.plan.md`) for better discoverability and differentiation in IDE/CLI command palettes and file explorers

## [0.0.17] - 2025-09-22

### Added

- New `/clarify` command template to surface up to 5 targeted clarification questions for an existing spec and persist answers into a Clarifications section in the spec.
- New `/analyze` command template providing a non-destructive cross-artifact discrepancy and alignment report (spec, clarifications, plan, tasks, constitution) inserted after `/tasks` and before `/implement`.
  - Note: Constitution rules are explicitly treated as non-negotiable; any conflict is a CRITICAL finding requiring artifact remediation, not weakening of principles.

## [0.0.16] - 2025-09-22

### Added

- `--force` flag for `init` command to bypass confirmation when using `--here` in a non-empty directory and proceed with merging/overwriting files.

## [0.0.15] - 2025-09-21

### Added

- Support for Roo Code.

## [0.0.14] - 2025-09-21

### Changed

- Error messages are now shown consistently.

## [0.0.13] - 2025-09-21

### Added

- Support for Kilo Code. Thank you [@shahrukhkhan489](https://github.com/shahrukhkhan489) with [#394](https://github.com/github/spec-kit/pull/394).
- Support for Auggie CLI. Thank you [@hungthai1401](https://github.com/hungthai1401) with [#137](https://github.com/github/spec-kit/pull/137).
- Agent folder security notice displayed after project provisioning completion, warning users that some agents may store credentials or auth tokens in their agent folders and recommending adding relevant folders to `.gitignore` to prevent accidental credential leakage.

### Changed

- Warning displayed to ensure that folks are aware that they might need to add their agent folder to `.gitignore`.
- Cleaned up the `check` command output.

## [0.0.12] - 2025-09-21

### Changed

- Added additional context for OpenAI Codex users - they need to set an additional environment variable, as described in [#417](https://github.com/github/spec-kit/issues/417).

## [0.0.11] - 2025-09-20

### Added

- Codex CLI support (thank you [@honjo-hiroaki-gtt](https://github.com/honjo-hiroaki-gtt) for the contribution in [#14](https://github.com/github/spec-kit/pull/14))
- Codex-aware context update tooling (Bash and PowerShell) so feature plans refresh `AGENTS.md` alongside existing assistants without manual edits.

## [0.0.10] - 2025-09-20

### Fixed

- Addressed [#378](https://github.com/github/spec-kit/issues/378) where a GitHub token may be attached to the request when it was empty.

## [0.0.9] - 2025-09-19

### Changed

- Improved agent selector UI with cyan highlighting for agent keys and gray parentheses for full names

## [0.0.8] - 2025-09-19

### Added

- Windsurf IDE support as additional AI assistant option (thank you [@raedkit](https://github.com/raedkit) for the work in [#151](https://github.com/github/spec-kit/pull/151))
- GitHub token support for API requests to handle corporate environments and rate limiting (contributed by [@zryfish](https://github.com/@zryfish) in [#243](https://github.com/github/spec-kit/pull/243))

### Changed

- Updated README with Windsurf examples and GitHub token usage
- Enhanced release workflow to include Windsurf templates

## [0.0.7] - 2025-09-18

### Changed

- Updated command instructions in the CLI.
- Cleaned up the code to not render agent-specific information when it's generic.

## [0.0.6] - 2025-09-17

### Added

- opencode support as additional AI assistant option

## [0.0.5] - 2025-09-17

### Added

- Qwen Code support as additional AI assistant option

## [0.0.4] - 2025-09-14

### Added

- SOCKS proxy support for corporate environments via `httpx[socks]` dependency

### Fixed

N/A

### Changed

N/A
