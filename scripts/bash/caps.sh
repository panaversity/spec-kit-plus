#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# CAPS Compiler - Coding Agent Playbook Spec
# =============================================================================
#
# A vendor-neutral compiler for AI coding agent playbooks.
# Write once in CAPS format, compile to Claude Code Skills and Goose Recipes.
#
# Usage:
#   caps.sh compile <playbook-dir> [--target claude|goose|all] [--output <dir>]
#   caps.sh validate <playbook-dir>
#   caps.sh new <playbook-name> [--output <dir>]
#   caps.sh help
#
# Playbook Structure:
#   playbooks/<name>/
#   ├── playbook.md          # Required: Main CAPS file with YAML frontmatter
#   ├── scripts/             # Optional: Executable scripts
#   ├── references/          # Optional: Documentation files
#   └── templates/           # Optional: Template files
#
# Output:
#   Claude: .claude/skills/<name>/SKILL.md
#   Goose:  .goose/recipes/<name>/recipe.yaml
#
# =============================================================================

# Get script location and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine repo root - handle both dev (scripts/bash/) and installed (.specify/scripts/bash/)
if [[ -d "$SCRIPT_DIR/../../.specify" ]]; then
    # Installed in user project: .specify/scripts/bash/
    REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    TEMPLATE_DIR="$REPO_ROOT/.specify/templates/caps"
else
    # Development: scripts/bash/
    REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    TEMPLATE_DIR="$REPO_ROOT/templates/caps"
fi

# =============================================================================
# YAML Parsing Functions (Pure Bash/Awk)
# =============================================================================

# Extract YAML frontmatter from markdown file (content between --- markers)
extract_frontmatter() {
    local file="$1"
    awk '
        /^---[[:space:]]*$/ {
            if (in_frontmatter) { exit }
            in_frontmatter = 1
            next
        }
        in_frontmatter { print }
    ' "$file"
}

# Extract markdown body (everything after the second ---)
extract_body() {
    local file="$1"
    awk '
        /^---[[:space:]]*$/ { count++; next }
        count >= 2 { print }
    ' "$file"
}

# Get simple YAML field value (handles both "key: value" and "key: 'value'")
get_field() {
    local yaml="$1"
    local field="$2"
    echo "$yaml" | awk -v f="$field" '
        BEGIN { FS=": " }
        $1 == f {
            val = $2
            for (i=3; i<=NF; i++) val = val ": " $i  # Handle colons in value
            gsub(/^[[:space:]]*["'"'"']?|["'"'"']?[[:space:]]*$/, "", val)
            print val
            exit
        }
    '
}

# Get multiline YAML field (for "field: |" or "field: >" syntax)
get_multiline_field() {
    local yaml="$1"
    local field="$2"
    echo "$yaml" | awk -v f="$field" '
        $0 ~ "^"f":[[:space:]]*[|>]" {
            capture = 1
            next
        }
        $0 ~ "^"f":[[:space:]]*[^|>]" && $0 !~ "^"f":[[:space:]]*$" {
            sub(/^[^:]+:[[:space:]]*/, "")
            print
            exit
        }
        capture && /^[a-zA-Z_][a-zA-Z0-9_-]*:/ && !/^[[:space:]]/ { exit }
        capture && /^[[:space:]]/ {
            sub(/^[[:space:]][[:space:]]/, "")  # Remove 2-space indent
            print
        }
    '
}

# Get YAML array as newline-separated values
get_array() {
    local yaml="$1"
    local field="$2"
    echo "$yaml" | awk -v f="$field" '
        $0 ~ "^"f":[[:space:]]*$" { capture = 1; next }
        $0 ~ "^"f":[[:space:]]*\\[" {
            # Inline array: [item1, item2]
            match($0, /\[.*\]/)
            arr = substr($0, RSTART+1, RLENGTH-2)
            n = split(arr, items, /,[[:space:]]*/)
            for (i=1; i<=n; i++) {
                gsub(/^[[:space:]]*["'"'"']?|["'"'"']?[[:space:]]*$/, "", items[i])
                if (items[i] != "") print items[i]
            }
            exit
        }
        capture && /^[a-zA-Z_][a-zA-Z0-9_-]*:/ && !/^[[:space:]]/ { exit }
        capture && /^[[:space:]]*-[[:space:]]/ {
            sub(/^[[:space:]]*-[[:space:]]*/, "")
            gsub(/^["'"'"']|["'"'"']$/, "")
            print
        }
    '
}

# Get complex YAML block (extensions, parameters, settings, references)
# Returns the entire block including the field name for pass-through
get_yaml_block() {
    local yaml="$1"
    local field="$2"
    echo "$yaml" | awk -v f="$field" '
        $0 ~ "^"f":" {
            capture = 1
            print
            next
        }
        capture && /^[a-zA-Z_][a-zA-Z0-9_-]*:/ && !/^[[:space:]]/ { exit }
        capture { print }
    '
}

# Get complex YAML block content only (without the field name line)
get_yaml_block_content() {
    local yaml="$1"
    local field="$2"
    echo "$yaml" | awk -v f="$field" '
        $0 ~ "^"f":" {
            capture = 1
            next
        }
        capture && /^[a-zA-Z_][a-zA-Z0-9_-]*:/ && !/^[[:space:]]/ { exit }
        capture { print }
    '
}

# =============================================================================
# Validation Functions
# =============================================================================

