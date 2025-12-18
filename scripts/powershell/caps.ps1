#!/usr/bin/env pwsh

# =============================================================================
# CAPS Compiler - Coding Agent Playbook Spec (PowerShell)
# =============================================================================
#
# A vendor-neutral compiler for AI coding agent playbooks.
# Write once in CAPS format, compile to Claude Code Skills and Goose Recipes.
#
# Usage:
#   caps.ps1 compile <playbook-dir> [-Target claude|goose|all] [-Output <dir>]
#   caps.ps1 validate <playbook-dir>
#   caps.ps1 new <playbook-name> [-Output <dir>]
#   caps.ps1 help
#
# =============================================================================

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

$ErrorActionPreference = 'Stop'

# Get script location and determine template directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

# Determine template directory based on context
if (Test-Path "$RepoRoot/.specify") {
    # Installed in user project
    $TemplateDir = "$RepoRoot/.specify/templates/caps"
} else {
    # Development
    $TemplateDir = "$RepoRoot/templates/caps"
}

# =============================================================================
# YAML Parsing Functions
# =============================================================================

function Get-Frontmatter {
    param([string]$Content)

    $lines = $Content -split "`n"
    $inFrontmatter = $false
    $frontmatter = @()

    foreach ($line in $lines) {
        if ($line -match '^---\s*$') {
            if ($inFrontmatter) { break }
            $inFrontmatter = $true
            continue
        }
        if ($inFrontmatter) {
            $frontmatter += $line
        }
    }

    return $frontmatter -join "`n"
}

function Get-Body {
    param([string]$Content)

    $lines = $Content -split "`n"
    $count = 0
    $body = @()

    foreach ($line in $lines) {
        if ($line -match '^---\s*$') {
            $count++
            continue
        }
        if ($count -ge 2) {
            $body += $line
        }
    }

    return $body -join "`n"
}

function Get-YamlField {
    param([string]$Yaml, [string]$Field)

    foreach ($line in ($Yaml -split "`n")) {
        if ($line -match "^$Field`:\s*(.*)$") {
            $value = $Matches[1].Trim()
            $value = $value -replace '^["'']|["'']$', ''
            return $value
        }
    }
    return $null
}

function Get-YamlMultilineField {
    param([string]$Yaml, [string]$Field)

    $lines = $Yaml -split "`n"
    $capture = $false
    $result = @()

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if ($line -match "^$Field`:\s*[|>]") {
            $capture = $true
            continue
        }

        if ($line -match "^$Field`:\s*(.+)$" -and $Matches[1] -notmatch '^[|>]') {
            return $Matches[1].Trim()
        }

        if ($capture) {
            if ($line -match '^[a-zA-Z_][a-zA-Z0-9_-]*:' -and $line -notmatch '^\s') {
                break
            }
            if ($line -match '^\s{2}(.*)$') {
                $result += $Matches[1]
            }
        }
    }

    return $result -join "`n"
}

function Get-YamlArray {
    param([string]$Yaml, [string]$Field)

    $lines = $Yaml -split "`n"
    $capture = $false
    $result = @()

    foreach ($line in $lines) {
        # Check for inline array: field: [item1, item2]
        if ($line -match "^$Field`:\s*\[(.*)\]") {
            $items = $Matches[1] -split ',\s*'
            foreach ($item in $items) {
                $item = $item.Trim() -replace '^["'']|["'']$', ''
                if ($item) { $result += $item }
            }
            return $result
        }

        # Start of block array
        if ($line -match "^$Field`:\s*$") {
            $capture = $true
            continue
        }

        if ($capture) {
            if ($line -match '^[a-zA-Z_][a-zA-Z0-9_-]*:' -and $line -notmatch '^\s') {
                break
            }
            if ($line -match '^\s*-\s*(.*)$') {
                $item = $Matches[1] -replace '^["'']|["'']$', ''
                $result += $item
            }
        }
    }

    return $result
}

function Get-YamlBlock {
    param([string]$Yaml, [string]$Field)

    $lines = $Yaml -split "`n"
    $capture = $false
    $result = @()

    foreach ($line in $lines) {
        if ($line -match "^$Field`:") {
            $capture = $true
            $result += $line
            continue
        }

        if ($capture) {
            if ($line -match '^[a-zA-Z_][a-zA-Z0-9_-]*:' -and $line -notmatch '^\s') {
                break
            }
            $result += $line
        }
    }

    return $result -join "`n"
}

# =============================================================================
# Validation Functions
# =============================================================================

function Test-PlaybookName {
    param([string]$Name)

    if ($Name -notmatch '^[a-z][a-z0-9-]*$') { return $false }
    if ($Name.Length -gt 64) { return $false }
    return $true
}

function ConvertTo-Slug {
    param([string]$Name)

    $slug = $Name.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', ''
    return $slug
}

function ConvertTo-TitleCase {
    param([string]$Name)

    $words = $Name -split '-'
    $titled = $words | ForEach-Object {
        if ($_.Length -gt 0) {
            $_.Substring(0, 1).ToUpper() + $_.Substring(1)
        }
    }
    return $titled -join ' '
}

# =============================================================================
# Claude Code Skill Generator
# =============================================================================

