# intellicad-ai - multi-agent installer (Windows / PowerShell).
#
# One line:
#   irm https://raw.githubusercontent.com/IntelliCAD-Official/intellicad-ai/master/install.ps1 | iex
#
# Detects which AI agents are on your machine and installs intellicad-ai for
# each one using its native distribution (plugin / extension / skill / rule
# file). Skips agents that aren't installed. Safe to re-run - each underlying
# install command is idempotent.
#
# Run `install.ps1 -Help` for the full reference (flags + agent matrix).
[CmdletBinding()]
param(
  [switch]$DryRun,
  [switch]$Force,
  [switch]$List,
  [switch]$Uninstall,
  [switch]$Detect,
  [switch]$NoColor,
  [switch]$Help,
  [string]$RepoUrlOverride,
  [string]$RepoBranchOverride,
  [string[]]$Only = @()
)
$ErrorActionPreference = "Stop"
$GitHubRawBase = "https://raw.githubusercontent.com"
$GitHubRepoName = "IntelliCAD-Official/intellicad-ai"
$GitHubRaw = "$GitHubRawBase/$GitHubRepoName/master"
$RepoUrl = "https://github.com/$GitHubRepoName.git"
if (-not [string]::IsNullOrWhiteSpace($RepoUrlOverride)) {
  $RepoUrl = $RepoUrlOverride
} elseif (-not [string]::IsNullOrWhiteSpace($RepoBranchOverride)) {
  $GitHubRaw = "$GitHubRawBase/$GitHubRepoName/$RepoBranchOverride"
  $RepoUrl = $RepoUrl + "#$RepoBranchOverride"
}
# ── Help ────────────────────────────────────────────────────────────────────
if ($Help) {
@"
intellicad-ai installer - detects your agents and installs intellicad-ai for each.
USAGE
  install.ps1 [-DryRun] [-Force] [-Only <agent>[,<agent>]] [-List] [-NoColor]
  install.ps1 -Uninstall [-DryRun] [-Only <agent>[,<agent>]] [-NoColor]
  install.ps1 -Detect [-Only <agent>[,<agent>]] [-NoColor]
  irm $GitHubRaw/install.ps1 | iex
FLAGS
  -DryRun          Print what would run, do nothing.
  -Force           Re-run even if a target reports "already installed".
  -Only <list>     Comma-separated agent ids. Repeatable / array.
  -List            Print the full provider matrix and exit.
  -NoColor         Disable ANSI color codes.
  -Uninstall       Remove intellicad-ai from all detected agents instead of installing.
  -Detect          Check whether all supported agents (or those in -Only) are
                   installed. Exits 0 if all are detected, 1 if any are missing.
                   Does not install or modify anything.
EXAMPLES
  install.ps1
  install.ps1 -DryRun
  install.ps1 -Only claude
  install.ps1 -Only claude,codex
  install.ps1 -List
  install.ps1 -Detect
  install.ps1 -Detect -Only claude,codex
  install.ps1 -Uninstall
  install.ps1 -Uninstall -DryRun
  install.ps1 -Uninstall -Only claude,codex
URLS THE INSTALLER MAY FETCH FROM
  $GitHubRaw/install.ps1
"@ | Write-Host
  exit 0
}
# ── Color helpers ──────────────────────────────────────────────────────────
$Esc = [char]27
function Say($msg) {
  if ($NoColor) { Write-Host $msg }
  else { Write-Host "$Esc[38;5;172m$msg$Esc[0m" }
}
function Note($msg) {
  if ($NoColor) { Write-Host $msg }
  else { Write-Host "$Esc[2m$msg$Esc[0m" }
}
function Warn($msg) {
  if ($NoColor) { Write-Host $msg }
  else { Write-Host "$Esc[31m$msg$Esc[0m" }
}
function Ok($msg) {
  if ($NoColor) { Write-Host $msg }
  else { Write-Host "$Esc[32m$msg$Esc[0m" }
}
# ── State ───────────────────────────────────────────────────────────────────
$OnlyList = @()
foreach ($o in $Only) {
  foreach ($x in ($o -split ',')) {
    $t = $x.Trim()
    if ($t) {
      $OnlyList += $t
    }
  }
}
$InstalledIds   = @()
$UninstalledIds = @()
$SkippedIds     = @()
$SkippedWhy     = @()
$FailedIds      = @()
$FailedWhy      = @()
$DetectedCount  = 0
function Want([string]$id) {
  if ($OnlyList.Count -eq 0) { return $true }
  return $OnlyList -contains $id
}
function Has-Cmd([string]$c) {
  return [bool](Get-Command $c -ErrorAction SilentlyContinue)
}
# ── Run helpers ─────────────────────────────────────────────────────────────
# Run a process, return $true if exit 0. Honors -DryRun. Errors do not throw.
# `$Args` is an automatic in PowerShell - name the param `$Argv` to avoid the
# implicit-collision warning under strict analysis.
function Try-Run {
  param([string]$Exe, [string[]]$Argv)
  if ($DryRun) {
    Note "  would run: $Exe $($Argv -join ' ')"
    return $true
  }
  Write-Host "  $ $Exe $($Argv -join ' ')"
  try {
    & $Exe @Argv
    return ($LASTEXITCODE -eq 0)
  } catch {
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    return $false
  }
}
function Record-Installed([string]$id)   { $script:InstalledIds   += $id }
function Record-Uninstalled([string]$id) { $script:UninstalledIds += $id }
function Record-Skipped([string]$id, [string]$why) {
  $script:SkippedIds += $id
  $script:SkippedWhy += $why
}
function Record-Failed([string]$id, [string]$why) {
  $script:FailedIds += $id
  $script:FailedWhy += $why
}
# Resolve a detect spec.
# Spec strings use $HOME / $env:HOME tokens that we expanded at build time -
# they're already absolute by the time they reach this function.
function Resolve-DetectSpec([string]$spec) {
  if ([string]::IsNullOrWhiteSpace($spec)) { return $false }
  foreach ($clause in ($spec -split '\|\|')) {
    $c = $clause.Trim()
    if (-not $c) { continue }
    if ($c -match '^command:(.+)$')          { if (Has-Cmd $matches[1]) { return $true } }
    elseif ($c -match '^dir:(.+)$')          { if (Test-Path $matches[1] -PathType Container) { return $true } }
    elseif ($c -match '^file:(.+)$')         { if (Test-Path $matches[1] -PathType Leaf) { return $true } }
  }
  return $false
}
# ── Provider matrix ──────────────────────
# Columns:
#   id, label, profile (npx-skills slug or empty for non-skills), detect,
#   soft (1 = config-dir-only probe, no CLI on PATH).
$Providers = @(
  @{ id='claude';      label='Claude Code';        profile='';             detect='command:claude'; soft=0 },
  #@{ id='gemini';      label='Gemini CLI';         profile='';             detect='command:gemini'; soft=0 },
  @{ id='codex';       label='Codex CLI';          profile='';             detect='command:codex'; soft=0 }
  #@{ id='opencode';    label='OpenCode';           profile='opencode';     detect="command:opencode||file:$HOME\.config\opencode\AGENTS.md"; soft=0 },
  #@{ id='antigravity'; label='Google Antigravity'; profile='antigravity';  detect="dir:$HOME\.gemini\antigravity"; soft=1 }
)
# ── -List output ────────────────────────────────────────────────────────────
if ($List) {
  Say "  intellicad-ai provider matrix"
  Write-Host ""
  Write-Host ("  {0,-13} {1,-22} {2}" -f "ID", "AGENT", "INSTALL MECHANISM")
  Write-Host ("  {0,-13} {1,-22} {2}" -f "----", "-----", "-----------------")
  foreach ($p in $Providers) {
    if ([string]::IsNullOrEmpty($p.profile)) {
      $mech = if ($p.id -eq 'claude') { 'claude plugin install' }
              elseif ($p.id -eq 'gemini') { 'gemini extensions install' }
              elseif ($p.id -eq 'codex') { 'codex plugin install' }
              else { '' }
    } else {
      $mech = "npx skills add ($($p.profile))"
    }
    if ($p.soft -eq 1) { $mech += ' (soft)' }
    Write-Host ("  {0,-13} {1,-22} {2}" -f $p.id, $p.label, $mech)
  }
  Write-Host ""
  Note "  Detection probes per agent live in install.ps1 \$Providers."
  Note "  Soft entries detect via config-dir presence only (no CLI on PATH)."
  exit 0
}
# ── -Detect ─────────────────────────────────────────────────────────────────
# Check whether all targeted agents are present on this machine.
# Exits 0 if every targeted provider is detected, 1 if any are missing.
# Does not install, modify, or download anything.
if ($Detect) {
  Say "  intellicad-ai - agent detection check"
  Note "  $RepoUrl"
  Write-Host ""
  $allFound = $true
  $checked  = 0
  foreach ($p in $Providers) {
    if (-not (Want $p.id)) { continue }
    $checked++
    $found = Resolve-DetectSpec $p.detect
    if ($found) {
      Ok   ("  [found]   {0} ({1})" -f $p.id, $p.label)
    } else {
      Warn ("  [missing] {0} ({1})" -f $p.id, $p.label)
      $allFound = $false
    }
  }
  Write-Host ""
  if ($checked -eq 0) {
    Warn "  no providers matched (check -Only list or use -List to see supported agents)"
    exit 1
  }
  if ($allFound) {
    Ok "  all detected - exit 0"
    exit 0
  } else {
    Warn "  one or more agents missing - exit 1"
    exit 1
  }
}
# ── Banner ──────────────────────────────────────────────────────────────────
Say "  intellicad-ai $(if ($Uninstall) { 'uninstaller' } else { 'installer' })"
Note "  $RepoUrl"
if ($DryRun) { Note "  (dry run - nothing will be written)" }
Write-Host ""
# ── Per-agent install functions ─────────────────────────────────────────────
function Install-Claude {
  $script:DetectedCount++
  Say "-> Claude Code detected"
  $pluginDone = $false
  $alreadyInstalled = $false
  if (-not $Force) {
    try {
      $list = & claude plugin list 2>$null
      if ($list -match "(?i)intellicad-ai") { $alreadyInstalled = $true }
    } catch {}
  }
  if ($alreadyInstalled) {
    Note "  intellicad-ai plugin already installed (use -Force to reinstall)"
    Record-Skipped "claude" "plugin already installed"
    $pluginDone = $true
  } else {
    if ((Try-Run "claude" @("plugin", "marketplace", "add", $RepoUrl)) -and
        (Try-Run "claude" @("plugin", "install", "intellicad-ai@intellicad-ai"))) {
      Record-Installed "claude"
      $pluginDone = $true
    } else {
      Record-Failed "claude" "claude plugin install failed"
    }
  }
  Write-Host ""
}
function Install-Codex {
  $script:DetectedCount++
  Say "-> Codex detected"
  $pluginDone = $false
  $alreadyInstalled = $false
  if (-not $Force) {
    try {
      $list = & codex plugin list 2>$null
      if ($list -match "(?i)intellicad-ai") { $alreadyInstalled = $true }
    } catch {}
  }
  if ($alreadyInstalled) {
    Note "  intellicad-ai plugin already installed (use -Force to reinstall)"
    Record-Skipped "codex" "plugin already installed"
    $pluginDone = $true
  } else {
    if ((Try-Run "codex" @("plugin", "marketplace", "add", $RepoUrl)) -and
        (Try-Run "codex" @("plugin", "add", "intellicad-ai@intellicad-ai"))) {
      Record-Installed "codex"
      $pluginDone = $true
    } else {
      Record-Failed "codex" "codex plugin install failed"
    }
  }
  Write-Host ""
}
function Install-Gemini {
  $script:DetectedCount++
  Say "-> Gemini CLI detected"
  $alreadyInstalled = $false
  if (-not $Force) {
    try {
      $list = & gemini extensions list 2>$null
      if ($list -match "(?i)intellicad-ai") { $alreadyInstalled = $true }
    } catch {}
  }
  if ($alreadyInstalled) {
    Note "  intellicad-ai extension already installed (use -Force to reinstall)"
    Record-Skipped "gemini" "extension already installed"
  } else {
    if (Try-Run "gemini" @("extensions", "install", $RepoUrl)) {
      Record-Installed "gemini"
    } else {
      Record-Failed "gemini" "gemini extensions install failed"
    }
  }
  Write-Host ""
}
# ── Per-agent uninstall functions ────────────────────────────────────────────
function Uninstall-Claude {
  $script:DetectedCount++
  Say "-> Claude Code detected"
  $isInstalled = $false
  try {
    $list = & claude plugin list 2>$null
    if ($list -match "(?i)intellicad-ai") { $isInstalled = $true }
  } catch {}
  if (-not $isInstalled -and -not $Force) {
    Note "  intellicad-ai plugin is not installed - nothing to remove"
    Record-Skipped "claude" "plugin not installed"
  } else {
    if ((Try-Run "claude" @("plugin", "uninstall", "intellicad-ai@intellicad-ai")) -and
        (Try-Run "claude" @("plugin", "marketplace", "remove", "intellicad-ai"))) {
      Record-Uninstalled "claude"
    } else {
      Record-Failed "claude" "claude plugin uninstall failed"
    }
  }
  Write-Host ""
}
function Uninstall-Codex {
  $script:DetectedCount++
  Say "-> Codex detected"
  $isInstalled = $false
  try {
    $list = & codex plugin list 2>$null
    if ($list -match "(?i)intellicad-ai") { $isInstalled = $true }
  } catch {}
  if (-not $isInstalled -and -not $Force) {
    Note "  intellicad-ai plugin is not installed - nothing to remove"
    Record-Skipped "codex" "plugin not installed"
  } else {
    if ((Try-Run "codex" @("plugin", "remove", "intellicad-ai@intellicad-ai")) -and
        (Try-Run "codex" @("plugin", "marketplace", "remove", "intellicad-ai"))) {
      Record-Uninstalled "codex"
    } else {
      Record-Failed "codex" "codex plugin uninstall failed"
    }
  }
  Write-Host ""
}
function Uninstall-Gemini {
  $script:DetectedCount++
  Say "-> Gemini CLI detected"
  $isInstalled = $false
  try {
    $list = & gemini extensions list 2>$null
    if ($list -match "(?i)intellicad-ai") { $isInstalled = $true }
  } catch {}
  if (-not $isInstalled -and -not $Force) {
    Note "  intellicad-ai extension is not installed - nothing to remove"
    Record-Skipped "gemini" "extension not installed"
  } else {
    if (Try-Run "gemini" @("extensions", "uninstall", "intellicad-ai")) {
      Record-Uninstalled "gemini"
    } else {
      Record-Failed "gemini" "gemini extensions uninstall failed"
    }
  }
  Write-Host ""
}
# ── Run the install / uninstall loop ────────────────────────────────────────
foreach ($p in $Providers) {
  if (-not (Want $p.id)) { continue }
  if (-not (Resolve-DetectSpec $p.detect)) { continue }
  if ($Uninstall) {
    switch ($p.id) {
      'claude' { Uninstall-Claude }
      'gemini' { Uninstall-Gemini }
      'codex'  { Uninstall-Codex }
      default  { Record-Failed $p.id "uninstall function is missing" }
    }
  } else {
    switch ($p.id) {
      'claude' { Install-Claude }
      'gemini' { Install-Gemini }
      'codex'  { Install-Codex }
      default  { Record-Failed $p.id "install function is missing" }
    }
  }
}
# ── Summary ────────────────────────────────────────────────────────────────
Write-Host ""
Say "  done"
if ($InstalledIds.Count -gt 0) {
  Ok "  installed:"
  foreach ($a in $InstalledIds) { Write-Host "    - $a" }
}
if ($UninstalledIds.Count -gt 0) {
  Ok "  uninstalled:"
  foreach ($a in $UninstalledIds) { Write-Host "    - $a" }
}
if ($SkippedIds.Count -gt 0) {
  Write-Host "  skipped:"
  for ($i = 0; $i -lt $SkippedIds.Count; $i++) {
    Write-Host ("    - {0} - {1}" -f $SkippedIds[$i], $SkippedWhy[$i])
  }
}
if ($FailedIds.Count -gt 0) {
  Warn "  failed:"
  for ($i = 0; $i -lt $FailedIds.Count; $i++) {
    Warn ("    - {0} - {1}" -f $FailedIds[$i], $FailedWhy[$i])
  }
}
if ($InstalledIds.Count -eq 0 -and $UninstalledIds.Count -eq 0 -and $SkippedIds.Count -eq 0 -and $FailedIds.Count -eq 0) {
  Write-Host "  nothing detected. install one of: claude, codex"
  Write-Host "  or pass -Only <agent> to force a specific target (see -List for the full matrix)"
}
Write-Host ""
if (-not $Uninstall) {
  Note "  start any session, run IntelliCAD, activate a drawing and ask a question related to IntelliCAD, query your drawing information, ask to select entities or run /lisp-developer in Claude Code to create and execute a LISP program in IntelliCAD"
}
Note "  uninstall: install.ps1 -Uninstall"
# Exit non-zero only when EVERY detected agent failed (and at least one was
# detected). Skips don't count as failure.
if ($DetectedCount -gt 0 -and $InstalledIds.Count -eq 0 -and $UninstalledIds.Count -eq 0 -and $SkippedIds.Count -eq 0) {
  exit 1
}
exit 0
