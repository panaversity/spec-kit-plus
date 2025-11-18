#!/usr/bin/env bash
set -euo pipefail

# build-workflow.sh
# Build and package Command Workflows for local testing and distribution
# This is a user-friendly wrapper around create-release-packages.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Default values
AGENT=""
SCRIPT_TYPE=""
VERSION="dev"
OUTPUT_DIR=".genreleases"
JSON_OUTPUT=false

# Supported agents and script types
SUPPORTED_AGENTS=(claude gemini copilot cursor-agent qwen opencode windsurf codex kilocode auggie codebuddy roo q amp)
SUPPORTED_SCRIPTS=(sh ps)

# Color output (if not in JSON mode)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage information
usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Build and package Command Workflows for testing and distribution.

Options:
  --agent <name>      Build for specific agent (default: all)
                      Supported: ${SUPPORTED_AGENTS[*]}

  --script <sh|ps>    Build for specific script type (default: both)
                      sh  = Bash scripts (Linux/macOS)
                      ps  = PowerShell scripts (Windows)

  --version <ver>     Version string (default: dev)
                      Format: v0.0.0 or 'dev' for development

  --output <dir>      Output directory (default: .genreleases)

  --json              Output results as JSON

  --help              Show this help message

Examples:
  $0                                          # Build all agents, all scripts
  $0 --agent claude --script sh              # Build Claude with bash only
  $0 --agent gemini --version v1.0.0-test    # Build Gemini with test version
  $0 --script ps                             # Build all agents with PowerShell only

EOF
  exit 0
}

# Parse command line arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --agent)
        AGENT="$2"
        shift 2
        ;;
      --script)
        SCRIPT_TYPE="$2"
        shift 2
        ;;
      --version)
        VERSION="$2"
        shift 2
        ;;
      --output)
        OUTPUT_DIR="$2"
        shift 2
        ;;
      --json)
        JSON_OUTPUT=true
        shift
        ;;
      --help)
        usage
        ;;
      *)
        if [[ "$1" == --* ]]; then
          echo "Error: Unknown option: $1" >&2
          echo "Use --help for usage information" >&2
          exit 1
        fi
        # Skip non-option arguments
        shift
        ;;
    esac
  done
}

# Validate agent
validate_agent() {
  if [[ -z "$AGENT" ]]; then
    return 0  # Empty means all agents
  fi

  for supported in "${SUPPORTED_AGENTS[@]}"; do
    if [[ "$AGENT" == "$supported" ]]; then
      return 0
    fi
  done

  echo "Error: Invalid agent '$AGENT'" >&2
  echo "Supported agents: ${SUPPORTED_AGENTS[*]}" >&2
  exit 1
}

# Validate script type
validate_script() {
  if [[ -z "$SCRIPT_TYPE" ]]; then
    return 0  # Empty means all script types
  fi

  for supported in "${SUPPORTED_SCRIPTS[@]}"; do
    if [[ "$SCRIPT_TYPE" == "$supported" ]]; then
      return 0
    fi
  done

  echo "Error: Invalid script type '$SCRIPT_TYPE'" >&2
  echo "Supported script types: ${SUPPORTED_SCRIPTS[*]}" >&2
  exit 1
}

# Validate version format
validate_version() {
  # Allow 'dev' as special case
  if [[ "$VERSION" == "dev" ]]; then
    return 0
  fi

  # Check for v0.0.0 format (exact format required by create-release-packages.sh)
  if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format '$VERSION'" >&2
    echo "Version must be 'dev' or match pattern: v0.0.0 (e.g., v1.0.0, v2.5.3)" >&2
    echo "Note: Version suffixes like -beta or -dev are not supported" >&2
    exit 1
  fi
}

# Print colored message (only if not in JSON mode)
print_msg() {
  if [[ "$JSON_OUTPUT" == "false" ]]; then
    echo -e "$1"
  fi
}

# Build packages using create-release-packages.sh
build_packages() {
  local build_script="$REPO_ROOT/.github/workflows/scripts/create-release-packages.sh"

  if [[ ! -f "$build_script" ]]; then
    echo "Error: Build script not found: $build_script" >&2
    exit 1
  fi

  # Change to repo root
  cd "$REPO_ROOT"

  # Convert 'dev' to proper version format for the build script
  local build_version="$VERSION"
  if [[ "$VERSION" == "dev" ]]; then
    build_version="v0.0.0"
  fi

  # Set environment variables for the build script
  if [[ -n "$AGENT" ]]; then
    export AGENTS="$AGENT"
  fi

  if [[ -n "$SCRIPT_TYPE" ]]; then
    export SCRIPTS="$SCRIPT_TYPE"
  fi

  # Run the build script
  print_msg "${BLUE}Building packages...${NC}"

  # Capture build output
  if [[ "$JSON_OUTPUT" == "false" ]]; then
    "$build_script" "$build_version"
  else
    "$build_script" "$build_version" >/dev/null 2>&1
  fi
}