function New-ClaudeSkill {
    param([string]$PlaybookDir, [string]$OutputDir, [switch]$DryRun)

    $playbookFile = Join-Path $PlaybookDir "playbook.md"
    $content = Get-Content -Path $playbookFile -Raw

    $frontmatter = Get-Frontmatter $content
    $body = Get-Body $content

    $name = Get-YamlField $frontmatter "name"
    $description = Get-YamlMultilineField $frontmatter "description"
    if (-not $description) { $description = Get-YamlField $frontmatter "description" }
    $license = Get-YamlField $frontmatter "license"
    $allowedTools = Get-YamlArray $frontmatter "allowed_tools"
    $references = Get-YamlArray $frontmatter "references"

    # Check for commands and agents directories
    $commandsDir = Join-Path $PlaybookDir "commands"
    $agentsDir = Join-Path $PlaybookDir "agents"
    $hasCommands = Test-Path $commandsDir
    $hasAgents = Test-Path $agentsDir

    $skillDir = Join-Path $OutputDir ".claude/skills/$name"

    if ($DryRun) {
        return $skillDir
    }

    # Create skill directory
    New-Item -ItemType Directory -Path $skillDir -Force | Out-Null

    # Generate SKILL.md
    $skill = @()
    $skill += "---"
    $skill += "name: $name"

    if ($description -match "`n") {
        $skill += "description: |"
        foreach ($line in ($description -split "`n")) {
            $skill += "  $line"
        }
    } else {
        $skill += "description: $description"
    }

    if ($license) { $skill += "license: $license" }

    if ($allowedTools) {
        $skill += "allowed-tools:"
        foreach ($tool in $allowedTools) {
            $skill += "- $tool"
        }
    }

    $skill += "---"
    $skill += ""
    $skill += $body

    # Add Related Skills section if references exist
    if ($references -and $references.Count -gt 0) {
        $skill += ""
        $skill += "## Related Skills"
        $skill += ""
        $skill += "This skill works with the following skills (invoke as needed):"
        $skill += ""
        foreach ($ref in $references) {
            $refName = Split-Path -Leaf $ref
            $skill += "- **$refName** - See [```.claude/skills/$refName/SKILL.md```](../$refName/SKILL.md)"
        }
    }

    # Add Commands section if commands/ directory exists
    if ($hasCommands) {
        $cmdFiles = Get-ChildItem -Path $commandsDir -Filter "*.md" -File
        if ($cmdFiles.Count -gt 0) {
            $skill += ""
            $skill += "## Commands"
            $skill += ""
            $skill += "This skill includes slash commands:"
            $skill += ""
            foreach ($cmdFile in $cmdFiles) {
                $cmdName = [System.IO.Path]::GetFileNameWithoutExtension($cmdFile.Name)
                $namespacedCmd = "$name-$cmdName"
                $cmdContent = Get-Content -Path $cmdFile.FullName -Raw
                $cmdDesc = ""
                if ($cmdContent -match "description:\s*(.+)") {
                    $cmdDesc = $Matches[1].Trim()
                }
                $skill += "- ``/$namespacedCmd`` - $cmdDesc"
            }
        }
    }

    # Add Agents section if agents/ directory exists
    if ($hasAgents) {
        $agentFiles = Get-ChildItem -Path $agentsDir -Filter "*.md" -File
        if ($agentFiles.Count -gt 0) {
            $skill += ""
            $skill += "## Subagents"
            $skill += ""
            $skill += "This skill includes specialized agents in ``agents/`` directory:"
            $skill += ""
            foreach ($agentFile in $agentFiles) {
                $agentName = [System.IO.Path]::GetFileNameWithoutExtension($agentFile.Name)
                $namespacedAgent = "$name-$agentName"
                $agentContent = Get-Content -Path $agentFile.FullName -Raw
                $agentDesc = ""
                if ($agentContent -match "description:\s*(.+)") {
                    $agentDesc = $Matches[1].Trim()
                }
                $skill += "- **$namespacedAgent** - $agentDesc"
            }
            $skill += ""
            $skill += "### Invoking Subagents"
            $skill += ""
            $skill += "**Claude Code**: Use the Task tool with the agent name."
            $skill += ""
            $skill += "**Other agents**: Spawn yourself with the agent's prompt:"
            $skill += ""
            $skill += '```bash'
            $skill += "# Read agent prompt and invoke"
            $skill += 'AGENT_PROMPT=$(cat agents/<agent-name>.md)'
            $skill += 'claude --print "$AGENT_PROMPT" "Your task here"'
            $skill += "# Or for Goose:"
            $skill += 'goose run --instructions "$AGENT_PROMPT"'
            $skill += '```'
        }
    }

    $skillFile = Join-Path $skillDir "SKILL.md"
    $skill -join "`n" | Set-Content -Path $skillFile -NoNewline

    # Copy supporting directories to skill
    @("scripts", "references", "templates") | ForEach-Object {
        $srcDir = Join-Path $PlaybookDir $_
        if (Test-Path $srcDir) {
            Copy-Item -Path $srcDir -Destination $skillDir -Recurse -Force
        }
    }

    # Bundle agents in skill directory (for all agents to use)
    if ($hasAgents) {
        $skillAgentsDir = Join-Path $skillDir "agents"
        New-Item -ItemType Directory -Path $skillAgentsDir -Force | Out-Null
        Get-ChildItem -Path $agentsDir -Filter "*.md" -File | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $skillAgentsDir -Force
        }
    }

    # Copy commands to .claude/commands/ with namespace prefix (Claude native)
    if ($hasCommands) {
        $claudeCommandsDir = Join-Path $OutputDir ".claude/commands"
        New-Item -ItemType Directory -Path $claudeCommandsDir -Force | Out-Null
        Get-ChildItem -Path $commandsDir -Filter "*.md" -File | ForEach-Object {
            $newName = "$name-$($_.BaseName).md"
            Copy-Item -Path $_.FullName -Destination (Join-Path $claudeCommandsDir $newName) -Force
        }
    }

    # Copy agents to .claude/agents/ with namespace prefix (Claude native)
    if ($hasAgents) {
        $claudeAgentsDir = Join-Path $OutputDir ".claude/agents"
        New-Item -ItemType Directory -Path $claudeAgentsDir -Force | Out-Null
        Get-ChildItem -Path $agentsDir -Filter "*.md" -File | ForEach-Object {
            $newName = "$name-$($_.BaseName).md"
            Copy-Item -Path $_.FullName -Destination (Join-Path $claudeAgentsDir $newName) -Force
        }
    }

    return $skillDir
}

