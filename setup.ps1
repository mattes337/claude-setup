# Claude Code Environment Setup Script
# This script sets up Claude Code with dependencies, MCP servers, agents, and commands

param(
    [switch]$y  # Auto-yes to all prompts
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Claude Code Environment Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($y) {
    Write-Host "Auto-yes mode enabled (-y flag detected)" -ForegroundColor Yellow
    Write-Host ""
}

# Function to check if a command exists
function Test-CommandExists {
    param($CommandName)
    try {
        Get-Command $CommandName -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Function to check if npm package is installed globally
function Test-NpmPackageInstalled {
    param($PackageName)
    $installedPackages = npm list -g --depth=0 2>$null
    return $installedPackages -match $PackageName
}

# Function to download file from GitHub
function Download-GitHubFile {
    param(
        [string]$Url,
        [string]$OutputPath
    )
    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing
        return $true
    } catch {
        Write-Host "Failed to download: $Url" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

# Step 1: Load and parse dependencies.yaml
Write-Host "Step 1: Loading dependencies configuration..." -ForegroundColor Yellow
$yamlUrl = "https://raw.githubusercontent.com/mattes337/claude-setup/refs/heads/main/dependencies.yaml"
$tempYamlPath = "$env:TEMP\claude-dependencies.yaml"

try {
    Invoke-WebRequest -Uri $yamlUrl -OutFile $tempYamlPath -UseBasicParsing
    Write-Host "Dependencies configuration loaded successfully." -ForegroundColor Green
    
    # Parse YAML content (simple parsing for this specific structure)
    $yamlContent = Get-Content $tempYamlPath -Raw
    
} catch {
    Write-Host "Failed to load dependencies.yaml" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Install NPM dependencies
Write-Host "`nStep 2: Installing NPM dependencies..." -ForegroundColor Yellow

# Check if npm is installed
if (-not (Test-CommandExists "npm")) {
    Write-Host "npm is not installed. Please install Node.js first." -ForegroundColor Red
    exit 1
}

# NPM packages to install
$npmPackages = @(
    @{Name="happy-coder"; Command="npm i -g happy-coder"},
    @{Name="claudekit"; Command="npm install -g claudekit"}
)

foreach ($package in $npmPackages) {
    Write-Host "`nChecking $($package.Name)..." -ForegroundColor Cyan
    
    if (Test-NpmPackageInstalled $package.Name) {
        Write-Host "$($package.Name) is already installed. Skipping..." -ForegroundColor Green
    } else {
        if ($y) {
            $install = 'y'
        } else {
            $install = Read-Host "Install $($package.Name)? (y/n)"
        }
        if ($install -eq 'y') {
            Write-Host "Installing $($package.Name)..." -ForegroundColor Yellow
            Invoke-Expression $package.Command
            if ($LASTEXITCODE -eq 0) {
                Write-Host "$($package.Name) installed successfully." -ForegroundColor Green
            } else {
                Write-Host "Failed to install $($package.Name)" -ForegroundColor Red
            }
        } else {
            Write-Host "Skipping $($package.Name) installation." -ForegroundColor Gray
        }
    }
}

# Step 3: Install MCP servers in Claude Code
Write-Host "`nStep 3: Installing MCP servers..." -ForegroundColor Yellow

# Check if claude command exists
if (-not (Test-CommandExists "claude")) {
    Write-Host "Claude CLI is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Please ensure Claude Code CLI is installed and available." -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y') {
        exit 1
    }
} else {
    # MCP servers to install
    $mcpServers = @(
        @{Name="aceternityui"; Command="npx aceternityui-mcp"},
        @{Name="playwright"; Command="npx @playwright/mcp@latest"},
        @{Name="context7"; Command="npx -y @upstash/context7-mcp"}
    )
    
    foreach ($server in $mcpServers) {
        Write-Host "`nChecking MCP server: $($server.Name)..." -ForegroundColor Cyan
        
        # Check if already installed (this is a simple check, may need adjustment)
        $mcpList = claude mcp list 2>$null
        if ($mcpList -match $server.Name) {
            Write-Host "$($server.Name) MCP server is already installed. Skipping..." -ForegroundColor Green
        } else {
            if ($y) {
                $install = 'y'
            } else {
                $install = Read-Host "Install $($server.Name) MCP server? (y/n)"
            }
            if ($install -eq 'y') {
                Write-Host "Installing $($server.Name) MCP server..." -ForegroundColor Yellow
                claude mcp add $server.Name $server.Command
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "$($server.Name) MCP server installed successfully." -ForegroundColor Green
                } else {
                    Write-Host "Failed to install $($server.Name) MCP server" -ForegroundColor Red
                }
            } else {
                Write-Host "Skipping $($server.Name) MCP server installation." -ForegroundColor Gray
            }
        }
    }
}

# Step 4: Download and install agent files
Write-Host "`nStep 4: Downloading agent files..." -ForegroundColor Yellow

$agents = @(
    "milestone-analyst.md",
    "milestone-reviewer.md",
    "milestone-tester.md",
    "stage-milestone-orchestrator.md",
    "tdd-development-agent.md",
    "ui-designer.md"
)

# Create agents directory if it doesn't exist
$agentsDir = "$env:USERPROFILE\.claude\agents"
if (-not (Test-Path $agentsDir)) {
    New-Item -ItemType Directory -Path $agentsDir -Force | Out-Null
    Write-Host "Created agents directory: $agentsDir" -ForegroundColor Green
}

foreach ($agent in $agents) {
    $agentUrl = "https://raw.githubusercontent.com/mattes337/claude-setup/main/agents/$agent"
    $outputPath = Join-Path $agentsDir $agent
    
    if (Test-Path $outputPath) {
        Write-Host "$agent already exists. Skipping..." -ForegroundColor Green
    } else {
        if ($y) {
            $download = 'y'
        } else {
            $download = Read-Host "Download agent $agent? (y/n)"
        }
        if ($download -eq 'y') {
            Write-Host "Downloading $agent..." -ForegroundColor Yellow
            if (Download-GitHubFile -Url $agentUrl -OutputPath $outputPath) {
                Write-Host "$agent downloaded successfully." -ForegroundColor Green
                
                # Install agent globally in Claude Code
                if (Test-CommandExists "claude") {
                    claude agent add --global $outputPath 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "$agent installed globally in Claude Code." -ForegroundColor Green
                    }
                }
            }
        } else {
            Write-Host "Skipping $agent download." -ForegroundColor Gray
        }
    }
}

# Step 5: Download and install command files
Write-Host "`nStep 5: Downloading command files..." -ForegroundColor Yellow

$commands = @(
    "milestone.md",
    "plan.md",
    "worktrees.md"
)

# Create commands directory if it doesn't exist
$commandsDir = "$env:USERPROFILE\.claude\commands"
if (-not (Test-Path $commandsDir)) {
    New-Item -ItemType Directory -Path $commandsDir -Force | Out-Null
    Write-Host "Created commands directory: $commandsDir" -ForegroundColor Green
}

foreach ($command in $commands) {
    $commandUrl = "https://raw.githubusercontent.com/mattes337/claude-setup/main/commands/$command"
    $outputPath = Join-Path $commandsDir $command
    
    if (Test-Path $outputPath) {
        Write-Host "$command already exists. Skipping..." -ForegroundColor Green
    } else {
        if ($y) {
            $download = 'y'
        } else {
            $download = Read-Host "Download command $command? (y/n)"
        }
        if ($download -eq 'y') {
            Write-Host "Downloading $command..." -ForegroundColor Yellow
            if (Download-GitHubFile -Url $commandUrl -OutputPath $outputPath) {
                Write-Host "$command downloaded successfully." -ForegroundColor Green
                
                # Install command globally in Claude Code
                if (Test-CommandExists "claude") {
                    claude command add --global $outputPath 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "$command installed globally in Claude Code." -ForegroundColor Green
                    }
                }
            }
        } else {
            Write-Host "Skipping $command download." -ForegroundColor Gray
        }
    }
}

# Cleanup
if (Test-Path $tempYamlPath) {
    Remove-Item $tempYamlPath -Force
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nYour Claude Code environment has been configured with:" -ForegroundColor Yellow
Write-Host "- NPM dependencies" -ForegroundColor White
Write-Host "- MCP servers" -ForegroundColor White
Write-Host "- Agent files in: $agentsDir" -ForegroundColor White
Write-Host "- Command files in: $commandsDir" -ForegroundColor White
Write-Host "`nNote: Some installations may require restarting your terminal or Claude Code." -ForegroundColor Yellow