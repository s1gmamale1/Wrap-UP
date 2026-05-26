#requires -version 5
<#
  Wrap-UP installer (Windows / PowerShell). Copies (or symlinks) the canonical
  wrap-up.md into each AI tool's command/skill location. One source of truth.

    ./install.ps1                                  # all four tools, user-global, copy
    ./install.ps1 -Tools claude,gemini             # subset
    ./install.ps1 -Project C:\path\to\repo         # project-scoped copies instead of ~
    ./install.ps1 -Link                            # symlink (needs Developer Mode / admin)
#>
[CmdletBinding()]
param(
  [string[]]$Tools = @("claude","codex","gemini","opencode"),
  [string]$Project = "",
  [switch]$Link
)
$ErrorActionPreference = "Stop"
$Src = Join-Path $PSScriptRoot "wrap-up.md"
if (-not (Test-Path -LiteralPath $Src)) { throw "wrap-up.md not found next to installer" }

function Get-Body {
  $lines = Get-Content -LiteralPath $Src
  $dash = 0; $body = [System.Collections.Generic.List[string]]::new()
  foreach ($l in $lines) {
    if ($l -match '^---\s*$') { $dash++; continue }
    if ($dash -ge 2) { $body.Add($l) }
  }
  if ($dash -lt 2) { return ($lines -join "`n") }   # no frontmatter -> whole file
  return ($body -join "`n")
}
function Get-Desc {
  foreach ($l in (Get-Content -LiteralPath $Src)) {
    if ($l -match '^description:\s*(.*)$') { return $Matches[1] }
  }
  return ""
}
function Ensure-Dir([string]$f) { New-Item -ItemType Directory -Force -Path (Split-Path -Parent $f) | Out-Null }

function Place([string]$target, [string]$mode) {
  Ensure-Dir $target
  if ($mode -eq "body") {
    Set-Content -LiteralPath $target -Value (Get-Body) -Encoding UTF8
  } elseif ($Link) {
    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Force }
    New-Item -ItemType SymbolicLink -Path $target -Target $Src | Out-Null
  } else {
    Copy-Item -LiteralPath $Src -Destination $target -Force
  }
  Write-Host "  [ok] $target"
}
function New-GeminiToml([string]$target) {
  Ensure-Dir $target
  $toml = "description = '{0}'`nprompt = '''`n{1}`n'''`n" -f (Get-Desc), (Get-Body)
  Set-Content -LiteralPath $target -Value $toml -Encoding UTF8
  Write-Host "  [ok] $target (generated)"
}

if ($Project) {
  $claude   = Join-Path $Project ".claude/skills/wrap-up/SKILL.md"
  $gemini   = Join-Path $Project ".gemini/commands/wrap-up.toml"
  $opencode = Join-Path $Project ".opencode/command/wrap-up.md"
} else {
  $claude   = Join-Path $HOME ".claude/skills/wrap-up/SKILL.md"
  $gemini   = Join-Path $HOME ".gemini/commands/wrap-up.toml"
  $opencode = Join-Path $HOME ".config/opencode/command/wrap-up.md"
}
$codex = Join-Path $HOME ".codex/prompts/wrap-up.md"   # Codex prompts are user-global only

$set = $Tools | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ }
Write-Host ("Installing wrap-up ({0}) ->" -f $(if ($Link) { "symlink" } else { "copy" }))
if ($set -contains "claude")   { Place $claude   "full" }
if ($set -contains "codex")    { Place $codex    "body" }
if ($set -contains "gemini")   { New-GeminiToml $gemini }
if ($set -contains "opencode") { Place $opencode "full" }
Write-Host "Done. Run /wrap-up in any installed tool."