# =============================================================================
# Goose Recipe Generator
# =============================================================================

function New-GooseRecipe {
    param([string]$PlaybookDir, [string]$OutputDir, [switch]$DryRun)

    $playbookFile = Join-Path $PlaybookDir "playbook.md"
    $content = Get-Content -Path $playbookFile -Raw

    $frontmatter = Get-Frontmatter $content
    $body = Get-Body $content

    $name = Get-YamlField $frontmatter "name"
    $title = Get-YamlField $frontmatter "title"
    $description = Get-YamlMultilineField $frontmatter "description"
    if (-not $description) { $description = Get-YamlField $frontmatter "description" }
    $version = Get-YamlField $frontmatter "version"
    if (-not $version) { $version = "1.0.0" }
    $references = Get-YamlArray $frontmatter "references"

    # Check for agents directory
    $agentsDir = Join-Path $PlaybookDir "agents"
    $hasAgents = Test-Path $agentsDir

    $recipeDir = Join-Path $OutputDir ".goose/recipes/$name"

    if ($DryRun) {
        return $recipeDir
    }

    # Create recipe directory
    New-Item -ItemType Directory -Path $recipeDir -Force | Out-Null

    # Generate recipe.yaml
    $recipe = @()
    $recipe += "version: $version"
    $recipe += "title: $title"

    if ($description -match "`n") {
        $recipe += "description: |-"
        foreach ($line in ($description -split "`n")) {
            $recipe += "  $line"
        }
    } else {
        $recipe += "description: $description"
    }

    $recipe += "instructions: |-"
    foreach ($line in ($body -split "`n")) {
        $recipe += "  $line"
    }

    # Pass through complex blocks
    @("parameters", "extensions", "activities", "settings") | ForEach-Object {
        $block = Get-YamlBlock $frontmatter $_
        if ($block) { $recipe += $block }
    }

    # Sub-recipes from references (recursive composition)
    if ($references -and $references.Count -gt 0) {
        $recipe += "sub_recipes:"
        foreach ($ref in $references) {
            $refName = Split-Path -Leaf $ref
            $recipe += "  - name: $refName"
            $recipe += "    path: `"{{ recipe_dir }}/../$refName/recipe.yaml`""
        }
    }

    $recipeFile = Join-Path $recipeDir "recipe.yaml"
    $recipe -join "`n" | Set-Content -Path $recipeFile -NoNewline

    # Copy supporting directories
    @("scripts", "references", "templates") | ForEach-Object {
        $srcDir = Join-Path $PlaybookDir $_
        if (Test-Path $srcDir) {
            Copy-Item -Path $srcDir -Destination $recipeDir -Recurse -Force
        }
    }

    # Bundle agents in recipe directory with invocation instructions
    if ($hasAgents) {
        $recipeAgentsDir = Join-Path $recipeDir "agents"
        New-Item -ItemType Directory -Path $recipeAgentsDir -Force | Out-Null
        Get-ChildItem -Path $agentsDir -Filter "*.md" -File | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $recipeAgentsDir -Force
        }

        # Create agents README with invocation instructions
        $readme = @()
        $readme += "# Subagents"
        $readme += ""
        $readme += "This recipe includes specialized agents that can be invoked via shell:"
        $readme += ""
        Get-ChildItem -Path $agentsDir -Filter "*.md" -File | ForEach-Object {
            $agentName = $_.BaseName
            $agentContent = Get-Content -Path $_.FullName -Raw
            $agentDesc = ""
            if ($agentContent -match "description:\s*(.+)") {
                $agentDesc = $Matches[1].Trim()
            }
            $readme += "- **$agentName** - $agentDesc"
        }
        $readme += ""
        $readme += "## Invocation"
        $readme += ""
        $readme += '```bash'
        $readme += '# Read agent prompt and spawn Goose with it'
        $readme += 'AGENT_PROMPT=$(cat agents/<agent-name>.md)'
        $readme += 'goose run --instructions "$AGENT_PROMPT"'
        $readme += '```'

        $readmeFile = Join-Path $recipeAgentsDir "README.md"
        $readme -join "`n" | Set-Content -Path $readmeFile -NoNewline
    }

    return $recipeDir
}

# =============================================================================
# Codex Skill Generator (OpenAI Codex CLI)
# =============================================================================

function New-CodexSkill {
    param([string]$PlaybookDir, [string]$OutputDir, [switch]$DryRun)

    $playbookFile = Join-Path $PlaybookDir "playbook.md"
    $content = Get-Content -Path $playbookFile -Raw

    $frontmatter = Get-Frontmatter $content
    $body = Get-Body $content

    $name = Get-YamlField $frontmatter "name"
    $description = Get-YamlMultilineField $frontmatter "description"
    if (-not $description) { $description = Get-YamlField $frontmatter "description" }
    $references = Get-YamlArray $frontmatter "references"

    # Check for commands and agents directories
    $commandsDir = Join-Path $PlaybookDir "commands"
    $agentsDir = Join-Path $PlaybookDir "agents"
    $hasCommands = Test-Path $commandsDir
    $hasAgents = Test-Path $agentsDir

    $skillDir = Join-Path $OutputDir ".codex/skills/$name"

    if ($DryRun) {
        return $skillDir
    }

    # Create skill directory
    New-Item -ItemType Directory -Path $skillDir -Force | Out-Null

    # Generate SKILL.md (Codex format - simpler, single-line description)
    $skill = @()
    $skill += "---"
    $skill += "name: $name"

    # Codex wants single line description, max 500 chars
    $descOneline = ($description -replace "`n", " " -replace "\s+", " ").Substring(0, [Math]::Min(500, $description.Length))
    $skill += "description: $descOneline"

    $skill += "---"
    $skill += ""
    $skill += $body

    # Add Related Skills section if references exist
    if ($references -and $references.Count -gt 0) {
        $skill += ""
        $skill += "## Related Skills"
        $skill += ""
        $skill += "This skill works with the following skills (invoke via `$skill-name):"
        $skill += ""
        foreach ($ref in $references) {
            $refName = Split-Path -Leaf $ref
            $skill += "- **`$$refName**"
        }
    }

    # Add Commands section if commands/ directory exists
    if ($hasCommands) {
        $cmdFiles = Get-ChildItem -Path $commandsDir -Filter "*.md" -File
        if ($cmdFiles.Count -gt 0) {
            $skill += ""
            $skill += "## Commands"
            $skill += ""
            $skill += "This skill includes command workflows in ``commands/`` directory:"
            $skill += ""
            foreach ($cmdFile in $cmdFiles) {
                $cmdName = [System.IO.Path]::GetFileNameWithoutExtension($cmdFile.Name)
                $cmdContent = Get-Content -Path $cmdFile.FullName -Raw
                $cmdDesc = ""
                if ($cmdContent -match "description:\s*(.+)") {
                    $cmdDesc = $Matches[1].Trim()
                }
                $skill += "- **$cmdName** - $cmdDesc"
            }
        }
    }

    # Add Agents section if agents/ directory exists
    if ($hasAgents) {
        $agentFiles = Get-ChildItem -Path $agentsDir -Filter "*.md" -File
        if ($agentFiles.Count -gt 0) {
            $skill += ""
            $skill += "## Subagents"
            $skill += ""
            $skill += "This skill includes specialized agents in ``agents/`` directory:"
            $skill += ""
            foreach ($agentFile in $agentFiles) {
                $agentName = [System.IO.Path]::GetFileNameWithoutExtension($agentFile.Name)
                $agentContent = Get-Content -Path $agentFile.FullName -Raw
                $agentDesc = ""
                if ($agentContent -match "description:\s*(.+)") {
                    $agentDesc = $Matches[1].Trim()
                }
                $skill += "- **$agentName** - $agentDesc"
            }
            $skill += ""
            $skill += "### Invoking Subagents"
            $skill += ""
            $skill += "Spawn yourself with the agent's prompt:"
            $skill += ""
            $skill += '```bash'
            $skill += 'AGENT_PROMPT=$(cat agents/<agent-name>.md)'
            $skill += 'codex --prompt "$AGENT_PROMPT"'
            $skill += '```'
        }
    }

    $skillFile = Join-Path $skillDir "SKILL.md"
    $skill -join "`n" | Set-Content -Path $skillFile -NoNewline

    # Copy supporting directories to skill
    @("scripts", "references", "templates") | ForEach-Object {
        $srcDir = Join-Path $PlaybookDir $_
        if (Test-Path $srcDir) {
            Copy-Item -Path $srcDir -Destination $skillDir -Recurse -Force
        }
    }

    # Bundle commands in skill directory
    if ($hasCommands) {
        $skillCommandsDir = Join-Path $skillDir "commands"
        New-Item -ItemType Directory -Path $skillCommandsDir -Force | Out-Null
        Get-ChildItem -Path $commandsDir -Filter "*.md" -File | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $skillCommandsDir -Force
        }
    }

    # Bundle agents in skill directory
    if ($hasAgents) {
        $skillAgentsDir = Join-Path $skillDir "agents"
        New-Item -ItemType Directory -Path $skillAgentsDir -Force | Out-Null
        Get-ChildItem -Path $agentsDir -Filter "*.md" -File | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $skillAgentsDir -Force
        }
    }

    return $skillDir
}