# Validate playbook name format (lowercase alphanumeric with hyphens)
validate_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
        return 1
    fi
    if [[ ${#name} -gt 64 ]]; then
        return 1
    fi
    return 0
}

# Slugify a string (convert to lowercase, replace non-alphanumeric with hyphens)
slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//' | sed 's/-$//'
}

# Title case a hyphenated string
titlecase() {
    echo "$1" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1'
}

# =============================================================================
# Claude Code Skill Generator
# =============================================================================

generate_claude_skill() {
    local playbook_dir="$1"
    local output_dir="$2"
    local playbook_file="$playbook_dir/playbook.md"

    # Parse playbook
    local frontmatter body name description license allowed_tools
    frontmatter=$(extract_frontmatter "$playbook_file")
    body=$(extract_body "$playbook_file")

    name=$(get_field "$frontmatter" "name")
    description=$(get_multiline_field "$frontmatter" "description")
    [[ -z "$description" ]] && description=$(get_field "$frontmatter" "description")
    license=$(get_field "$frontmatter" "license")

    # Create skill directory
    local skill_dir="$output_dir/.claude/skills/$name"
    mkdir -p "$skill_dir"

    # Get references for Related Skills section
    local references
    references=$(get_array "$frontmatter" "references")

    # Check for commands and agents directories
    local has_commands=false
    local has_agents=false
    [[ -d "$playbook_dir/commands" ]] && has_commands=true
    [[ -d "$playbook_dir/agents" ]] && has_agents=true

    # Generate SKILL.md
    {
        echo "---"
        echo "name: $name"

        # Handle multiline description
        if [[ "$description" == *$'\n'* ]]; then
            echo "description: |"
            echo "$description" | sed 's/^/  /'
        else
            echo "description: $description"
        fi

        [[ -n "$license" ]] && echo "license: $license"

        # Add allowed-tools if present
        local tools
        tools=$(get_array "$frontmatter" "allowed_tools")
        if [[ -n "$tools" ]]; then
            echo "allowed-tools:"
            echo "$tools" | while read -r tool; do
                [[ -n "$tool" ]] && echo "- $tool"
            done
        fi

        echo "---"
        echo ""
        echo "$body"

        # Add Related Skills section if references exist
        if [[ -n "$references" ]]; then
            echo ""
            echo "## Related Skills"
            echo ""
            echo "This skill works with the following skills (invoke as needed):"
            echo ""
            echo "$references" | while read -r ref; do
                if [[ -n "$ref" ]]; then
                    local ref_name
                    ref_name=$(basename "$ref")
                    echo "- **$ref_name** - See [\`.claude/skills/$ref_name/SKILL.md\`](../$ref_name/SKILL.md)"
                fi
            done
        fi

        # Add Commands section if commands/ directory exists
        if [[ "$has_commands" == true ]]; then
            echo ""
            echo "## Commands"
            echo ""
            echo "This skill includes slash commands:"
            echo ""
            for cmd_file in "$playbook_dir/commands"/*.md; do
                [[ -f "$cmd_file" ]] || continue
                local cmd_name cmd_desc namespaced_cmd
                cmd_name=$(basename "$cmd_file" .md)
                namespaced_cmd="${name}-${cmd_name}"
                # Extract description from command frontmatter
                cmd_desc=$(extract_frontmatter "$cmd_file" | get_field "$(cat)" "description" 2>/dev/null || echo "")
                if [[ -z "$cmd_desc" ]]; then
                    cmd_desc=$(awk '/^description:/ {sub(/^description:[[:space:]]*/, ""); print; exit}' "$cmd_file")
                fi
                echo "- \`/$namespaced_cmd\` - $cmd_desc"
            done
        fi

        # Add Agents section if agents/ directory exists
        if [[ "$has_agents" == true ]]; then
            echo ""
            echo "## Subagents"
            echo ""
            echo "This skill includes specialized agents in \`agents/\` directory:"
            echo ""
            for agent_file in "$playbook_dir/agents"/*.md; do
                [[ -f "$agent_file" ]] || continue
                local agent_name agent_desc namespaced_agent
                agent_name=$(basename "$agent_file" .md)
                namespaced_agent="${name}-${agent_name}"
                # Extract description from agent frontmatter
                agent_desc=$(awk '/^description:/ {sub(/^description:[[:space:]]*/, ""); print; exit}' "$agent_file")
                echo "- **$namespaced_agent** - $agent_desc"
            done
            echo ""
            echo "### Invoking Subagents"
            echo ""
            echo "**Claude Code**: Use the Task tool with the agent name."
            echo ""
            echo "**Other agents**: Spawn yourself with the agent's prompt:"
            echo ""
            echo '```bash'
            echo "# Read agent prompt and invoke"
            echo 'AGENT_PROMPT=\$(cat agents/<agent-name>.md)'
            echo 'claude --print "\$AGENT_PROMPT" "Your task here"'
            echo "# Or for Goose:"
            echo 'goose run --instructions "\$AGENT_PROMPT"'
            echo '```'
        fi

    } > "$skill_dir/SKILL.md"

    # Copy supporting directories to skill
    [[ -d "$playbook_dir/scripts" ]] && cp -r "$playbook_dir/scripts" "$skill_dir/"
    [[ -d "$playbook_dir/references" ]] && cp -r "$playbook_dir/references" "$skill_dir/"
    [[ -d "$playbook_dir/templates" ]] && cp -r "$playbook_dir/templates" "$skill_dir/"

    # Bundle agents in skill directory (for all agents to use)
    if [[ "$has_agents" == true ]]; then
        mkdir -p "$skill_dir/agents"
        cp -r "$playbook_dir/agents"/*.md "$skill_dir/agents/" 2>/dev/null || true
    fi

    # Copy commands to .claude/commands/ with namespace prefix (Claude native)
    if [[ "$has_commands" == true ]]; then
        mkdir -p "$output_dir/.claude/commands"
        for cmd_file in "$playbook_dir/commands"/*.md; do
            [[ -f "$cmd_file" ]] || continue
            local cmd_name
            cmd_name=$(basename "$cmd_file" .md)
            # Namespace: <playbook>-<command>.md
            cp "$cmd_file" "$output_dir/.claude/commands/${name}-${cmd_name}.md"
        done
    fi

    # Copy agents to .claude/agents/ with namespace prefix (Claude native)
    if [[ "$has_agents" == true ]]; then
        mkdir -p "$output_dir/.claude/agents"
        for agent_file in "$playbook_dir/agents"/*.md; do
            [[ -f "$agent_file" ]] || continue
            local agent_name
            agent_name=$(basename "$agent_file" .md)
            # Namespace: <playbook>-<agent>.md
            cp "$agent_file" "$output_dir/.claude/agents/${name}-${agent_name}.md"
        done
    fi

    echo "$skill_dir"
}

# =============================================================================
# Goose Recipe Generator
# =============================================================================

generate_goose_recipe() {
    local playbook_dir="$1"
    local output_dir="$2"
    local playbook_file="$playbook_dir/playbook.md"

    # Parse playbook
    local frontmatter body name title description version
    frontmatter=$(extract_frontmatter "$playbook_file")
    body=$(extract_body "$playbook_file")

    name=$(get_field "$frontmatter" "name")
    title=$(get_field "$frontmatter" "title")
    description=$(get_multiline_field "$frontmatter" "description")
    [[ -z "$description" ]] && description=$(get_field "$frontmatter" "description")
    version=$(get_field "$frontmatter" "version")
    [[ -z "$version" ]] && version="1.0.0"

    # Create recipe directory
    local recipe_dir="$output_dir/.goose/recipes/$name"
    mkdir -p "$recipe_dir"

    # Get references for sub_recipes
    local references
    references=$(get_array "$frontmatter" "references")

    # Check for agents directory
    local has_agents=false
    [[ -d "$playbook_dir/agents" ]] && has_agents=true

    # Generate recipe.yaml
    {
        echo "version: $version"
        echo "title: $title"

        # Handle multiline description
        if [[ "$description" == *$'\n'* ]]; then
            echo "description: |-"
            echo "$description" | sed 's/^/  /'
        else
            echo "description: $description"
        fi

        # Instructions (the markdown body)
        echo "instructions: |-"
        echo "$body" | sed 's/^/  /'

        # Parameters (pass through)
        local parameters
        parameters=$(get_yaml_block "$frontmatter" "parameters")
        [[ -n "$parameters" ]] && echo "$parameters"

        # Extensions (pass through)
        local extensions
        extensions=$(get_yaml_block "$frontmatter" "extensions")
        [[ -n "$extensions" ]] && echo "$extensions"

        # Sub-recipes from references (recursive composition)
        if [[ -n "$references" ]]; then
            echo "sub_recipes:"
            echo "$references" | while read -r ref; do
                if [[ -n "$ref" ]]; then
                    # Extract recipe name from path (e.g., playbooks/docker-build -> docker-build)
                    local ref_name
                    ref_name=$(basename "$ref")
                    echo "  - name: $ref_name"
                    echo "    path: \"{{ recipe_dir }}/../$ref_name/recipe.yaml\""
                fi
            done
        fi

        # Activities (pass through)
        local activities
        activities=$(get_yaml_block "$frontmatter" "activities")
        [[ -n "$activities" ]] && echo "$activities"

        # Settings (pass through)
        local settings
        settings=$(get_yaml_block "$frontmatter" "settings")
        [[ -n "$settings" ]] && echo "$settings"

    } > "$recipe_dir/recipe.yaml"

    # Copy supporting directories
    [[ -d "$playbook_dir/scripts" ]] && cp -r "$playbook_dir/scripts" "$recipe_dir/"
    [[ -d "$playbook_dir/references" ]] && cp -r "$playbook_dir/references" "$recipe_dir/"
    [[ -d "$playbook_dir/templates" ]] && cp -r "$playbook_dir/templates" "$recipe_dir/"

    # Bundle agents in recipe directory with invocation instructions
    if [[ "$has_agents" == true ]]; then
        mkdir -p "$recipe_dir/agents"
        cp -r "$playbook_dir/agents"/*.md "$recipe_dir/agents/" 2>/dev/null || true

        # Create agents README with invocation instructions
        {
            echo "# Subagents"
            echo ""
            echo "This recipe includes specialized agents that can be invoked via shell:"
            echo ""
            for agent_file in "$playbook_dir/agents"/*.md; do
                [[ -f "$agent_file" ]] || continue
                local agent_name agent_desc
                agent_name=$(basename "$agent_file" .md)
                agent_desc=$(awk '/^description:/ {sub(/^description:[[:space:]]*/, ""); print; exit}' "$agent_file")
                echo "- **$agent_name** - $agent_desc"
            done
            echo ""
            echo "## Invocation"
            echo ""
            echo '```bash'
            echo '# Read agent prompt and spawn Goose with it'
            echo 'AGENT_PROMPT=$(cat agents/<agent-name>.md)'
            echo 'goose run --instructions "$AGENT_PROMPT"'
            echo '```'
        } > "$recipe_dir/agents/README.md"
    fi

    echo "$recipe_dir"
}

