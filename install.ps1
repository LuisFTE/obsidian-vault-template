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

# --- Virtualization ------------------------------------------------------

Write-Step "Checking hardware virtualization..."

$virtEnabled = $false
try {
    $cpu = Get-WmiObject -Class Win32_Processor -ErrorAction Stop
    $virtEnabled = $cpu.VirtualizationFirmwareEnabled
} catch {}

# Fallback: parse systeminfo output
if (-not $virtEnabled) {
    $sysinfo = systeminfo 2>&1 | Select-String "Virtualization Enabled In Firmware"
    if ($sysinfo -match "Yes") { $virtEnabled = $true }
}

if (-not $virtEnabled) {
    Write-Host ""
    Write-Warn "Hardware virtualization does not appear to be enabled."
    Write-Host ""
    Write-Host "WSL2 requires Intel VT-x or AMD-V to be enabled in your BIOS/UEFI."
    Write-Host ""
    Write-Host "How to enable it:"
    Write-Host "  1. Restart your PC and enter BIOS/UEFI setup"
    Write-Host "     (usually Del, F2, F10, or F12 during boot — check your PC's brand)"
    Write-Host "  2. Look for: Virtualization Technology, Intel VT-x, AMD-V, or SVM Mode"
    Write-Host "  3. Set it to Enabled"
    Write-Host "  4. Save and exit, then re-run this script"
    Write-Host ""
    Write-Host "Common BIOS locations:"
    Write-Host "  Intel: Advanced -> CPU Configuration -> Intel Virtualization Technology"
    Write-Host "  AMD:   Advanced -> CPU Configuration -> SVM Mode"
    Write-Host ""
    $continue = Read-Host "Continue anyway? Only do this if you know virtualization is already on (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") { exit 1 }
} else {
    Write-Ok "Hardware virtualization is enabled"
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