# =============================================================================
# Command Implementations
# =============================================================================

function Invoke-Compile {
    param([string[]]$Args)

    $playbookDir = $null
    $target = "all"
    $outputDir = "."
    $dryRun = $false

    for ($i = 0; $i -lt $Args.Count; $i++) {
        switch -Regex ($Args[$i]) {
            '^(-t|--target)$' { $target = $Args[++$i] }
            '^(-o|--output)$' { $outputDir = $Args[++$i] }
            '^(--dry-run)$' { $dryRun = $true }
            '^(-h|--help)$' {
                Write-Output "Usage: caps.ps1 compile <playbook-dir> [-Target claude|goose|codex|all] [-Output <dir>] [--dry-run]"
                return
            }
            '^-' { Write-Error "Unknown option: $($Args[$i])"; exit 1 }
            default { if (-not $playbookDir) { $playbookDir = $Args[$i] } }
        }
    }

    if (-not $playbookDir) {
        Write-Error "Playbook directory is required"
        exit 1
    }

    # Check if this is a batch compile (directory of playbooks)
    $playbookFile = Join-Path $playbookDir "playbook.md"
    if (-not (Test-Path $playbookFile)) {
        # Try batch mode - look for subdirectories with playbook.md
        $playbooks = Get-ChildItem -Path $playbookDir -Directory | Where-Object {
            Test-Path (Join-Path $_.FullName "playbook.md")
        }

        if ($playbooks.Count -eq 0) {
            Write-Error "No playbook.md found in $playbookDir or its subdirectories"
            exit 1
        }

        Write-Output ""
        Write-Output "Batch compiling playbooks in: $playbookDir"
        if ($dryRun) { Write-Output "[DRY-RUN MODE]" }

        $success = 0
        $failed = 0

        foreach ($pb in $playbooks) {
            try {
                Invoke-CompileSingle -PlaybookDir $pb.FullName -Target $target -OutputDir $outputDir -DryRun:$dryRun
                $success++
            } catch {
                Write-Output "  [FAIL] $($pb.Name): $_"
                $failed++
            }
        }

        Write-Output ""
        Write-Output "========================================"
        Write-Output "Batch Compilation Summary"
        Write-Output "========================================"
        Write-Output "Total playbooks: $($playbooks.Count)"
        Write-Output "Successful: $success"
        Write-Output "Failed: $failed"
        Write-Output ""
        return
    }

    Invoke-CompileSingle -PlaybookDir $playbookDir -Target $target -OutputDir $outputDir -DryRun:$dryRun
}

