### README — Claude Code Environment Setup

#### Overview
This PowerShell script bootstraps a Claude Code development environment by optionally installing:
- Global npm packages: happy-coder, claudekit
- Claude MCP servers: aceternityui, playwright, context7
- Claude agents (Markdown configs) into %USERPROFILE%\.claude\agents
- Claude commands (Markdown configs) into %USERPROFILE%\.claude\commands

It is idempotent where possible: existing packages/files are detected and skipped.

Script URL:
- Raw: https://raw.githubusercontent.com/mattes337/claude-setup/refs/heads/main/setup.ps1

#### Options
- -y (switch): Auto-accept all per-item prompts within install/download loops.
  - Example: .\setup.ps1 -y
  - Important: If the Claude CLI is not found, the script still prompts “Continue anyway? (y/n)” even with -y.

#### Requirements
- PowerShell 5.1+ (Windows) or PowerShell 7+ (pwsh on macOS/Linux)
- Node.js/npm installed and on PATH (required for npm/npx steps)
- Internet access
- Optional but recommended: Claude Code CLI (claude) on PATH for MCP/agent/command registration

#### What the script does (at a glance)
1) Loads dependencies.yaml from the repo (download only).
2) Installs global npm packages (if not already installed):
   - happy-coder (npm i -g happy-coder)
   - claudekit (npm install -g claudekit)
3) Adds Claude MCP servers (if Claude CLI is available and not already added):
   - aceternityui → npx aceternityui-mcp
   - playwright → npx @playwright/mcp@latest
   - context7 → npx -y @upstash/context7-mcp
4) Downloads agent files to %USERPROFILE%\.claude\agents and installs them globally with claude agent add --global:
   - milestone-analyst.md
   - milestone-reviewer.md
   - milestone-tester.md
   - stage-milestone-orchestrator.md
   - tdd-development-agent.md
   - ui-designer.md
5) Downloads command files to %USERPROFILE%\.claude\commands and installs them globally with claude command add --global:
   - milestone.md
   - plan.md
   - worktrees.md

#### Quick start

- Direct one-liner (runs immediately; review before executing):
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
iex "& { $(irm 'https://raw.githubusercontent.com/mattes337/claude-setup/refs/heads/main/setup.ps1') } -y"
```

- Download first (safer: allows inspection), then run:
```powershell
iwr -useb 'https://raw.githubusercontent.com/mattes337/claude-setup/refs/heads/main/setup.ps1' -outfile setup.ps1
# Inspect setup.ps1 if you like, then:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
.\setup.ps1 -y
```

- Without -y (you’ll be prompted for each item):
```powershell
.\setup.ps1
```

- From Windows CMD:
```cmd
powershell -NoProfile -ExecutionPolicy Bypass -Command "iwr -useb 'https://raw.githubusercontent.com/mattes337/claude-setup/refs/heads/main/setup.ps1' -outfile setup.ps1; .\setup.ps1 -y"
```

- From macOS/Linux (PowerShell 7 installed as pwsh):
```bash
pwsh -NoProfile -c "iwr -useb 'https://raw.githubusercontent.com/mattes337/claude-setup/refs/heads/main/setup.ps1' -outfile setup.ps1; ./setup.ps1 -y"
```

#### Behavior details
- Execution policy: The examples scope a bypass to the current process to avoid changing machine-level policy.
- Auto-yes mode (-y):
  - Applies to: Installing npm packages, adding MCP servers, downloading agent/command files.
  - Does not apply to: The “Continue anyway? (y/n)” prompt when Claude CLI is missing.
- Checks for existing installs/files:
  - npm packages: Detected with npm list -g --depth=0; already-installed packages are skipped.
  - MCP servers: Detected via claude mcp list and name match.
  - Agents/commands: If the target file already exists in %USERPROFILE%\.claude\agents or %USERPROFILE%\.claude\commands, it is skipped.
- Post-download install:
  - If claude CLI is available, each downloaded agent/command is registered globally (claude agent add --global, claude command add --global).

#### Verifying installation
- npm:
```powershell
npm list -g --depth=0 | findstr happy-coder
npm list -g --depth=0 | findstr claudekit
```
- Claude MCP:
```powershell
claude mcp list
```
- Agents/commands on disk:
```powershell
ls $env:USERPROFILE\.claude\agents
ls $env:USERPROFILE\.claude\commands
```

#### Troubleshooting
- “npm is not installed”: Install Node.js (which includes npm) and ensure it’s on PATH. Restart the terminal.
- “Claude CLI is not installed or not in PATH”: Install the Claude Code CLI and reopen the terminal, or choose “y” when asked to continue without it. MCP/agent/command registration requires the CLI.
- Permission errors on global npm installs: Run an elevated PowerShell (Run as Administrator) on Windows, or configure npm’s global prefix to a user-writable directory.
- Corporate proxies/firewalls: Set the appropriate proxy for PowerShell and npm (e.g., $env:HTTP_PROXY, npm config set proxy …).

#### Uninstall/cleanup (manual)
- Global npm packages:
```powershell
npm uninstall -g happy-coder
npm uninstall -g claudekit
```
- Remove downloaded agent/command files:
```powershell
Remove-Item -Recurse -Force $env:USERPROFILE\.claude\agents
Remove-Item -Recurse -Force $env:USERPROFILE\.claude\commands
```
- Deregister in Claude (if needed):
```powershell
claude agent list
claude agent remove --global <agent-name-or-path>
claude command list
claude command remove --global <command-name-or-path>
```

#### Security note
Always review scripts before executing, especially when using pipe-to-iex. Prefer downloading and inspecting first.

If you want, I can also save this as README.md in your workspace.