# =============================================================================
# Codex Skill Generator (OpenAI Codex CLI)
# =============================================================================

generate_codex_skill() {
    local playbook_dir="$1"
    local output_dir="$2"
    local playbook_file="$playbook_dir/playbook.md"

    # Parse playbook
    local frontmatter body name description
    frontmatter=$(extract_frontmatter "$playbook_file")
    body=$(extract_body "$playbook_file")

    name=$(get_field "$frontmatter" "name")
    description=$(get_multiline_field "$frontmatter" "description")
    [[ -z "$description" ]] && description=$(get_field "$frontmatter" "description")

    # Create skill directory
    local skill_dir="$output_dir/.codex/skills/$name"
    mkdir -p "$skill_dir"

    # Get references for Related Skills section
    local references
    references=$(get_array "$frontmatter" "references")

    # Check for commands and agents directories
    local has_commands=false
    local has_agents=false
    [[ -d "$playbook_dir/commands" ]] && has_commands=true
    [[ -d "$playbook_dir/agents" ]] && has_agents=true

    # Generate SKILL.md (Codex format - simpler, no allowed-tools)
    {
        echo "---"
        echo "name: $name"

        # Handle multiline description (Codex wants single line, max 500 chars)
        local desc_oneline
        desc_oneline=$(echo "$description" | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-500)
        echo "description: $desc_oneline"

        echo "---"
        echo ""
        echo "$body"

        # Add Related Skills section if references exist
        if [[ -n "$references" ]]; then
            echo ""
            echo "## Related Skills"
            echo ""
            echo "This skill works with the following skills (invoke via \$skill-name):"
            echo ""
            echo "$references" | while read -r ref; do
                if [[ -n "$ref" ]]; then
                    local ref_name
                    ref_name=$(basename "$ref")
                    echo "- **\$$ref_name**"
                fi
            done
        fi

        # Add Commands section if commands/ directory exists
        if [[ "$has_commands" == true ]]; then
            echo ""
            echo "## Commands"
            echo ""
            echo "This skill includes command workflows in \`commands/\` directory:"
            echo ""
            for cmd_file in "$playbook_dir/commands"/*.md; do
                [[ -f "$cmd_file" ]] || continue
                local cmd_name cmd_desc
                cmd_name=$(basename "$cmd_file" .md)
                cmd_desc=$(awk '/^description:/ {sub(/^description:[[:space:]]*/, ""); print; exit}' "$cmd_file")
                echo "- **$cmd_name** - $cmd_desc"
            done
        fi

        # Add Agents section if agents/ directory exists
        if [[ "$has_agents" == true ]]; then
            echo ""
            echo "## Subagents"
            echo ""
            echo "This skill includes specialized agents in \`agents/\` directory:"
            echo ""
            for agent_file in "$playbook_dir/agents"/*.md; do
                [[ -f "$agent_file" ]] || continue
                local agent_name agent_desc
                agent_name=$(basename "$agent_file" .md)
                agent_desc=$(awk '/^description:/ {sub(/^description:[[:space:]]*/, ""); print; exit}' "$agent_file")
                echo "- **$agent_name** - $agent_desc"
            done
            echo ""
            echo "### Invoking Subagents"
            echo ""
            echo "Spawn yourself with the agent's prompt:"
            echo ""
            echo '```bash'
            echo 'AGENT_PROMPT=$(cat agents/<agent-name>.md)'
            echo 'codex --prompt "$AGENT_PROMPT"'
            echo '```'
        fi

    } > "$skill_dir/SKILL.md"

    # Copy supporting directories to skill
    [[ -d "$playbook_dir/scripts" ]] && cp -r "$playbook_dir/scripts" "$skill_dir/"
    [[ -d "$playbook_dir/references" ]] && cp -r "$playbook_dir/references" "$skill_dir/"
    [[ -d "$playbook_dir/templates" ]] && cp -r "$playbook_dir/templates" "$skill_dir/"

    # Bundle commands in skill directory
    if [[ "$has_commands" == true ]]; then
        mkdir -p "$skill_dir/commands"
        cp -r "$playbook_dir/commands"/*.md "$skill_dir/commands/" 2>/dev/null || true
    fi

    # Bundle agents in skill directory
    if [[ "$has_agents" == true ]]; then
        mkdir -p "$skill_dir/agents"
        cp -r "$playbook_dir/agents"/*.md "$skill_dir/agents/" 2>/dev/null || true
    fi

    echo "$skill_dir"
}

# =============================================================================
# Command Implementations
# =============================================================================

# Compile a single playbook (internal function)
compile_single_playbook() {
    local playbook_dir="$1"
    local output_dir="$2"
    local target="$3"
    local dry_run="$4"

    local playbook_file="$playbook_dir/playbook.md"

    # Parse and validate
    local frontmatter name title
    frontmatter=$(extract_frontmatter "$playbook_file")
    name=$(get_field "$frontmatter" "name")
    title=$(get_field "$frontmatter" "title")

    if [[ -z "$name" ]]; then
        echo "Error: Missing required field 'name' in $playbook_file" >&2
        return 1
    fi

    if ! validate_name "$name"; then
        echo "Error: Invalid name '$name' - must be lowercase alphanumeric with hyphens" >&2
        return 1
    fi

    echo ""
    echo "Parsing playbook: $playbook_dir"
    echo "  Name: $name"
    echo "  Title: $title"

    # Count files
    local script_count=0 ref_count=0
    [[ -d "$playbook_dir/scripts" ]] && script_count=$(find "$playbook_dir/scripts" -type f | wc -l | tr -d ' ')
    [[ -d "$playbook_dir/references" ]] && ref_count=$(find "$playbook_dir/references" -type f | wc -l | tr -d ' ')

    echo "  Scripts: $script_count"
    echo "  References: $ref_count"

    if [[ "$dry_run" == true ]]; then
        echo ""
        echo "[DRY-RUN] Would generate:"
        [[ "$target" == "claude" || "$target" == "all" ]] && echo "  - $output_dir/.claude/skills/$name/SKILL.md"
        [[ "$target" == "goose" || "$target" == "all" ]] && echo "  - $output_dir/.goose/recipes/$name/recipe.yaml"
        [[ "$target" == "codex" || "$target" == "all" ]] && echo "  - $output_dir/.codex/skills/$name/SKILL.md"
        return 0
    fi

    # Compile
    if [[ "$target" == "claude" || "$target" == "all" ]]; then
        echo ""
        echo "Compiling to Claude Code Skill..."
        local skill_dir
        skill_dir=$(generate_claude_skill "$playbook_dir" "$output_dir")
        echo "  Created: $skill_dir"
    fi

    if [[ "$target" == "goose" || "$target" == "all" ]]; then
        echo ""
        echo "Compiling to Goose Recipe..."
        local recipe_dir
        recipe_dir=$(generate_goose_recipe "$playbook_dir" "$output_dir")
        echo "  Created: $recipe_dir"
    fi

    if [[ "$target" == "codex" || "$target" == "all" ]]; then
        echo ""
        echo "Compiling to Codex Skill..."
        local codex_dir
        codex_dir=$(generate_codex_skill "$playbook_dir" "$output_dir")
        echo "  Created: $codex_dir"
    fi
}

cmd_compile() {
    local playbook_dir=""
    local target="all"
    local output_dir="."
    local dry_run=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target|-t)
                target="${2:-all}"
                shift 2
                ;;
            --output|-o)
                output_dir="${2:-.}"
                shift 2
                ;;
            --dry-run|-n)
                dry_run=true
                shift
                ;;
            --help|-h)
                echo "Usage: caps.sh compile <playbook-dir|playbooks-folder> [options]"
                echo ""
                echo "Compile CAPS playbook(s) to agent-specific formats."
                echo ""
                echo "Arguments:"
                echo "  <playbook-dir>       Single playbook directory (contains playbook.md)"
                echo "  <playbooks-folder>   Directory containing multiple playbooks (batch mode)"
                echo ""
                echo "Options:"
                echo "  --target, -t   Target format: claude, goose, codex, or all (default: all)"
                echo "  --output, -o   Output directory (default: current directory)"
                echo "  --dry-run, -n  Show what would be generated without writing files"
                exit 0
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                exit 1
                ;;
            *)
                [[ -z "$playbook_dir" ]] && playbook_dir="$1"
                shift
                ;;
        esac
    done

    # Validate
    if [[ -z "$playbook_dir" ]]; then
        echo "Error: Playbook directory is required" >&2
        echo "Usage: caps.sh compile <playbook-dir> [--target claude|goose|all]" >&2
        exit 1
    fi

    # Check if this is a single playbook or a directory of playbooks
    if [[ -f "$playbook_dir/playbook.md" ]]; then
        # Single playbook
        compile_single_playbook "$playbook_dir" "$output_dir" "$target" "$dry_run"
    elif [[ -d "$playbook_dir" ]]; then
        # Batch mode: find all playbooks in directory
        local playbook_count=0
        local success_count=0
        local fail_count=0

        echo ""
        echo "Batch compiling playbooks in: $playbook_dir"
        [[ "$dry_run" == true ]] && echo "[DRY-RUN MODE]"

        for subdir in "$playbook_dir"/*/; do
            [[ -d "$subdir" ]] || continue
            if [[ -f "$subdir/playbook.md" ]]; then
                ((playbook_count++))
                if compile_single_playbook "$subdir" "$output_dir" "$target" "$dry_run"; then
                    ((success_count++))
                else
                    ((fail_count++))
                fi
            fi
        done

        echo ""
        echo "========================================"
        echo "Batch Compilation Summary"
        echo "========================================"
        echo "Total playbooks: $playbook_count"
        echo "Successful: $success_count"
        echo "Failed: $fail_count"

        [[ $fail_count -gt 0 ]] && exit 1
    else
        echo "Error: '$playbook_dir' is not a valid playbook directory" >&2
        echo "Expected: directory containing playbook.md OR directory containing playbook subdirectories" >&2
        exit 1
    fi

    echo ""
    echo "Compilation complete!"
    echo ""
}