function Invoke-CompileSingle {
    param([string]$PlaybookDir, [string]$Target, [string]$OutputDir, [switch]$DryRun)

    $playbookFile = Join-Path $PlaybookDir "playbook.md"
    $content = Get-Content -Path $playbookFile -Raw
    $frontmatter = Get-Frontmatter $content
    $name = Get-YamlField $frontmatter "name"
    $title = Get-YamlField $frontmatter "title"

    if (-not $name) {
        throw "Missing required field 'name' in playbook.md"
    }

    if (-not (Test-PlaybookName $name)) {
        throw "Invalid name '$name' - must be lowercase alphanumeric with hyphens"
    }

    $scriptsDir = Join-Path $PlaybookDir "scripts"
    $refsDir = Join-Path $PlaybookDir "references"
    $scriptsCount = if (Test-Path $scriptsDir) { (Get-ChildItem $scriptsDir -File).Count } else { 0 }
    $refsCount = if (Test-Path $refsDir) { (Get-ChildItem $refsDir -File).Count } else { 0 }

    Write-Output ""
    Write-Output "Parsing playbook: $PlaybookDir"
    Write-Output "  Name: $name"
    Write-Output "  Title: $title"
    Write-Output "  Scripts: $scriptsCount"
    Write-Output "  References: $refsCount"

    if ($DryRun) {
        Write-Output ""
        Write-Output "[DRY-RUN] Would generate:"
        if ($Target -eq "claude" -or $Target -eq "all") {
            $skillDir = New-ClaudeSkill -PlaybookDir $PlaybookDir -OutputDir $OutputDir -DryRun
            Write-Output "  - $skillDir/SKILL.md"
        }
        if ($Target -eq "goose" -or $Target -eq "all") {
            $recipeDir = New-GooseRecipe -PlaybookDir $PlaybookDir -OutputDir $OutputDir -DryRun
            Write-Output "  - $recipeDir/recipe.yaml"
        }
        if ($Target -eq "codex" -or $Target -eq "all") {
            $codexDir = New-CodexSkill -PlaybookDir $PlaybookDir -OutputDir $OutputDir -DryRun
            Write-Output "  - $codexDir/SKILL.md"
        }
        return
    }

    if ($Target -eq "claude" -or $Target -eq "all") {
        Write-Output ""
        Write-Output "Compiling to Claude Code Skill..."
        $skillDir = New-ClaudeSkill -PlaybookDir $PlaybookDir -OutputDir $OutputDir
        Write-Output "  Created: $skillDir"
    }

    if ($Target -eq "goose" -or $Target -eq "all") {
        Write-Output ""
        Write-Output "Compiling to Goose Recipe..."
        $recipeDir = New-GooseRecipe -PlaybookDir $PlaybookDir -OutputDir $OutputDir
        Write-Output "  Created: $recipeDir"
    }

    if ($Target -eq "codex" -or $Target -eq "all") {
        Write-Output ""
        Write-Output "Compiling to Codex Skill..."
        $codexDir = New-CodexSkill -PlaybookDir $PlaybookDir -OutputDir $OutputDir
        Write-Output "  Created: $codexDir"
    }

    Write-Output ""
    Write-Output "Compilation complete!"
    Write-Output ""
}

