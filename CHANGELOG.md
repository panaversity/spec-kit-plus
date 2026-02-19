# Changelog

<!-- markdownlint-disable MD024 -->

All notable changes to the Specify CLI and templates are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-01-28

### Added

- **Extension System**: Introduced modular extension architecture for Spec Kit
  - Extensions are self-contained packages that add commands and functionality without bloating core
  - Extension manifest schema (`extension.yml`) with validation
  - Extension registry (`.specify/extensions/.registry`) for tracking installed extensions
  - Extension manager module (`src/specify_cli/extensions.py`) for installation/removal
  - New CLI commands:
    - `specify extension list` - List installed extensions
    - `specify extension add` - Install extension from local directory or URL
    - `specify extension remove` - Uninstall extension
    - `specify extension search` - Search extension catalog
    - `specify extension info` - Show detailed extension information
  - Semantic versioning compatibility checks
  - Support for extension configuration files
  - Command registration system for AI agents (Claude support initially)
  - Added dependencies: `pyyaml>=6.0`, `packaging>=23.0`

- **Extension Catalog**: Extension discovery and distribution system
  - Central catalog (`extensions/catalog.json`) for published extensions
  - Extension catalog manager (`ExtensionCatalog` class) with:
    - Catalog fetching from GitHub
    - 1-hour local caching for performance
    - Search by query, tag, author, or verification status
    - Extension info retrieval
  - Catalog cache stored in `.specify/extensions/.cache/`
  - Search and info commands with rich console output
  - Added 9 catalog-specific unit tests (100% pass rate)

- **Jira Extension**: First official extension for Jira integration
  - Extension ID: `jira`
  - Version: 1.0.0
  - Commands:
    - `/speckit.jira.specstoissues` - Create Jira hierarchy from spec and tasks
    - `/speckit.jira.discover-fields` - Discover Jira custom fields
    - `/speckit.jira.sync-status` - Sync task completion status
  - Comprehensive documentation (README, usage guide, examples)
  - MIT licensed

- **Hook System**: Extension lifecycle hooks for automation
  - `HookExecutor` class for managing extension hooks
  - Hooks registered in `.specify/extensions.yml`
  - Hook registration during extension installation
  - Hook unregistration during extension removal
  - Support for optional and mandatory hooks
  - Hook execution messages for AI agent integration
  - Condition support for conditional hook execution (placeholder)

- **Extension Management**: Advanced extension management commands
  - `specify extension update` - Check and update extensions to latest version
  - `specify extension enable` - Enable a disabled extension
  - `specify extension disable` - Disable extension without removing it
  - Version comparison with catalog
  - Update notifications
  - Preserve configuration during updates

- **Multi-Agent Support**: Extensions now work with all supported AI agents (Phase 6)
  - Automatic detection and registration for all agents in project
  - Support for 16+ AI agents (Claude, Gemini, Copilot, Cursor, Qwen, and more)
  - Agent-specific command formats (Markdown and TOML)
  - Automatic argument placeholder conversion ($ARGUMENTS → {{args}})
  - Commands registered for all detected agents during installation
  - Multi-agent command unregistration on extension removal
  - `CommandRegistrar.register_commands_for_agent()` method
  - `CommandRegistrar.register_commands_for_all_agents()` method

- **Configuration Layers**: Full configuration cascade system (Phase 6)
  - **Layer 1**: Defaults from extension manifest (`extension.yml`)
  - **Layer 2**: Project config (`.specify/extensions/{ext-id}/{ext-id}-config.yml`)
  - **Layer 3**: Local config (`.specify/extensions/{ext-id}/local-config.yml`, gitignored)
  - **Layer 4**: Environment variables (`SPECKIT_{EXT_ID}_{KEY}` pattern)
  - Recursive config merging with proper precedence
  - `ConfigManager` class for programmatic config access
  - `get_config()`, `get_value()`, `has_value()` methods
  - Support for nested configuration paths with dot-notation

- **Hook Condition Evaluation**: Smart hook execution based on runtime conditions (Phase 6)
  - Config conditions: `config.key.path is set`, `config.key == 'value'`, `config.key != 'value'`
  - Environment conditions: `env.VAR is set`, `env.VAR == 'value'`, `env.VAR != 'value'`
  - Automatic filtering of hooks based on condition evaluation
  - Safe fallback behavior on evaluation errors
  - Case-insensitive pattern matching

- **Hook Integration**: Agent-level hook checking and execution (Phase 6)
  - `check_hooks_for_event()` method for AI agents to query hooks after core commands
  - Condition-aware hook filtering before execution
  - `enable_hooks()` and `disable_hooks()` methods per extension
  - Formatted hook messages for agent display
  - `execute_hook()` method for hook execution information

- **Documentation Suite**: Comprehensive documentation for users and developers
  - **EXTENSION-USER-GUIDE.md**: Complete user guide with installation, usage, configuration, and troubleshooting
  - **EXTENSION-API-REFERENCE.md**: Technical API reference with manifest schema, Python API, and CLI commands
  - **EXTENSION-PUBLISHING-GUIDE.md**: Publishing guide for extension authors
  - **RFC-EXTENSION-SYSTEM.md**: Extension architecture design document

- **Extension Template**: Starter template in `extensions/template/` for creating new extensions
  - Fully commented `extension.yml` manifest template
  - Example command file with detailed explanations
  - Configuration template with all options
  - Complete project structure (README, LICENSE, CHANGELOG, .gitignore)
  - EXAMPLE-README.md showing final documentation format

- **Unit Tests**: Comprehensive test suite with 39 tests covering all extension system components
  - Test coverage: 83% of extension module code
  - Test dependencies: `pytest>=7.0`, `pytest-cov>=4.0`
  - Configured pytest in `pyproject.toml`

### Changed

- Version bumped to 0.1.0 (minor release for new feature)

## [0.0.22] - 2025-11-07

- Support for VS Code/Copilot agents, and moving away from prompts to proper agents with hand-offs.
- Move to use `AGENTS.md` for Copilot workloads, since it's already supported out-of-the-box.
- Adds support for the version command. ([#486](https://github.com/github/spec-kit/issues/486))
- Fixes potential bug with the `create-new-feature.ps1` script that ignores existing feature branches when determining next feature number ([#975](https://github.com/github/spec-kit/issues/975))
- Add graceful fallback and logging for GitHub API rate-limiting during template fetch ([#970](https://github.com/github/spec-kit/issues/970))

## [0.0.21] - 2025-10-21

- Fixes [#975](https://github.com/github/spec-kit/issues/975) (thank you [@fgalarraga](https://github.com/fgalarraga)).
- Adds support for Amp CLI.
- Adds support for VS Code hand-offs and moves prompts to be full-fledged chat modes.
- Adds support for `version` command (addresses [#811](https://github.com/github/spec-kit/issues/811) and [#486](https://github.com/github/spec-kit/issues/486), thank you [@mcasalaina](https://github.com/mcasalaina) and [@dentity007](https://github.com/dentity007)).
- Adds support for rendering the rate limit errors from the CLI when encountered ([#970](https://github.com/github/spec-kit/issues/970), thank you [@psmman](https://github.com/psmman)).

## [Plus 0.0.17] - 2025-10-28 (SpecifyPlus Fork)

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

## [Plus 0.0.16] - 2025-10-28 (SpecifyPlus Fork)

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