cmd_validate() {
    local playbook_dir=""
    local check_refs=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --check-references|--check-refs)
                check_refs=true
                shift
                ;;
            --help|-h)
                echo "Usage: caps.sh validate <playbook-dir> [--check-references]"
                echo ""
                echo "Validate a CAPS playbook without compiling."
                echo ""
                echo "Options:"
                echo "  --check-references   Verify that referenced playbooks exist"
                exit 0
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                exit 1
                ;;
            *)
                [[ -z "$playbook_dir" ]] && playbook_dir="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$playbook_dir" ]]; then
        echo "Error: Playbook directory is required" >&2
        echo "Usage: caps.sh validate <playbook-dir>" >&2
        exit 1
    fi

    local playbook_file="$playbook_dir/playbook.md"
    if [[ ! -f "$playbook_file" ]]; then
        echo "Error: playbook.md not found in $playbook_dir" >&2
        exit 1
    fi

    echo ""
    echo "Validating playbook: $playbook_dir"
    echo ""

    local frontmatter errors=0 warnings=0
    frontmatter=$(extract_frontmatter "$playbook_file")

    # Check required fields
    local name title description
    name=$(get_field "$frontmatter" "name")
    title=$(get_field "$frontmatter" "title")
    description=$(get_multiline_field "$frontmatter" "description")
    [[ -z "$description" ]] && description=$(get_field "$frontmatter" "description")

    printf "%-20s " "Name:"
    if [[ -n "$name" ]]; then
        echo "[PASS] $name"
    else
        echo "[FAIL] Missing required field"
        ((errors++))
    fi

    printf "%-20s " "Title:"
    if [[ -n "$title" ]]; then
        echo "[PASS] $title"
    else
        echo "[FAIL] Missing required field"
        ((errors++))
    fi

    printf "%-20s " "Description:"
    if [[ -n "$description" ]]; then
        local desc_preview="${description:0:50}"
        [[ ${#description} -gt 50 ]] && desc_preview="$desc_preview..."
        echo "[PASS] $desc_preview"
    else
        echo "[FAIL] Missing required field"
        ((errors++))
    fi

    printf "%-20s " "Name Format:"
    if validate_name "$name"; then
        echo "[PASS] Valid lowercase-hyphen format"
    else
        echo "[FAIL] Must be lowercase alphanumeric with hyphens"
        ((errors++))
    fi

    printf "%-20s " "Directory Match:"
    local dir_name
    dir_name=$(basename "$playbook_dir")
    if [[ "$name" == "$dir_name" ]]; then
        echo "[PASS] Name matches directory"
    else
        echo "[WARN] Name '$name' != directory '$dir_name'"
        ((warnings++))
    fi

    # File inventory
    local script_count=0 ref_count=0
    [[ -d "$playbook_dir/scripts" ]] && script_count=$(find "$playbook_dir/scripts" -type f | wc -l | tr -d ' ')
    [[ -d "$playbook_dir/references" ]] && ref_count=$(find "$playbook_dir/references" -type f | wc -l | tr -d ' ')

    printf "%-20s [INFO] %s files\n" "Scripts:" "$script_count"
    printf "%-20s [INFO] %s files\n" "References:" "$ref_count"

    # Check playbook references if --check-references flag is set
    local references
    references=$(get_array "$frontmatter" "references")
    if [[ -n "$references" ]]; then
        local ref_playbook_count=0
        ref_playbook_count=$(echo "$references" | grep -c . || true)
        printf "%-20s [INFO] %s playbooks\n" "Playbook Refs:" "$ref_playbook_count"

        if [[ "$check_refs" == true ]]; then
            echo ""
            echo "Checking referenced playbooks:"
            echo "$references" | while read -r ref; do
                if [[ -n "$ref" ]]; then
                    local ref_name ref_path
                    ref_name=$(basename "$ref")
                    # Try to find the referenced playbook relative to current playbook
                    ref_path="$(dirname "$playbook_dir")/$ref_name/playbook.md"
                    # Also try the exact path if it looks absolute-ish
                    [[ ! -f "$ref_path" ]] && ref_path="$ref/playbook.md"

                    printf "  %-18s " "$ref_name:"
                    if [[ -f "$ref_path" ]]; then
                        echo "[PASS] Found"
                    else
                        echo "[FAIL] Not found at $ref_path"
                        # Note: can't increment errors here due to subshell
                        echo "REFCHECK_FAIL" >> /tmp/caps_refcheck_$$
                    fi
                fi
            done
            # Check for reference failures
            if [[ -f /tmp/caps_refcheck_$$ ]]; then
                local ref_errors
                ref_errors=$(wc -l < /tmp/caps_refcheck_$$ | tr -d ' ')
                rm -f /tmp/caps_refcheck_$$
                errors=$((errors + ref_errors))
            fi
        fi
    fi

    echo ""
    if [[ $errors -eq 0 ]]; then
        if [[ $warnings -gt 0 ]]; then
            echo "Validation complete with $warnings warning(s)."
        else
            echo "Validation complete! No errors found."
        fi
    else
        echo "Validation failed with $errors error(s)."
        exit 1
    fi
    echo ""
}

cmd_new() {
    local name=""
    local output_dir=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output|-o)
                output_dir="${2:-}"
                shift 2
                ;;
            --help|-h)
                echo "Usage: caps.sh new <playbook-name> [--output <dir>]"
                echo ""
                echo "Create a new CAPS playbook from template."
                echo ""
                echo "Options:"
                echo "  --output, -o   Output directory (default: playbooks/)"
                exit 0
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                exit 1
                ;;
            *)
                [[ -z "$name" ]] && name="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$name" ]]; then
        echo "Error: Playbook name is required" >&2
        echo "Usage: caps.sh new <playbook-name> [--output <dir>]" >&2
        exit 1
    fi

    # Slugify the name
    local slug
    slug=$(slugify "$name")
    if [[ "$slug" != "$name" ]]; then
        echo "Note: Normalized name to: $slug"
    fi

    # Determine output directory
    if [[ -z "$output_dir" ]]; then
        # Try to find playbooks directory
        if [[ -d "playbooks" ]]; then
            output_dir="playbooks"
        else
            output_dir="."
        fi
    fi

    local playbook_dir="$output_dir/$slug"

    if [[ -d "$playbook_dir" ]]; then
        echo "Error: Playbook directory already exists: $playbook_dir" >&2
        exit 1
    fi

    # Find template
    if [[ ! -d "$TEMPLATE_DIR" ]]; then
        echo "Error: CAPS template directory not found at $TEMPLATE_DIR" >&2
        exit 1
    fi

    local template_file="$TEMPLATE_DIR/playbook-template.md"
    if [[ ! -f "$template_file" ]]; then
        echo "Error: Playbook template not found: $template_file" >&2
        exit 1
    fi

    # Create playbook directory structure
    mkdir -p "$playbook_dir"
    mkdir -p "$playbook_dir/scripts"
    mkdir -p "$playbook_dir/references"
    mkdir -p "$playbook_dir/commands"
    mkdir -p "$playbook_dir/agents"

    # Generate title from slug
    local title
    title=$(titlecase "$slug")

    # Copy and process template
    sed -e "s/{{PLAYBOOK_NAME}}/$slug/g" \
        -e "s/{{PLAYBOOK_TITLE}}/$title/g" \
        -e "s/{{PLAYBOOK_DESCRIPTION}}/Description of $slug/g" \
        -e "s/{{TRIGGER_PHRASES}}/users request $slug/g" \
        "$template_file" > "$playbook_dir/playbook.md"

    echo ""
    echo "Created new CAPS playbook: $playbook_dir"
    echo ""
    echo "Structure:"
    echo "  $playbook_dir/"
    echo "  ├── playbook.md     # Main skill instructions"
    echo "  ├── commands/       # Slash commands (optional)"
    echo "  ├── agents/         # Subagents (optional)"
    echo "  ├── scripts/        # Helper scripts"
    echo "  └── references/     # Documentation"
    echo ""
    echo "Next steps:"
    echo "  1. Edit $playbook_dir/playbook.md"
    echo "  2. Add commands to commands/, agents to agents/"
    echo "  3. Run: caps.sh compile $playbook_dir --target claude"
    echo ""
}