function Invoke-Validate {
    param([string[]]$Args)

    $playbookDir = $null
    $checkRefs = $false

    for ($i = 0; $i -lt $Args.Count; $i++) {
        switch -Regex ($Args[$i]) {
            '^(--check-references)$' { $checkRefs = $true }
            '^(-h|--help)$' {
                Write-Output "Usage: caps.ps1 validate <playbook-dir> [--check-references]"
                return
            }
            '^-' { Write-Error "Unknown option: $($Args[$i])"; exit 1 }
            default { if (-not $playbookDir) { $playbookDir = $Args[$i] } }
        }
    }

    if (-not $playbookDir) {
        Write-Error "Playbook directory is required"
        exit 1
    }

    $playbookFile = Join-Path $playbookDir "playbook.md"
    if (-not (Test-Path $playbookFile)) {
        Write-Error "playbook.md not found in $playbookDir"
        exit 1
    }

    Write-Output ""
    Write-Output "Validating playbook: $playbookDir"
    Write-Output ""

    $content = Get-Content -Path $playbookFile -Raw
    $frontmatter = Get-Frontmatter $content
    $errors = 0

    $name = Get-YamlField $frontmatter "name"
    $title = Get-YamlField $frontmatter "title"
    $description = Get-YamlMultilineField $frontmatter "description"
    if (-not $description) { $description = Get-YamlField $frontmatter "description" }
    $references = Get-YamlArray $frontmatter "references"

    $status = if ($name) { "[PASS] $name" } else { "[FAIL] Missing required field"; $errors++ }
    Write-Output ("Name:".PadRight(20) + $status)

    $status = if ($title) { "[PASS] $title" } else { "[FAIL] Missing required field"; $errors++ }
    Write-Output ("Title:".PadRight(20) + $status)

    $status = if ($description) {
        $preview = if ($description.Length -gt 50) { $description.Substring(0, 50) + "..." } else { $description }
        "[PASS] $preview"
    } else {
        "[FAIL] Missing required field"; $errors++
    }
    Write-Output ("Description:".PadRight(20) + $status)

    $status = if (Test-PlaybookName $name) { "[PASS] Valid lowercase-hyphen format" } else { "[FAIL] Invalid format"; $errors++ }
    Write-Output ("Name Format:".PadRight(20) + $status)

    # Check directory name matches
    $dirName = Split-Path -Leaf $playbookDir
    $status = if ($dirName -eq $name) { "[PASS] Name matches directory" } else { "[FAIL] Name '$name' doesn't match directory '$dirName'"; $errors++ }
    Write-Output ("Directory Match:".PadRight(20) + $status)

    # File counts
    $scriptsDir = Join-Path $playbookDir "scripts"
    $refsDir = Join-Path $playbookDir "references"
    $scriptsCount = if (Test-Path $scriptsDir) { (Get-ChildItem $scriptsDir -File).Count } else { 0 }
    $refsCount = if (Test-Path $refsDir) { (Get-ChildItem $refsDir -File).Count } else { 0 }
    $playbookRefsCount = if ($references) { $references.Count } else { 0 }

    Write-Output ("Scripts:".PadRight(20) + "[INFO] $scriptsCount files")
    Write-Output ("References:".PadRight(20) + "[INFO] $refsCount files")
    Write-Output ("Playbook Refs:".PadRight(20) + "[INFO] $playbookRefsCount playbooks")

    # Check referenced playbooks if flag is set
    if ($checkRefs -and $references -and $references.Count -gt 0) {
        Write-Output ""
        Write-Output "Checking referenced playbooks:"
        foreach ($ref in $references) {
            $refName = Split-Path -Leaf $ref
            $refPath = Join-Path (Split-Path -Parent $playbookDir) "$refName/playbook.md"
            if (Test-Path $refPath) {
                Write-Output ("  ${refName}:".PadRight(20) + "[PASS] Found")
            } else {
                Write-Output ("  ${refName}:".PadRight(20) + "[FAIL] Not found at $ref/playbook.md")
                $errors++
            }
        }
    }

    Write-Output ""
    if ($errors -eq 0) {
        Write-Output "Validation complete! No errors found."
    } else {
        Write-Output "Validation failed with $errors error(s)."
        exit 1
    }
    Write-Output ""
}

