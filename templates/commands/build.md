---
description: Build and package Command Workflows for local testing and distribution.
scripts:
  sh: scripts/bash/build-workflow.sh --json "{ARGS}"
  ps: scripts/powershell/build-workflow.ps1 -Json "{ARGS}"
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

The `/sp.build` command allows you to build and package Command Workflows locally for testing and distribution. This is particularly useful for:

1. **Local Testing**: Build packages to test your custom commands before contributing
2. **Validation**: Verify that your command templates and scripts are correctly structured
3. **Distribution**: Create release packages for specific AI agents and script types
4. **Development**: Quickly rebuild packages during command development

## Usage Patterns

### Basic Build (All Agents, Both Script Types)
```
/sp.build
```
Builds packages for all supported AI agents with both bash and PowerShell scripts.

### Build for Specific Agent
```
/sp.build --agent claude
/sp.build --agent gemini
```
Builds packages only for the specified agent.

### Build for Specific Script Type
```
/sp.build --script sh       # Bash only
/sp.build --script ps       # PowerShell only
```

### Combined Options
```
/sp.build --agent claude --script sh
/sp.build --agent gemini --script ps --version v1.0.0-test
```

### Custom Version
```
/sp.build --version v0.5.0-dev
```
Specify a custom version string (default: dev).

## Supported Agents

The following AI agents are supported:
- `claude` - Claude Code
- `gemini` - Gemini CLI
- `copilot` - GitHub Copilot
- `cursor-agent` - Cursor
- `qwen` - Qwen Code
- `opencode` - opencode
- `windsurf` - Windsurf
- `codex` - Codex CLI
- `kilocode` - Kilo Code
- `auggie` - Auggie CLI
- `codebuddy` - CodeBuddy
- `roo` - Roo Code
- `q` - Amazon Q Developer CLI
- `amp` - AWS Amplify AI

## Script Types

- `sh` - Bash scripts (Linux/macOS)
- `ps` - PowerShell scripts (Windows/cross-platform)

## Execution Flow

1. **Parse Arguments**
   - Extract agent, script type, and version from user input
   - If no arguments provided, use defaults (all agents, both script types, version "dev")
   - Validate agent and script type values

2. **Run Build Script**
   - Execute `{SCRIPT}` with parsed arguments
   - The script will:
     - Create `.genreleases/` directory
     - Build package(s) for specified agent(s) and script type(s)
     - Process command templates and inject scripts
     - Rewrite paths from `/memory/`, `/scripts/`, `/templates/` to `.specify/*`
     - Generate agent-specific rule files
     - Return JSON with build results

3. **Parse Build Output**
   - The script returns JSON with:
     ```json
     {
       "status": "success",
       "packages": [
         {
           "agent": "claude",
           "script": "sh",
           "path": ".genreleases/sdd-claude-package-sh",
           "archive": ".genreleases/spec-kit-template-claude-sh.zip"
         }
       ],
       "version": "dev",
       "output_dir": ".genreleases"
     }
     ```

4. **Display Results**
   - Show summary of built packages
   - Display package locations
   - Provide next steps for testing or distribution

## Important Notes

- **Build Location**: All packages are built in `.genreleases/` directory
- **Clean Build**: Each build cleans the `.genreleases/` directory first
- **Template Validation**: The build process validates command templates
- **Path Rewriting**: Paths are automatically rewritten for user projects
- **Agent Rules**: Agent-specific rule files are generated automatically

## Examples

### Example 1: Quick Local Test Build
```
User: /sp.build --agent claude --script sh

Agent:
1. Parses arguments: agent=claude, script=sh, version=dev
2. Runs: scripts/bash/build-workflow.sh --json --agent claude --script sh --version dev
3. Displays results:

   ✓ Built package: sdd-claude-package-sh
   Location: .genreleases/sdd-claude-package-sh
   Archive: .genreleases/spec-kit-template-claude-sh.zip

   To test this package:
   1. Copy to your test project: cp -r .genreleases/sdd-claude-package-sh/. ../test-project/
   2. Test your commands: /sp.your-command
```

### Example 2: Full Release Build
```
User: /sp.build --version v1.0.0

Agent:
1. Parses arguments: version=v1.0.0 (all agents, all scripts)
2. Runs: scripts/bash/build-workflow.sh --json --version v1.0.0
3. Displays results showing all built packages
```