show_help() {
    cat <<'EOF'
CAPS - Coding Agent Playbook Spec Compiler

Reusable Intelligence Packages for AI coding agents.
Bundle skills + commands + subagents into portable playbooks.

USAGE:
    caps.sh <command> [options]

COMMANDS:
    compile <path>             Compile playbook(s) to agent formats
        --target <target>      Target: claude, goose, codex, or all (default: all)
        --output <dir>         Output directory (default: current)
        --dry-run              Preview without writing files

    validate <playbook-dir>    Validate a CAPS playbook
        --check-references     Verify referenced playbooks exist

    lint <playbook-dir>        Check playbook quality and best practices

    new <playbook-name>        Create a new CAPS playbook from template
        --output <dir>         Output directory (default: playbooks/)

    import <skill-or-recipe>   Convert existing Skill/Recipe to CAPS
        --output <dir>         Output directory (default: playbooks/)

    help                       Show this help message

PLAYBOOK STRUCTURE:
    playbooks/<name>/
    ├── playbook.md            # Required: Main skill (YAML frontmatter + markdown)
    ├── commands/              # Optional: Slash commands (*.md)
    ├── agents/                # Optional: Subagent definitions (*.md)
    ├── scripts/               # Optional: Helper scripts (*.sh, *.py)
    └── references/            # Optional: Documentation (*.md)

OUTPUT:
    Claude (.claude/):
        skills/<name>/SKILL.md     # Skill with bundled agents/
        commands/<name>-<cmd>.md   # Native slash commands
        agents/<name>-<agent>.md   # Native subagents

    Goose (.goose/):
        recipes/<name>/recipe.yaml # Recipe with bundled agents/

    Codex (.codex/):
        skills/<name>/SKILL.md     # Skill with bundled commands/ and agents/

FRONTMATTER FIELDS:
    Required:
        name           Playbook identifier (lowercase-hyphen)
        title          Human-readable title
        description    What + when to use (include trigger phrases)

    Optional:
        version        Semantic version (default: 1.0.0)
        allowed_tools  Restrict available tools [Bash, Read, Write, etc.]
        references     Other playbooks to compose with

EXAMPLES:
    # Create a new playbook
    caps.sh new deploy-workflow

    # Compile to Claude
    caps.sh compile playbooks/deploy-workflow

    # Batch compile all playbooks
    caps.sh compile playbooks/ --dry-run

    # Import existing skill
    caps.sh import .claude/skills/pdf

EOF
}

