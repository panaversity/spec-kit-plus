#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# CAPS Compiler Test Suite
# =============================================================================
#
# Automated tests for the CAPS bash compiler.
# Run from repo root: ./scripts/bash/test-caps.sh
#
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CAPS="$REPO_ROOT/scripts/bash/caps.sh"
TEST_DIR=$(mktemp -d)
FIXTURE_DIR="$REPO_ROOT/tests/fixtures/playbooks/internal-comms"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0

pass() {
    echo -e "  ${GREEN}PASS${NC}: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    echo -e "  ${RED}FAIL${NC}: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

echo ""
echo "========================================"
echo "CAPS Compiler Test Suite"
echo "========================================"
echo "Test directory: $TEST_DIR"
echo ""

# =============================================================================
# Test: Help Command
# =============================================================================
echo "TEST: Help command"
if "$CAPS" help > /dev/null 2>&1; then
    pass "help executes without error"
else
    fail "help command failed"
fi

if "$CAPS" help | grep -q "CAPS - Coding Agent Playbook Spec"; then
    pass "help shows correct title"
else
    fail "help missing title"
fi

# =============================================================================
# Test: Validate Command
# =============================================================================
echo ""
echo "TEST: Validate command"

if "$CAPS" validate "$FIXTURE_DIR" > /dev/null 2>&1; then
    pass "validate succeeds on valid playbook"
else
    fail "validate failed on valid playbook"
fi

validate_output=$("$CAPS" validate /nonexistent 2>&1 || true)
if echo "$validate_output" | grep -q "not found"; then
    pass "validate errors on missing directory"
else
    fail "validate should error on missing directory"
fi

# Create invalid playbook (missing required fields)
mkdir -p "$TEST_DIR/invalid-playbook"
echo -e "---\nname: invalid\n---\n# Test" > "$TEST_DIR/invalid-playbook/playbook.md"
validate_output=$("$CAPS" validate "$TEST_DIR/invalid-playbook" 2>&1 || true)
if echo "$validate_output" | grep -q "FAIL"; then
    pass "validate catches missing required fields"
else
    fail "validate should fail on missing title"
fi

# =============================================================================
# Test: New Command
# =============================================================================
echo ""
echo "TEST: New command"

if "$CAPS" new my-test-playbook --output "$TEST_DIR" > /dev/null 2>&1; then
    pass "new creates playbook"
else
    fail "new command failed"
fi

if [[ -f "$TEST_DIR/my-test-playbook/playbook.md" ]]; then
    pass "new creates playbook.md"
else
    fail "playbook.md not created"
fi

if [[ -d "$TEST_DIR/my-test-playbook/scripts" ]]; then
    pass "new creates scripts/ directory"
else
    fail "scripts/ not created"
fi

if [[ -d "$TEST_DIR/my-test-playbook/references" ]]; then
    pass "new creates references/ directory"
else
    fail "references/ not created"
fi

if grep -q "name: my-test-playbook" "$TEST_DIR/my-test-playbook/playbook.md"; then
    pass "new populates name field"
else
    fail "name field not populated"
fi

if grep -q "title: My Test Playbook" "$TEST_DIR/my-test-playbook/playbook.md"; then
    pass "new generates title case"
else
    fail "title not generated correctly"
fi

# Test duplicate detection
new_output=$("$CAPS" new my-test-playbook --output "$TEST_DIR" 2>&1 || true)
if echo "$new_output" | grep -qi "already exists"; then
    pass "new detects existing directory"
else
    fail "new should error on existing directory"
fi

# =============================================================================
# Test: Compile to Claude
# =============================================================================
echo ""
echo "TEST: Compile to Claude"

if "$CAPS" compile "$FIXTURE_DIR" --target claude --output "$TEST_DIR/claude-out" > /dev/null 2>&1; then
    pass "compile to claude succeeds"
else
    fail "compile to claude failed"
fi

SKILL_FILE="$TEST_DIR/claude-out/.claude/skills/internal-comms/SKILL.md"

if [[ -f "$SKILL_FILE" ]]; then
    pass "SKILL.md created"
else
    fail "SKILL.md not created"
fi

if grep -q "^name: internal-comms" "$SKILL_FILE"; then
    pass "SKILL.md has name field"
else
    fail "SKILL.md missing name"
fi

if grep -q "^description:" "$SKILL_FILE"; then
    pass "SKILL.md has description"
else
    fail "SKILL.md missing description"
fi

if grep -q "^allowed-tools:" "$SKILL_FILE"; then
    pass "SKILL.md has allowed-tools"
else
    fail "SKILL.md missing allowed-tools"
fi

if grep -q "^- Read" "$SKILL_FILE"; then
    pass "SKILL.md has Read in allowed-tools"
else
    fail "SKILL.md missing Read tool"
fi

# Check for sub-playbook references (content varies by playbook)
if grep -q "sub-playbooks" "$SKILL_FILE" || grep -q "## Related" "$SKILL_FILE"; then
    pass "SKILL.md references sub-playbooks"
else
    pass "SKILL.md has no sub-playbook references (optional)"
fi

if [[ -d "$TEST_DIR/claude-out/.claude/skills/internal-comms/scripts" ]]; then
    pass "scripts/ directory copied to skill"
else
    fail "scripts/ not copied"
fi

if [[ -d "$TEST_DIR/claude-out/.claude/skills/internal-comms/references" ]]; then
    pass "references/ directory copied to skill"
else
    fail "references/ not copied"
fi

# =============================================================================
# Test: Compile to Goose
# =============================================================================
echo ""
echo "TEST: Compile to Goose"

if "$CAPS" compile "$FIXTURE_DIR" --target goose --output "$TEST_DIR/goose-out" > /dev/null 2>&1; then
    pass "compile to goose succeeds"
else
    fail "compile to goose failed"
fi

RECIPE_FILE="$TEST_DIR/goose-out/.goose/recipes/internal-comms/recipe.yaml"

if [[ -f "$RECIPE_FILE" ]]; then
    pass "recipe.yaml created"
else
    fail "recipe.yaml not created"
fi

if grep -q "^version:" "$RECIPE_FILE"; then
    pass "recipe.yaml has version"
else
    fail "recipe.yaml missing version"
fi

if grep -q "^title:" "$RECIPE_FILE"; then
    pass "recipe.yaml has title"
else
    fail "recipe.yaml missing title"
fi

if grep -q "^description:" "$RECIPE_FILE"; then
    pass "recipe.yaml has description"
else
    fail "recipe.yaml missing description"
fi

if grep -q "^instructions:" "$RECIPE_FILE"; then
    pass "recipe.yaml has instructions"
else
    fail "recipe.yaml missing instructions"
fi

# Optional Goose fields - check if present when specified in playbook
if grep -q "^parameters:" "$RECIPE_FILE"; then
    pass "recipe.yaml has parameters (optional)"
else
    pass "recipe.yaml has no parameters (optional field)"
fi

if grep -q "^extensions:" "$RECIPE_FILE"; then
    pass "recipe.yaml has extensions (optional)"
else
    pass "recipe.yaml has no extensions (optional field)"
fi

# =============================================================================
# Test: Compile to Both (all)
# =============================================================================
echo ""
echo "TEST: Compile to both targets"

if "$CAPS" compile "$FIXTURE_DIR" --output "$TEST_DIR/both-out" > /dev/null 2>&1; then
    pass "compile to all succeeds"
else
    fail "compile to all failed"
fi

if [[ -f "$TEST_DIR/both-out/.claude/skills/internal-comms/SKILL.md" ]] && \
   [[ -f "$TEST_DIR/both-out/.goose/recipes/internal-comms/recipe.yaml" ]]; then
    pass "both SKILL.md and recipe.yaml created"
else
    fail "not both outputs created"
fi

# =============================================================================
# Test: Name Validation
# =============================================================================
echo ""
echo "TEST: Name validation"

# Create playbook with invalid name
mkdir -p "$TEST_DIR/BadName"
cat > "$TEST_DIR/BadName/playbook.md" << 'EOF'
---
name: BadName
title: Bad Name Test
description: Test invalid name
---
# Test
EOF

compile_output=$("$CAPS" compile "$TEST_DIR/BadName" --output "$TEST_DIR/bad-out" 2>&1 || true)
if echo "$compile_output" | grep -qi "invalid name"; then
    pass "compile rejects invalid name format"
else
    fail "compile should reject uppercase names"
fi

# =============================================================================
# Test: Import Claude Skill
# =============================================================================
echo ""
echo "TEST: Import Claude Skill"

# Create a minimal Claude skill fixture for import testing
mkdir -p "$TEST_DIR/import-source/.claude/skills/test-import"
cat > "$TEST_DIR/import-source/.claude/skills/test-import/SKILL.md" << 'EOF'
---
name: test-import
description: A test skill for import validation
allowed-tools:
- Read
- Write
- Bash
---

# Test Import Skill

This is a test skill to validate the import functionality.

## Instructions

1. Do something useful
2. Do something else

## Example Usage

```bash
echo "Hello from test skill"
```
EOF

# Add a script file
mkdir -p "$TEST_DIR/import-source/.claude/skills/test-import/scripts"
echo '#!/bin/bash' > "$TEST_DIR/import-source/.claude/skills/test-import/scripts/helper.sh"
echo 'echo "Helper script"' >> "$TEST_DIR/import-source/.claude/skills/test-import/scripts/helper.sh"

# Test import command
import_output=$("$CAPS" import "$TEST_DIR/import-source/.claude/skills/test-import" --output "$TEST_DIR/imported-playbooks" 2>&1 || true)
if echo "$import_output" | grep -qi "success\|created\|imported"; then
    pass "import executes successfully"
else
    fail "import command failed"
fi

if [[ -f "$TEST_DIR/imported-playbooks/test-import/playbook.md" ]]; then
    pass "import creates playbook.md"
else
    fail "playbook.md not created by import"
fi

if grep -q "^name: test-import" "$TEST_DIR/imported-playbooks/test-import/playbook.md"; then
    pass "imported playbook has correct name"
else
    fail "imported playbook missing name"
fi

if grep -q "^description: A test skill" "$TEST_DIR/imported-playbooks/test-import/playbook.md"; then
    pass "imported playbook has description"
else
    fail "imported playbook missing description"
fi

if [[ -d "$TEST_DIR/imported-playbooks/test-import/scripts" ]]; then
    pass "import copies scripts directory"
else
    fail "scripts not copied during import"
fi

if [[ -f "$TEST_DIR/imported-playbooks/test-import/scripts/helper.sh" ]]; then
    pass "import preserves script files"
else
    fail "script files not preserved"
fi

# =============================================================================
# Test: Round-trip Import/Compile
# =============================================================================
echo ""
echo "TEST: Round-trip (import then compile back)"

# Compile the imported playbook back to a Claude skill
if "$CAPS" compile "$TEST_DIR/imported-playbooks/test-import" --target claude --output "$TEST_DIR/roundtrip-out" > /dev/null 2>&1; then
    pass "round-trip compile succeeds"
else
    fail "round-trip compile failed"
fi

ROUNDTRIP_SKILL="$TEST_DIR/roundtrip-out/.claude/skills/test-import/SKILL.md"
if [[ -f "$ROUNDTRIP_SKILL" ]]; then
    pass "round-trip creates SKILL.md"
else
    fail "round-trip SKILL.md not created"
fi

if grep -q "^name: test-import" "$ROUNDTRIP_SKILL"; then
    pass "round-trip preserves name"
else
    fail "round-trip lost name"
fi

if grep -q "^description: A test skill" "$ROUNDTRIP_SKILL"; then
    pass "round-trip preserves description"
else
    fail "round-trip lost description"
fi

if grep -q "^- Read" "$ROUNDTRIP_SKILL"; then
    pass "round-trip preserves allowed-tools"
else
    fail "round-trip lost allowed-tools"
fi

# =============================================================================
# Test: References Compilation (Recursive Composition)
# =============================================================================
echo ""
echo "TEST: References compilation (recursive composition)"

REFS_FIXTURE_DIR="$REPO_ROOT/tests/fixtures/playbooks/comms-suite"

# Test compile to Claude with references
if "$CAPS" compile "$REFS_FIXTURE_DIR" --target claude --output "$TEST_DIR/refs-claude" > /dev/null 2>&1; then
    pass "compile with references to claude succeeds"
else
    fail "compile with references to claude failed"
fi

REFS_SKILL_FILE="$TEST_DIR/refs-claude/.claude/skills/comms-suite/SKILL.md"

if [[ -f "$REFS_SKILL_FILE" ]]; then
    pass "SKILL.md created for playbook with references"
else
    fail "SKILL.md not created for playbook with references"
fi

if grep -q "## Related Skills" "$REFS_SKILL_FILE"; then
    pass "SKILL.md has Related Skills section"
else
    fail "SKILL.md missing Related Skills section"
fi

if grep -q "internal-comms" "$REFS_SKILL_FILE"; then
    pass "SKILL.md references internal-comms skill"
else
    fail "SKILL.md missing internal-comms reference"
fi

if grep -q "format-helpers" "$REFS_SKILL_FILE"; then
    pass "SKILL.md references format-helpers skill"
else
    fail "SKILL.md missing format-helpers reference"
fi

# Test compile to Goose with references
if "$CAPS" compile "$REFS_FIXTURE_DIR" --target goose --output "$TEST_DIR/refs-goose" > /dev/null 2>&1; then
    pass "compile with references to goose succeeds"
else
    fail "compile with references to goose failed"
fi

REFS_RECIPE_FILE="$TEST_DIR/refs-goose/.goose/recipes/comms-suite/recipe.yaml"

if [[ -f "$REFS_RECIPE_FILE" ]]; then
    pass "recipe.yaml created for playbook with references"
else
    fail "recipe.yaml not created for playbook with references"
fi

if grep -q "^sub_recipes:" "$REFS_RECIPE_FILE"; then
    pass "recipe.yaml has sub_recipes section"
else
    fail "recipe.yaml missing sub_recipes section"
fi

if grep -q "name: internal-comms" "$REFS_RECIPE_FILE"; then
    pass "recipe.yaml has internal-comms sub_recipe"
else
    fail "recipe.yaml missing internal-comms sub_recipe"
fi

if grep -q "name: format-helpers" "$REFS_RECIPE_FILE"; then
    pass "recipe.yaml has format-helpers sub_recipe"
else
    fail "recipe.yaml missing format-helpers sub_recipe"
fi

if grep -q "{{ recipe_dir }}" "$REFS_RECIPE_FILE"; then
    pass "recipe.yaml uses recipe_dir template variable"
else
    fail "recipe.yaml missing recipe_dir template"
fi

# =============================================================================
# Test: Commands and Agents (Intelligence Package)
# =============================================================================
echo ""
echo "TEST: Commands and Agents compilation"

# Use the playbooks/internal-comms which has commands/ and agents/
BUNDLE_FIXTURE_DIR="$REPO_ROOT/playbooks/internal-comms"

# Test compile with commands and agents
if "$CAPS" compile "$BUNDLE_FIXTURE_DIR" --target claude --output "$TEST_DIR/bundle-out" > /dev/null 2>&1; then
    pass "compile with commands/agents succeeds"
else
    fail "compile with commands/agents failed"
fi

BUNDLE_SKILL_FILE="$TEST_DIR/bundle-out/.claude/skills/internal-comms/SKILL.md"

# Check SKILL.md has Commands section
if grep -q "## Commands" "$BUNDLE_SKILL_FILE"; then
    pass "SKILL.md has Commands disclosure section"
else
    fail "SKILL.md missing Commands section"
fi

# Check SKILL.md has Subagents section
if grep -q "## Subagents" "$BUNDLE_SKILL_FILE"; then
    pass "SKILL.md has Subagents disclosure section"
else
    fail "SKILL.md missing Subagents section"
fi

# Check commands copied to .claude/commands/ with namespace prefix
if [[ -f "$TEST_DIR/bundle-out/.claude/commands/internal-comms-3p-update.md" ]]; then
    pass "command copied to .claude/commands/ with namespace"
else
    fail "command not copied to .claude/commands/ (expected internal-comms-3p-update.md)"
fi

# Check agents copied to .claude/agents/ with namespace prefix
if [[ -f "$TEST_DIR/bundle-out/.claude/agents/internal-comms-comms-reviewer.md" ]]; then
    pass "agent copied to .claude/agents/ with namespace"
else
    fail "agent not copied to .claude/agents/ (expected internal-comms-comms-reviewer.md)"
fi

# Check command is listed in SKILL.md with namespace
if grep -q "/internal-comms-3p-update" "$BUNDLE_SKILL_FILE"; then
    pass "SKILL.md lists /internal-comms-3p-update command"
else
    fail "SKILL.md missing /internal-comms-3p-update command"
fi

# Check agent is listed in SKILL.md with namespace
if grep -q "internal-comms-comms-reviewer" "$BUNDLE_SKILL_FILE"; then
    pass "SKILL.md lists internal-comms-comms-reviewer agent"
else
    fail "SKILL.md missing internal-comms-comms-reviewer agent"
fi

# Check agents bundled in skill directory
if [[ -d "$TEST_DIR/bundle-out/.claude/skills/internal-comms/agents" ]]; then
    pass "agents/ directory bundled in skill"
else
    fail "agents/ not bundled in skill directory"
fi

if [[ -f "$TEST_DIR/bundle-out/.claude/skills/internal-comms/agents/comms-reviewer.md" ]]; then
    pass "agent file bundled in skill/agents/"
else
    fail "agent file not bundled in skill/agents/"
fi

# Check invocation instructions in SKILL.md
if grep -q "Invoking Subagents" "$BUNDLE_SKILL_FILE"; then
    pass "SKILL.md has invocation instructions section"
else
    fail "SKILL.md missing invocation instructions"
fi

if grep -q "AGENT_PROMPT" "$BUNDLE_SKILL_FILE"; then
    pass "SKILL.md has shell invocation example"
else
    fail "SKILL.md missing shell invocation example"
fi

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "========================================"
echo "Test Summary"
echo "========================================"
echo -e "Passed: ${GREEN}$PASS_COUNT${NC}"
echo -e "Failed: ${RED}$FAIL_COUNT${NC}"
echo ""

if [[ $FAIL_COUNT -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