### Example 3: Development Workflow
```
User: I'm developing a new command and want to test it with Claude

Agent:
1. Suggests: Let me build a test package for Claude
2. Runs: /sp.build --agent claude --script sh --version dev
3. Shows where the package was built
4. Suggests copying it to a test project
```

## Error Handling

- **Invalid Agent**: Show list of supported agents
- **Invalid Script Type**: Show valid options (sh, ps)
- **Build Failures**: Display detailed error messages from build script
- **Missing Templates**: Warn about missing command templates or scripts

## Related Commands

- `/sp.specify` - Create feature specifications
- `/sp.plan` - Plan implementation
- `/sp.implement` - Implement features
- `/sp.git.commit_pr` - Commit and create PR

## Tips for Contributors

When contributing new commands:

1. **Develop Locally First**
   ```bash
   # Create test project
   specifyplus init test-project --ai claude
   cd test-project
   # Develop in .specify/templates/commands/
   ```

2. **Build for Testing**
   ```bash
   # In spec-kit-plus repo
   /sp.build --agent claude --script sh --version test
   ```

3. **Copy to Test Project**
   ```bash
   cp -r .genreleases/sdd-claude-package-sh/. ../test-project/
   ```

4. **Test Your Command**
   ```bash
   # In test project
   /sp.your-command test-arguments
   ```

5. **Iterate**
   - Make changes to templates/commands/
   - Rebuild: /sp.build --agent claude --script sh
   - Copy and test again

## Implementation Details

### What the Build Script Does

1. **Creates Output Directory**
   - Creates `.genreleases/` directory
   - Cleans previous builds

2. **Processes Templates**
   - Reads command templates from `templates/commands/`
   - Extracts YAML frontmatter (description, scripts)
   - Replaces placeholders: `{SCRIPT}`, `{ARGS}`, `__AGENT__`
   - Injects `memory/command-rules.md` for universal behavior

3. **Copies Resources**
   - Copies `memory/` directory to `.specify/memory/`
   - Copies appropriate script directory (`bash/` or `powershell/`)
   - Copies template files to `.specify/templates/`

4. **Rewrites Paths**
   - Changes `/memory/` to `.specify/memory/`
   - Changes `/scripts/` to `.specify/scripts/`
   - Changes `/templates/` to `.specify/templates/`

5. **Generates Agent Files**
   - Creates agent-specific rule files (CLAUDE.md, GEMINI.md, etc.)
   - Uses content from `protocol-templates/AGENTS.md`

6. **Creates Archives** (Optional)
   - Generates ZIP files for distribution
   - Names: `spec-kit-template-{agent}-{script}.zip`

### Version Format

- Must start with 'v' followed by semantic version: `v0.0.0`
- Examples: `v1.0.0`, `v0.5.0-beta`, `v2.1.3-dev`
- Special value: `dev` for development builds

## Command Arguments Reference

The script accepts the following arguments:

- `--agent <name>` : Build for specific agent (default: all)
- `--script <sh|ps>` : Build for specific script type (default: both)
- `--version <ver>` : Version string (default: dev)
- `--output <dir>` : Output directory (default: .genreleases)
- `--json` : Return JSON output (used by command template)

## Success Criteria

A successful build should:
- ✓ Create packages in `.genreleases/` directory
- ✓ Include all command templates with processed content
- ✓ Include appropriate script files (bash or PowerShell)
- ✓ Include memory files (constitution, etc.)
- ✓ Include template files
- ✓ Generate agent-specific rule files
- ✓ Rewrite all paths correctly
- ✓ Return valid JSON output with package details

---

**Now, execute the build workflow:**

1. Parse the user's arguments from `$ARGUMENTS` (if provided)
2. Extract `--agent`, `--script`, and `--version` flags
3. Run `{SCRIPT}` with appropriate parameters
4. Parse the JSON output
5. Display a friendly summary of the build results
6. Provide guidance on next steps (testing, distribution, etc.)

**Remember**:
- If user provided no arguments, build for all agents and both script types
- Always validate agent and script type values
- Show clear, helpful error messages if build fails
- Provide actionable next steps after successful build
