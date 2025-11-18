#!/usr/bin/env pwsh
# build-workflow.ps1
# Build and package Command Workflows for local testing and distribution
# This is a user-friendly wrapper around create-release-packages.sh

[CmdletBinding()]
param(
    [string]$Agent = "",
    [string]$Script = "",
    [string]$Version = "dev",
    [string]$Output = ".genreleases",
    [switch]$Json,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

# Supported agents and script types
$SUPPORTED_AGENTS = @('claude', 'gemini', 'copilot', 'cursor-agent', 'qwen', 'opencode', 'windsurf', 'codex', 'kilocode', 'auggie', 'codebuddy', 'roo', 'q', 'amp')
$SUPPORTED_SCRIPTS = @('sh', 'ps')

# Show help if requested
if ($Help) {
    Write-Host "Usage: ./build-workflow.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Build and package Command Workflows for testing and distribution."
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Agent <name>      Build for specific agent (default: all)"
    Write-Host "                     Supported: $($SUPPORTED_AGENTS -join ', ')"
    Write-Host ""
    Write-Host "  -Script <sh|ps>    Build for specific script type (default: both)"
    Write-Host "                     sh  = Bash scripts (Linux/macOS)"
    Write-Host "                     ps  = PowerShell scripts (Windows)"
    Write-Host ""
    Write-Host "  -Version <ver>     Version string (default: dev)"
    Write-Host "                     Format: v0.0.0 or 'dev' for development"
    Write-Host ""
    Write-Host "  -Output <dir>      Output directory (default: .genreleases)"
    Write-Host ""
    Write-Host "  -Json              Output results as JSON"
    Write-Host ""
    Write-Host "  -Help              Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  ./build-workflow.ps1                                        # Build all agents, all scripts"
    Write-Host "  ./build-workflow.ps1 -Agent claude -Script sh              # Build Claude with bash only"
    Write-Host "  ./build-workflow.ps1 -Agent gemini -Version v1.0.0-test    # Build Gemini with test version"
    Write-Host "  ./build-workflow.ps1 -Script ps                            # Build all agents with PowerShell only"
    Write-Host ""
    exit 0
}

# Validate agent
function Test-Agent {
    param([string]$AgentName)

    if ([string]::IsNullOrEmpty($AgentName)) {
        return $true  # Empty means all agents
    }

    if ($SUPPORTED_AGENTS -contains $AgentName) {
        return $true
    }

    Write-Error "Invalid agent '$AgentName'. Supported agents: $($SUPPORTED_AGENTS -join ', ')"
    exit 1
}

# Validate script type
function Test-ScriptType {
    param([string]$ScriptType)

    if ([string]::IsNullOrEmpty($ScriptType)) {
        return $true  # Empty means all script types
    }

    if ($SUPPORTED_SCRIPTS -contains $ScriptType) {
        return $true
    }

    Write-Error "Invalid script type '$ScriptType'. Supported script types: $($SUPPORTED_SCRIPTS -join ', ')"
    exit 1
}

# Validate version format
function Test-Version {
    param([string]$Ver)

    # Allow 'dev' as special case
    if ($Ver -eq 'dev') {
        return $true
    }

    # Check for v0.0.0 format (exact format required by create-release-packages.sh)
    if ($Ver -match '^v\d+\.\d+\.\d+$') {
        return $true
    }

    Write-Error "Invalid version format '$Ver'. Version must be 'dev' or match pattern: v0.0.0 (e.g., v1.0.0, v2.5.3). Note: Version suffixes like -beta or -dev are not supported"
    exit 1
}

# Print colored message (only if not in JSON mode)
function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )

    if (-not $Json) {
        Write-Host $Message -ForegroundColor $Color
    }
}

# Find repository root
function Find-RepositoryRoot {
    param(
        [string]$StartDir = (Get-Location),
        [string[]]$Markers = @('.git', '.specify', '.github')
    )

    $current = Resolve-Path $StartDir
    while ($true) {
        foreach ($marker in $Markers) {
            $markerPath = Join-Path $current $marker
            if (Test-Path $markerPath) {
                return $current
            }
        }
        $parent = Split-Path $current -Parent
        if ($parent -eq $current) {
            # Reached filesystem root without finding markers
            return $null
        }
        $current = $parent
    }
}