# Collect build results
collect_results() {
  local results=()

  # Determine which agents and scripts were built
  local agents_to_check=("${SUPPORTED_AGENTS[@]}")
  if [[ -n "$AGENT" ]]; then
    agents_to_check=("$AGENT")
  fi

  local scripts_to_check=("${SUPPORTED_SCRIPTS[@]}")
  if [[ -n "$SCRIPT_TYPE" ]]; then
    scripts_to_check=("$SCRIPT_TYPE")
  fi

  # Check for built packages
  for agent in "${agents_to_check[@]}"; do
    for script in "${scripts_to_check[@]}"; do
      local package_dir="$OUTPUT_DIR/sdd-${agent}-package-${script}"
      local archive="$OUTPUT_DIR/spec-kit-template-${agent}-${script}.zip"

      if [[ -d "$package_dir" ]]; then
        results+=("{\"agent\":\"$agent\",\"script\":\"$script\",\"path\":\"$package_dir\",\"archive\":\"$archive\"}")
      fi
    done
  done

  echo "${results[@]}"
}

# Output results as JSON
output_json() {
  local packages=("$@")

  echo -n '{"status":"success","version":"'"$VERSION"'","output_dir":"'"$OUTPUT_DIR"'","packages":['

  local first=true
  for pkg in "${packages[@]}"; do
    if [[ "$first" == "true" ]]; then
      first=false
    else
      echo -n ","
    fi
    echo -n "$pkg"
  done

  echo ']}'
}

# Output results in human-readable format
output_human() {
  local packages=("$@")

  print_msg ""
  print_msg "${GREEN}✓ Build completed successfully!${NC}"
  print_msg ""
  print_msg "${BLUE}Version:${NC} $VERSION"
  print_msg "${BLUE}Output Directory:${NC} $OUTPUT_DIR"
  print_msg ""
  print_msg "${BLUE}Built Packages:${NC}"

  for pkg in "${packages[@]}"; do
    # Parse JSON to extract values
    local agent=$(echo "$pkg" | grep -o '"agent":"[^"]*"' | cut -d'"' -f4)
    local script=$(echo "$pkg" | grep -o '"script":"[^"]*"' | cut -d'"' -f4)
    local path=$(echo "$pkg" | grep -o '"path":"[^"]*"' | cut -d'"' -f4)

    print_msg ""
    print_msg "  ${GREEN}•${NC} Agent: $agent ($script)"
    print_msg "    Location: $path"
  done

  print_msg ""
  print_msg "${YELLOW}Next Steps:${NC}"
  print_msg "  1. Test the package:"
  print_msg "     ${BLUE}cp -r $OUTPUT_DIR/sdd-<agent>-package-<script>/. /path/to/test-project/${NC}"
  print_msg ""
  print_msg "  2. Test your commands in the test project:"
  print_msg "     ${BLUE}/sp.your-command${NC}"
  print_msg ""
}

# Main execution
main() {
  # Parse arguments from JSON if provided as single argument
  if [[ $# -eq 1 && "$1" == --json\ * ]]; then
    # Extract JSON argument
    local json_arg="${1#--json }"

    # Simple argument parsing from the JSON string representation
    # Convert --json "{\"agent\":\"claude\"}" style to individual args
    # For now, just pass through and let parse_args handle it
    set -- --json
  fi

  parse_args "$@"
  validate_agent
  validate_script
  validate_version

  # Build packages
  if ! build_packages; then
    if [[ "$JSON_OUTPUT" == "true" ]]; then
      echo '{"status":"error","message":"Build failed"}'
    else
      print_msg "${RED}✗ Build failed${NC}"
    fi
    exit 1
  fi

  # Collect and output results
  local packages=($(collect_results))

  if [[ ${#packages[@]} -eq 0 ]]; then
    if [[ "$JSON_OUTPUT" == "true" ]]; then
      echo '{"status":"error","message":"No packages were built"}'
    else
      print_msg "${RED}✗ No packages were built${NC}"
    fi
    exit 1
  fi

  if [[ "$JSON_OUTPUT" == "true" ]]; then
    output_json "${packages[@]}"
  else
    output_human "${packages[@]}"
  fi
}

# Run main function
main "$@"