# =============================================================================
# Import Command - Convert Claude Skills or Goose Recipes to CAPS
# =============================================================================

cmd_import() {
    local source_dir=""
    local output_dir=""
    local source_type=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output|-o)
                output_dir="${2:-}"
                shift 2
                ;;
            --type|-t)
                source_type="${2:-}"
                shift 2
                ;;
            --help|-h)
                echo "Usage: caps.sh import <skill-or-recipe-dir> [--output <dir>] [--type claude|goose]"
                echo ""
                echo "Import an existing Claude Code Skill or Goose Recipe to CAPS format."
                echo ""
                echo "Options:"
                echo "  --output, -o   Output directory (default: playbooks/)"
                echo "  --type, -t     Source type: claude or goose (auto-detected if not specified)"
                exit 0
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                exit 1
                ;;
            *)
                [[ -z "$source_dir" ]] && source_dir="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$source_dir" ]]; then
        echo "Error: Source directory is required" >&2
        echo "Usage: caps.sh import <skill-or-recipe-dir> [--output <dir>]" >&2
        exit 1
    fi

    # Auto-detect source type
    if [[ -z "$source_type" ]]; then
        if [[ -f "$source_dir/SKILL.md" ]]; then
            source_type="claude"
        elif [[ -f "$source_dir/recipe.yaml" ]]; then
            source_type="goose"
        else
            echo "Error: Cannot detect source type. No SKILL.md or recipe.yaml found." >&2
            exit 1
        fi
    fi

    # Set default output directory
    if [[ -z "$output_dir" ]]; then
        if [[ -d "playbooks" ]]; then
            output_dir="playbooks"
        else
            output_dir="."
        fi
    fi

    echo ""
    echo "Importing from: $source_dir"
    echo "Source type: $source_type"

    case "$source_type" in
        claude)
            import_claude_skill "$source_dir" "$output_dir"
            ;;
        goose)
            import_goose_recipe "$source_dir" "$output_dir"
            ;;
        *)
            echo "Error: Unknown source type: $source_type" >&2
            exit 1
            ;;
    esac
}