function Invoke-New {
    param([string[]]$Args)

    $name = $null
    $outputDir = $null

    for ($i = 0; $i -lt $Args.Count; $i++) {
        switch -Regex ($Args[$i]) {
            '^(-o|--output)$' { $outputDir = $Args[++$i] }
            '^(-h|--help)$' {
                Write-Output "Usage: caps.ps1 new <playbook-name> [-Output <dir>]"
                return
            }
            '^-' { Write-Error "Unknown option: $($Args[$i])"; exit 1 }
            default { if (-not $name) { $name = $Args[$i] } }
        }
    }

    if (-not $name) {
        Write-Error "Playbook name is required"
        exit 1
    }

    $slug = ConvertTo-Slug $name
    if ($slug -ne $name) {
        Write-Output "Note: Normalized name to: $slug"
    }

    if (-not $outputDir) {
        $outputDir = if (Test-Path "playbooks") { "playbooks" } else { "." }
    }

    $playbookDir = Join-Path $outputDir $slug

    if (Test-Path $playbookDir) {
        Write-Error "Playbook directory already exists: $playbookDir"
        exit 1
    }

    if (-not (Test-Path $TemplateDir)) {
        Write-Error "CAPS template directory not found at $TemplateDir"
        exit 1
    }

    $templateFile = Join-Path $TemplateDir "playbook-template.md"
    if (-not (Test-Path $templateFile)) {
        Write-Error "Playbook template not found: $templateFile"
        exit 1
    }

    # Create directory structure
    New-Item -ItemType Directory -Path $playbookDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $playbookDir "scripts") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $playbookDir "references") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $playbookDir "commands") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $playbookDir "agents") -Force | Out-Null

    $title = ConvertTo-TitleCase $slug

    # Copy and process template
    $template = Get-Content -Path $templateFile -Raw
    $template = $template -replace '\{\{PLAYBOOK_NAME\}\}', $slug
    $template = $template -replace '\{\{PLAYBOOK_TITLE\}\}', $title
    $template = $template -replace '\{\{PLAYBOOK_DESCRIPTION\}\}', "Description of $slug"
    $template = $template -replace '\{\{TRIGGER_PHRASES\}\}', "users request $slug"

    $playbookFile = Join-Path $playbookDir "playbook.md"
    $template | Set-Content -Path $playbookFile -NoNewline

    Write-Output ""
    Write-Output "Created new CAPS playbook: $playbookDir"
    Write-Output ""
    Write-Output "Structure:"
    Write-Output "  $playbookDir/"
    Write-Output "  ├── playbook.md     # Main skill instructions"
    Write-Output "  ├── commands/       # Slash commands (optional)"
    Write-Output "  ├── agents/         # Subagents (optional)"
    Write-Output "  ├── scripts/        # Helper scripts"
    Write-Output "  └── references/     # Documentation"
    Write-Output ""
    Write-Output "Next steps:"
    Write-Output "  1. Edit $playbookDir/playbook.md"
    Write-Output "  2. Add commands to commands/, agents to agents/"
    Write-Output "  3. Run: caps.ps1 compile $playbookDir --target claude"
    Write-Output ""
}

