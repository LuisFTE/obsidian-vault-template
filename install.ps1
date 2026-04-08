# =============================================================================
# Obsidian Vault — Windows Bootstrap
# Run this in PowerShell as Administrator.
# Installs WSL2 + Ubuntu if needed, then hands off to install.sh inside WSL.
# =============================================================================

$ErrorActionPreference = "Stop"

function Write-Step  { Write-Host "-> $args" -ForegroundColor Cyan }
function Write-Ok    { Write-Host "v  $args" -ForegroundColor Green }
function Write-Warn  { Write-Host "!  $args" -ForegroundColor Yellow }
function Write-Fail  { Write-Host "x  $args" -ForegroundColor Red }

Write-Host ""
Write-Host "=== Obsidian Second Brain - Windows Setup ===" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ""

# --- Must be admin -------------------------------------------------------

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Fail "Run this script as Administrator."
    Write-Host "Right-click PowerShell -> 'Run as administrator', then try again."
    exit 1
}

# --- Check Windows version (WSL2 needs Win 10 2004+ / Win 11) -----------

$build = [System.Environment]::OSVersion.Version.Build
if ($build -lt 19041) {
    Write-Fail "WSL2 requires Windows 10 version 2004 (build 19041) or later."
    Write-Host "Current build: $build. Please update Windows first."
    exit 1
}

# --- WSL -----------------------------------------------------------------

$wslInstalled = $false
try {
    $wslStatus = wsl --status 2>&1
    if ($LASTEXITCODE -eq 0) { $wslInstalled = $true }
} catch {}

if (-not $wslInstalled) {
    Write-Step "Installing WSL2 with Ubuntu..."
    wsl --install --distribution Ubuntu
    Write-Host ""
    Write-Warn "WSL installed. A restart is required."
    Write-Host ""
    Write-Host "After restarting:"
    Write-Host "  1. Ubuntu will open and ask you to create a Linux username/password"
    Write-Host "  2. Once at the Linux prompt, run:"
    Write-Host ""
    Write-Host '     bash <(curl -fsSL https://raw.githubusercontent.com/LuisFTE/obsidian-vault-template/main/install.sh)' -ForegroundColor Yellow
    Write-Host ""
    $restart = Read-Host "Restart now? (y/N)"
    if ($restart -eq "y" -or $restart -eq "Y") {
        Restart-Computer -Force
    }
    exit 0
}

Write-Ok "WSL2 is installed"

# --- Check Ubuntu is available -------------------------------------------

$distros = wsl --list --quiet 2>&1
$hasUbuntu = $distros | Where-Object { $_ -match "Ubuntu" }

if (-not $hasUbuntu) {
    Write-Step "Installing Ubuntu..."
    wsl --install --distribution Ubuntu
    Write-Host ""
    Write-Warn "Ubuntu installed. Open Ubuntu from the Start menu to finish setup"
    Write-Host "(create a Linux username/password), then come back and re-run this script."
    exit 0
}

Write-Ok "Ubuntu is available"

# --- Check WSL2 (not WSL1) -----------------------------------------------

$defaultVersion = (wsl --status 2>&1 | Select-String "Default Version").ToString() -replace ".*:\s*", ""
if ($defaultVersion -eq "1") {
    Write-Step "Upgrading WSL default to version 2..."
    wsl --set-default-version 2
    wsl --set-version Ubuntu 2
}

Write-Ok "WSL2 confirmed"
Write-Host ""

# --- Hand off to install.sh inside WSL -----------------------------------

Write-Step "Launching install.sh inside WSL..."
Write-Host ""

wsl --distribution Ubuntu -- bash -c '
    bash <(curl -fsSL https://raw.githubusercontent.com/LuisFTE/obsidian-vault-template/main/install.sh)
'