# Import Claude Code Skill to CAPS Playbook
import_claude_skill() {
    local skill_dir="$1"
    local output_dir="$2"
    local skill_file="$skill_dir/SKILL.md"

    if [[ ! -f "$skill_file" ]]; then
        echo "Error: SKILL.md not found in $skill_dir" >&2
        exit 1
    fi

    # Parse skill
    local frontmatter body name description license
    frontmatter=$(extract_frontmatter "$skill_file")
    body=$(extract_body "$skill_file")

    name=$(get_field "$frontmatter" "name")
    description=$(get_multiline_field "$frontmatter" "description")
    [[ -z "$description" ]] && description=$(get_field "$frontmatter" "description")
    license=$(get_field "$frontmatter" "license")

    # Extract allowed-tools (uses hyphen in SKILL.md)
    local allowed_tools
    allowed_tools=$(get_array "$frontmatter" "allowed-tools")

    if [[ -z "$name" ]]; then
        echo "Error: No 'name' field in SKILL.md frontmatter" >&2
        exit 1
    fi

    # Generate title from name
    local title
    title=$(titlecase "$name")

    # Create playbook directory
    local playbook_dir="$output_dir/$name"
    if [[ -d "$playbook_dir" ]]; then
        echo "Error: Playbook directory already exists: $playbook_dir" >&2
        exit 1
    fi

    mkdir -p "$playbook_dir"
    mkdir -p "$playbook_dir/scripts"
    mkdir -p "$playbook_dir/references"

    echo "  Name: $name"
    echo "  Title: $title"

    # Generate playbook.md
    {
        echo "---"
        echo "name: $name"
        echo "title: $title"

        # Handle multiline description
        if [[ "$description" == *$'\n'* ]]; then
            echo "description: |"
            echo "$description" | sed 's/^/  /'
        else
            echo "description: $description"
        fi

        echo "version: 1.0.0"
        [[ -n "$license" ]] && echo "license: $license"

        # Add allowed_tools if present in source (underscore for CAPS format)
        if [[ -n "$allowed_tools" ]]; then
            echo "allowed_tools:"
            echo "$allowed_tools" | while read -r tool; do
                [[ -n "$tool" ]] && echo "  - $tool"
            done
        fi

        echo "---"
        echo ""
        echo "$body"
    } > "$playbook_dir/playbook.md"

    # Copy scripts/ if exists
    if [[ -d "$skill_dir/scripts" ]]; then
        cp -r "$skill_dir/scripts/"* "$playbook_dir/scripts/" 2>/dev/null || true
        local script_count
        script_count=$(find "$playbook_dir/scripts" -type f 2>/dev/null | wc -l | tr -d ' ')
        echo "  Copied scripts: $script_count files"
    fi

    # Copy references/ if exists
    if [[ -d "$skill_dir/references" ]]; then
        cp -r "$skill_dir/references/"* "$playbook_dir/references/" 2>/dev/null || true
        local ref_count
        ref_count=$(find "$playbook_dir/references" -type f 2>/dev/null | wc -l | tr -d ' ')
        echo "  Copied references: $ref_count files"
    fi

    # Move loose .md files (not SKILL.md) to references/
    local loose_md_count=0
    for md_file in "$skill_dir"/*.md; do
        [[ -f "$md_file" ]] || continue
        local basename
        basename=$(basename "$md_file")
        if [[ "$basename" != "SKILL.md" && "$basename" != "LICENSE"* && "$basename" != "README"* ]]; then
            cp "$md_file" "$playbook_dir/references/"
            ((loose_md_count++))
        fi
    done
    [[ $loose_md_count -gt 0 ]] && echo "  Moved loose .md files to references: $loose_md_count files"

    # Copy other directories as references (themes, examples, etc.)
    for subdir in "$skill_dir"/*/; do
        [[ -d "$subdir" ]] || continue
        local dirname
        dirname=$(basename "$subdir")
        if [[ "$dirname" != "scripts" && "$dirname" != "references" && "$dirname" != "assets" ]]; then
            cp -r "$subdir" "$playbook_dir/references/"
            echo "  Copied $dirname/ to references/"
        fi
    done

    # Copy assets/ if exists
    if [[ -d "$skill_dir/assets" ]]; then
        mkdir -p "$playbook_dir/templates"
        cp -r "$skill_dir/assets/"* "$playbook_dir/templates/" 2>/dev/null || true
        echo "  Copied assets/ to templates/"
    fi

    # Clean up empty directories
    rmdir "$playbook_dir/scripts" 2>/dev/null || true
    rmdir "$playbook_dir/references" 2>/dev/null || true

    echo ""
    echo "Created CAPS playbook: $playbook_dir"
    echo ""
    echo "Next steps:"
    echo "  1. Review $playbook_dir/playbook.md"
    echo "  2. Add Goose-specific fields if needed (extensions, parameters)"
    echo "  3. Compile: caps.sh compile $playbook_dir"
    echo ""
}