function Invoke-Lint {
    param([string[]]$Args)

    $playbookDir = $null

    for ($i = 0; $i -lt $Args.Count; $i++) {
        switch -Regex ($Args[$i]) {
            '^(-h|--help)$' {
                Write-Output "Usage: caps.ps1 lint <playbook-dir>"
                return
            }
            '^-' { Write-Error "Unknown option: $($Args[$i])"; exit 1 }
            default { if (-not $playbookDir) { $playbookDir = $Args[$i] } }
        }
    }

    if (-not $playbookDir) {
        Write-Error "Playbook directory is required"
        exit 1
    }

    $playbookFile = Join-Path $playbookDir "playbook.md"
    if (-not (Test-Path $playbookFile)) {
        Write-Error "playbook.md not found in $playbookDir"
        exit 1
    }

    Write-Output "Linting playbook: $playbookDir"
    Write-Output ""

    $content = Get-Content -Path $playbookFile -Raw
    $frontmatter = Get-Frontmatter $content
    $body = Get-Body $content

    $warnings = 0
    $errors = 0

    $name = Get-YamlField $frontmatter "name"
    $title = Get-YamlField $frontmatter "title"
    $description = Get-YamlMultilineField $frontmatter "description"
    if (-not $description) { $description = Get-YamlField $frontmatter "description" }
    $version = Get-YamlField $frontmatter "version"
    $allowedTools = Get-YamlArray $frontmatter "allowed_tools"
    $references = Get-YamlArray $frontmatter "references"

    # Required Fields
    Write-Output "Required Fields:"
    if ($name) {
        Write-Output "  [OK] name: $name"
    } else {
        Write-Output "  [ERR] name: Missing required field"
        $errors++
    }

    if ($title) {
        Write-Output "  [OK] title: $title"
    } else {
        Write-Output "  [ERR] title: Missing required field"
        $errors++
    }

    if ($description) {
        Write-Output "  [OK] description: $($description.Length) chars"
        if ($description -notmatch 'Use when|use when|Use for|use for') {
            Write-Output "  [WARN] description: No trigger phrases found (add 'Use when...')"
            $warnings++
        }
    } else {
        Write-Output "  [ERR] description: Missing required field"
        $errors++
    }

    # Optional Fields
    Write-Output ""
    Write-Output "Optional Fields:"
    if ($version) {
        if ($version -match '^[0-9]+\.[0-9]+(\.[0-9]+)?$') {
            Write-Output "  [OK] version: $version"
        } else {
            Write-Output "  [WARN] version: '$version' is not semver format (x.y.z)"
            $warnings++
        }
    } else {
        Write-Output "  [INFO] version: Not specified (will default to 1.0.0)"
    }

    if ($allowedTools -and $allowedTools.Count -gt 0) {
        Write-Output "  [OK] allowed_tools: $($allowedTools.Count) tools defined"
    } else {
        Write-Output "  [INFO] allowed_tools: None (all tools available)"
    }

    if ($references -and $references.Count -gt 0) {
        Write-Output "  [OK] references: $($references.Count) playbooks"
    } else {
        Write-Output "  [INFO] references: None (standalone playbook)"
    }

    # Content Quality
    Write-Output ""
    Write-Output "Content Quality:"
    $lines = ($body -split "`n").Count
    if ($lines -ge 10) {
        Write-Output "  [OK] Instructions: $lines lines"
    } else {
        Write-Output "  [WARN] Instructions: Only $lines lines (consider adding more detail)"
        $warnings++
    }

    $headings = ([regex]::Matches($body, '^##\s+', 'Multiline')).Count
    if ($headings -ge 2) {
        Write-Output "  [OK] Section headings: $headings found"
    } else {
        Write-Output "  [INFO] Section headings: $headings (consider adding ## sections)"
    }

    $codeBlocks = ([regex]::Matches($body, '```')).Count / 2
    if ($codeBlocks -ge 1) {
        Write-Output "  [OK] Code blocks: $([int]$codeBlocks) found"
    } else {
        Write-Output "  [INFO] Code blocks: None (consider adding examples)"
    }

    $checklistItems = ([regex]::Matches($body, '\[\s*\]')).Count
    if ($checklistItems -ge 1) {
        Write-Output "  [OK] Validation criteria: $checklistItems checklist items"
    } else {
        Write-Output "  [INFO] Validation criteria: No checklist (consider adding [ ] items)"
    }

    # File Structure
    Write-Output ""
    Write-Output "File Structure:"
    $scriptsDir = Join-Path $playbookDir "scripts"
    $refsDir = Join-Path $playbookDir "references"

    if (Test-Path $scriptsDir) {
        $scripts = Get-ChildItem $scriptsDir -File
        Write-Output "  [OK] scripts/: $($scripts.Count) files"
    } else {
        Write-Output "  [INFO] scripts/: Not present"
    }

    if (Test-Path $refsDir) {
        $refs = Get-ChildItem $refsDir -File
        Write-Output "  [OK] references/: $($refs.Count) files"
    } else {
        Write-Output "  [INFO] references/: Not present"
    }

    # Summary
    Write-Output ""
    Write-Output "========================================"
    Write-Output "Lint Summary"
    Write-Output "========================================"
    Write-Output "Errors: $errors"
    Write-Output "Warnings: $warnings"
    Write-Output ""

    if ($errors -gt 0) {
        Write-Output "Fix errors before compiling."
        exit 1
    } elseif ($warnings -gt 0) {
        Write-Output "Consider fixing warnings for better quality."
    } else {
        Write-Output "Looking good!"
    }
    Write-Output ""
}

function Show-Help {
    Write-Output @"
CAPS - Coding Agent Playbook Spec Compiler

Reusable Intelligence Packages for AI coding agents.
Bundle skills + commands + subagents into portable playbooks.

USAGE:
    caps.ps1 <command> [options]

COMMANDS:
    new <playbook-name>        Create a new CAPS playbook from template
        -Output <dir>          Output directory (default: playbooks/)

    validate <playbook-dir>    Validate a CAPS playbook
        --check-references     Also verify referenced playbooks exist

    lint <playbook-dir>        Quality checks with warnings

    compile <playbook-dir>     Compile a CAPS playbook
        -Target <target>       Target format: claude, goose, codex, or all (default: all)
        -Output <dir>          Output directory (default: current directory)
        --dry-run              Preview what would be generated
        (pass directory of playbooks for batch compile)

    help                       Show this help message

OUTPUT:
    Claude (.claude/):  skills/, commands/, agents/
    Goose (.goose/):    recipes/ with bundled agents/
    Codex (.codex/):    skills/ with bundled commands/ and agents/

EXAMPLES:
    # Create a new playbook
    caps.ps1 new kafka-setup

    # Compile to all formats
    caps.ps1 compile playbooks/kafka-setup

    # Compile to specific target
    caps.ps1 compile playbooks/kafka-setup -Target codex

    # Batch compile all playbooks (dry-run)
    caps.ps1 compile playbooks/ --dry-run

"@
}

# =============================================================================
# Main Entry Point
# =============================================================================

switch ($Command) {
    "compile" { Invoke-Compile $Arguments }
    "validate" { Invoke-Validate $Arguments }
    "lint" { Invoke-Lint $Arguments }
    "new" { Invoke-New $Arguments }
    { $_ -in "help", "--help", "-h" } { Show-Help }
    default {
        Write-Error "Unknown command: $Command"
        Write-Output "Run 'caps.ps1 help' for usage information"
        exit 1
    }
}