# Build packages using create-release-packages.sh
function Invoke-BuildPackages {
    param(
        [string]$RepoRoot,
        [string]$BuildVersion
    )

    $buildScript = Join-Path $RepoRoot ".github/workflows/scripts/create-release-packages.sh"

    if (-not (Test-Path $buildScript)) {
        Write-Error "Build script not found: $buildScript"
        exit 1
    }

    # Convert 'dev' to proper version format for the build script
    $actualVersion = $BuildVersion
    if ($BuildVersion -eq 'dev') {
        $actualVersion = 'v0.0.0'
    }

    # Change to repo root
    Push-Location $RepoRoot

    try {
        # Set environment variables for the build script
        if (-not [string]::IsNullOrEmpty($Agent)) {
            $env:AGENTS = $Agent
        }

        if (-not [string]::IsNullOrEmpty($Script)) {
            $env:SCRIPTS = $Script
        }

        # Run the build script
        Write-ColorMessage "Building packages..." -Color Cyan

        # Execute the bash script using bash (assuming bash is available)
        if ($Json) {
            & bash $buildScript $actualVersion 2>&1 | Out-Null
        } else {
            & bash $buildScript $actualVersion
        }

        if ($LASTEXITCODE -ne 0) {
            throw "Build script failed with exit code $LASTEXITCODE"
        }

    } finally {
        # Clean up environment variables
        if ($env:AGENTS) { Remove-Item Env:\AGENTS -ErrorAction SilentlyContinue }
        if ($env:SCRIPTS) { Remove-Item Env:\SCRIPTS -ErrorAction SilentlyContinue }

        Pop-Location
    }
}

# Collect build results
function Get-BuildResults {
    param(
        [string]$OutputDir
    )

    $results = @()

    # Determine which agents and scripts were built
    $agentsToCheck = if ([string]::IsNullOrEmpty($Agent)) { $SUPPORTED_AGENTS } else { @($Agent) }
    $scriptsToCheck = if ([string]::IsNullOrEmpty($Script)) { $SUPPORTED_SCRIPTS } else { @($Script) }

    # Check for built packages
    foreach ($ag in $agentsToCheck) {
        foreach ($sc in $scriptsToCheck) {
            $packageDir = Join-Path $OutputDir "sdd-$ag-package-$sc"
            $archive = Join-Path $OutputDir "spec-kit-template-$ag-$sc.zip"

            if (Test-Path $packageDir) {
                $results += @{
                    agent = $ag
                    script = $sc
                    path = $packageDir
                    archive = $archive
                }
            }
        }
    }

    return $results
}

# Output results as JSON
function Write-JsonOutput {
    param(
        [array]$Packages
    )

    $output = @{
        status = "success"
        version = $Version
        output_dir = $Output
        packages = $Packages
    }

    $output | ConvertTo-Json -Compress
}

# Output results in human-readable format
function Write-HumanOutput {
    param(
        [array]$Packages
    )

    Write-Host ""
    Write-ColorMessage "✓ Build completed successfully!" -Color Green
    Write-Host ""
    Write-ColorMessage "Version: $Version" -Color Cyan
    Write-ColorMessage "Output Directory: $Output" -Color Cyan
    Write-Host ""
    Write-ColorMessage "Built Packages:" -Color Cyan

    foreach ($pkg in $Packages) {
        Write-Host ""
        Write-ColorMessage "  • Agent: $($pkg.agent) ($($pkg.script))" -Color Green
        Write-Host "    Location: $($pkg.path)"
    }

    Write-Host ""
    Write-ColorMessage "Next Steps:" -Color Yellow
    Write-Host "  1. Test the package:"
    Write-ColorMessage "     Copy-Item -Recurse $Output/sdd-<agent>-package-<script>/* /path/to/test-project/" -Color Cyan
    Write-Host ""
    Write-Host "  2. Test your commands in the test project:"
    Write-ColorMessage "     /sp.your-command" -Color Cyan
    Write-Host ""
}

# Main execution
function Main {
    # Validate inputs
    Test-Agent $Agent | Out-Null
    Test-ScriptType $Script | Out-Null
    Test-Version $Version | Out-Null

    # Find repository root
    $repoRoot = Find-RepositoryRoot
    if (-not $repoRoot) {
        Write-Error "Could not find repository root. Make sure you're in a spec-kit-plus repository."
        exit 1
    }

    # Build packages
    try {
        Invoke-BuildPackages -RepoRoot $repoRoot -BuildVersion $Version
    } catch {
        if ($Json) {
            @{
                status = "error"
                message = "Build failed: $_"
            } | ConvertTo-Json -Compress
        } else {
            Write-ColorMessage "✗ Build failed: $_" -Color Red
        }
        exit 1
    }

    # Collect and output results
    $packages = Get-BuildResults -OutputDir $Output

    if ($packages.Count -eq 0) {
        if ($Json) {
            @{
                status = "error"
                message = "No packages were built"
            } | ConvertTo-Json -Compress
        } else {
            Write-ColorMessage "✗ No packages were built" -Color Red
        }
        exit 1
    }

    if ($Json) {
        Write-JsonOutput -Packages $packages
    } else {
        Write-HumanOutput -Packages $packages
    }
}

# Run main function
Main