# Import Goose Recipe to CAPS Playbook
import_goose_recipe() {
    local recipe_dir="$1"
    local output_dir="$2"
    local recipe_file="$recipe_dir/recipe.yaml"

    if [[ ! -f "$recipe_file" ]]; then
        echo "Error: recipe.yaml not found in $recipe_dir" >&2
        exit 1
    fi

    # Parse recipe (YAML)
    local content name title description version instructions
    content=$(cat "$recipe_file")

    title=$(echo "$content" | awk '/^title:/ {sub(/^title:[[:space:]]*/, ""); print; exit}')
    description=$(echo "$content" | awk '/^description:/ {sub(/^description:[[:space:]]*/, ""); print; exit}')
    version=$(echo "$content" | awk '/^version:/ {sub(/^version:[[:space:]]*/, ""); print; exit}')

    # Generate name from title (slugify)
    name=$(slugify "$title")

    if [[ -z "$name" ]]; then
        # Fallback to directory name
        name=$(basename "$recipe_dir")
    fi

    # Create playbook directory
    local playbook_dir="$output_dir/$name"
    if [[ -d "$playbook_dir" ]]; then
        echo "Error: Playbook directory already exists: $playbook_dir" >&2
        exit 1
    fi

    mkdir -p "$playbook_dir"

    echo "  Name: $name"
    echo "  Title: $title"

    # Extract instructions block
    instructions=$(echo "$content" | awk '
        /^instructions:[[:space:]]*[|>]/ { capture=1; next }
        /^instructions:[[:space:]]*$/ { capture=1; next }
        capture && /^[a-zA-Z_][a-zA-Z0-9_-]*:/ && !/^[[:space:]]/ { exit }
        capture { sub(/^  /, ""); print }
    ')

    # Generate playbook.md - pass through most YAML fields
    {
        echo "---"
        echo "name: $name"
        echo "title: $title"
        echo "description: $description"
        [[ -n "$version" ]] && echo "version: $version"

        # Pass through Goose-specific blocks
        local parameters extensions activities settings
        parameters=$(get_yaml_block "$content" "parameters")
        extensions=$(get_yaml_block "$content" "extensions")
        activities=$(get_yaml_block "$content" "activities")
        settings=$(get_yaml_block "$content" "settings")

        [[ -n "$parameters" ]] && echo "" && echo "$parameters"
        [[ -n "$extensions" ]] && echo "" && echo "$extensions"
        [[ -n "$activities" ]] && echo "" && echo "$activities"
        [[ -n "$settings" ]] && echo "" && echo "$settings"

        echo "---"
        echo ""
        echo "$instructions"
    } > "$playbook_dir/playbook.md"

    # Copy supporting directories
    [[ -d "$recipe_dir/scripts" ]] && cp -r "$recipe_dir/scripts" "$playbook_dir/"
    [[ -d "$recipe_dir/references" ]] && cp -r "$recipe_dir/references" "$playbook_dir/"

    echo ""
    echo "Created CAPS playbook: $playbook_dir"
    echo ""
}

# =============================================================================
# Lint Command - Quality Warnings
# =============================================================================

cmd_lint() {
    local playbook_dir=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                echo "Usage: caps.sh lint <playbook-dir>"
                echo ""
                echo "Check a CAPS playbook for quality issues and best practices."
                echo ""
                echo "Checks performed:"
                echo "  - Required fields present"
                echo "  - Description quality (length, trigger phrases)"
                echo "  - Instructions content (not empty, has steps)"
                echo "  - File references (scripts exist, references exist)"
                echo "  - Naming conventions"
                exit 0
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                exit 1
                ;;
            *)
                [[ -z "$playbook_dir" ]] && playbook_dir="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$playbook_dir" ]]; then
        echo "Error: Playbook directory is required" >&2
        echo "Usage: caps.sh lint <playbook-dir>" >&2
        exit 1
    fi

    local playbook_file="$playbook_dir/playbook.md"
    if [[ ! -f "$playbook_file" ]]; then
        echo "Error: playbook.md not found in $playbook_dir" >&2
        exit 1
    fi

    echo ""
    echo "Linting playbook: $playbook_dir"
    echo ""

    local frontmatter body warnings=0 errors=0
    frontmatter=$(extract_frontmatter "$playbook_file")
    body=$(extract_body "$playbook_file")

    # Get fields
    local name title description version
    name=$(get_field "$frontmatter" "name")
    title=$(get_field "$frontmatter" "title")
    description=$(get_multiline_field "$frontmatter" "description")
    [[ -z "$description" ]] && description=$(get_field "$frontmatter" "description")
    version=$(get_field "$frontmatter" "version")

    echo "Required Fields:"

    # Check name
    if [[ -z "$name" ]]; then
        echo "  [ERROR] name: Missing"
        ((errors++))
    elif ! validate_name "$name"; then
        echo "  [ERROR] name: '$name' invalid (must be lowercase-hyphen)"
        ((errors++))
    else
        echo "  [OK] name: $name"
    fi

    # Check title
    if [[ -z "$title" ]]; then
        echo "  [ERROR] title: Missing"
        ((errors++))
    elif [[ ${#title} -lt 5 ]]; then
        echo "  [WARN] title: Too short (${#title} chars, recommend 10+)"
        ((warnings++))
    else
        echo "  [OK] title: $title"
    fi

    # Check description
    if [[ -z "$description" ]]; then
        echo "  [ERROR] description: Missing"
        ((errors++))
    else
        local desc_len=${#description}
        if [[ $desc_len -lt 20 ]]; then
            echo "  [WARN] description: Too short ($desc_len chars, recommend 50+)"
            ((warnings++))
        else
            echo "  [OK] description: $desc_len chars"
        fi

        # Check for trigger phrases
        if ! echo "$description" | grep -qiE "(use when|trigger|invoke|run this)"; then
            echo "  [WARN] description: No trigger phrases found (add 'Use when...')"
            ((warnings++))
        fi
    fi

    echo ""
    echo "Optional Fields:"

    # Check version
    if [[ -z "$version" ]]; then
        echo "  [INFO] version: Not specified (will default to 1.0.0)"
    elif ! echo "$version" | grep -qE '^[0-9]+\.[0-9]+(\.[0-9]+)?$'; then
        echo "  [WARN] version: '$version' doesn't look like semver"
        ((warnings++))
    else
        echo "  [OK] version: $version"
    fi

    # Check allowed_tools
    local tools
    tools=$(get_array "$frontmatter" "allowed_tools")
    if [[ -n "$tools" ]]; then
        local tool_count
        tool_count=$(echo "$tools" | grep -c . || true)
        echo "  [OK] allowed_tools: $tool_count tools defined"
    else
        echo "  [INFO] allowed_tools: Not specified (all tools allowed)"
    fi

    # Check references
    local references
    references=$(get_array "$frontmatter" "references")
    if [[ -n "$references" ]]; then
        local ref_count
        ref_count=$(echo "$references" | grep -c . || true)
        echo "  [OK] references: $ref_count playbooks"
    else
        echo "  [INFO] references: None (standalone playbook)"
    fi

    echo ""
    echo "Content Quality:"

    # Check body content
    local body_lines
    body_lines=$(echo "$body" | wc -l | tr -d ' ')
    if [[ $body_lines -lt 5 ]]; then
        echo "  [WARN] Instructions: Very short ($body_lines lines)"
        ((warnings++))
    else
        echo "  [OK] Instructions: $body_lines lines"
    fi

    # Check for headings
    if ! echo "$body" | grep -q "^##"; then
        echo "  [WARN] Instructions: No section headings (## Headers)"
        ((warnings++))
    else
        local heading_count
        heading_count=$(echo "$body" | grep -c "^##" || true)
        echo "  [OK] Section headings: $heading_count found"
    fi

    # Check for code blocks
    if ! echo "$body" | grep -q '```'; then
        echo "  [INFO] Code blocks: None (consider adding examples)"
    else
        local code_count
        code_count=$(echo "$body" | grep -c '```' || true)
        code_count=$((code_count / 2))
        echo "  [OK] Code blocks: $code_count found"
    fi

    # Check for validation criteria
    if echo "$body" | grep -qE '\[[ x]\]'; then
        echo "  [OK] Validation criteria: Checklist found"
    else
        echo "  [INFO] Validation criteria: No checklist (consider adding [ ] items)"
    fi

    echo ""
    echo "File Structure:"

    # Check scripts
    if [[ -d "$playbook_dir/scripts" ]]; then
        local script_count
        script_count=$(find "$playbook_dir/scripts" -type f | wc -l | tr -d ' ')
        if [[ $script_count -gt 0 ]]; then
            echo "  [OK] scripts/: $script_count files"
            # Check if scripts are executable
            local non_exec=0
            while IFS= read -r script; do
                if [[ ! -x "$script" ]]; then
                    ((non_exec++))
                fi
            done < <(find "$playbook_dir/scripts" -type f -name "*.sh")
            if [[ $non_exec -gt 0 ]]; then
                echo "  [WARN] scripts/: $non_exec shell scripts not executable"
                ((warnings++))
            fi
        else
            echo "  [INFO] scripts/: Empty directory"
        fi
    else
        echo "  [INFO] scripts/: Not present"
    fi

    # Check references dir
    if [[ -d "$playbook_dir/references" ]]; then
        local ref_file_count
        ref_file_count=$(find "$playbook_dir/references" -type f | wc -l | tr -d ' ')
        echo "  [OK] references/: $ref_file_count files"
    else
        echo "  [INFO] references/: Not present"
    fi

    echo ""
    echo "========================================"
    echo "Lint Summary"
    echo "========================================"
    echo "Errors: $errors"
    echo "Warnings: $warnings"

    if [[ $errors -gt 0 ]]; then
        echo ""
        echo "Fix errors before compiling."
        exit 1
    elif [[ $warnings -gt 0 ]]; then
        echo ""
        echo "Consider fixing warnings for better quality."
        exit 0
    else
        echo ""
        echo "No issues found!"
        exit 0
    fi
}

# =============================================================================
# Main Entry Point
# =============================================================================

main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        compile)
            cmd_compile "$@"
            ;;
        validate)
            cmd_validate "$@"
            ;;
        lint)
            cmd_lint "$@"
            ;;
        new)
            cmd_new "$@"
            ;;
        import)
            cmd_import "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "Error: Unknown command: $command" >&2
            echo "Run 'caps.sh help' for usage information" >&2
            exit 1
            ;;
    esac
}

main "$@"
