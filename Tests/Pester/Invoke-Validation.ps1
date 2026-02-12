# Placeholder - tutor will supply later.
# Tests\Pester\Invoke-Validation.ps1
# COM5411 Generic Pester Test Handler
#
# Purpose:
#   Run Pester tests in a predictable way.
#   - Default: run all *.Tests.ps1 under Tests\Pester (recursively)
#   - Optional: pass one or more test files/folders as arguments
#   - Writes an NUnitXml result file into Evidence\Pester for commit-friendly evidence
#
# Usage (from repo root):
#   .\Tests\Pester\Invoke-Validation.ps1
#   .\Tests\Pester\Invoke-Validation.ps1 .\Tests\Pester\Baseline\Baseline-Extras.Tests.ps1
#   .\Tests\Pester\Invoke-Validation.ps1 .\Tests\Pester\Baseline\ .\Tests\Pester\AD\
#   .\Tests\Pester\Invoke-Validation.ps1 -Output Detailed
#   .\Tests\Pester\Invoke-Validation.ps1 -NoResultFile
#
# Notes:
#   - Accepts files or folders. Folders are searched for *.Tests.ps1 recursively.
#   - Any non-existent path fails fast with a clear error.
#   - Requires Pester v5+.

[CmdletBinding()]
param(
  # One or more test files or folders. If omitted, runs everything under Tests\Pester.
  [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
  [string[]]$Paths,

  # Pester output verbosity.
  [ValidateSet('None','Normal','Detailed','Diagnostic')]
  [string]$Output = 'Detailed',

  # Write a result file into Evidence\Pester (NUnitXml) unless disabled.
  [switch]$NoResultFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-TestTargets {
  param(
    [string[]]$InputPaths,
    [string]$ScriptRoot  # PESTER v5 FIX: Pass in $PSScriptRoot from script level
                             # Inside functions, $MyInvocation doesn't have .Path property
  )

  $testsRoot = $ScriptRoot
  $testsRootNormalized = (Resolve-Path -Path $testsRoot).Path.TrimEnd('\') + '\'

  # Default: all tests under Tests\Pester, excluding this runner file itself.
  if (-not $InputPaths -or $InputPaths.Count -eq 0) {
    # PESTER v5 FIX: Hardcode the script name since $MyInvocation isn't available in functions
    $runnerName = 'Invoke-Validation.ps1'
    $all = Get-ChildItem -Path $testsRoot -Recurse -File -Filter '*.Tests.ps1' |
      Where-Object { $_.Name -ne $runnerName } |
      Select-Object -ExpandProperty FullName
    return $all
  }

  $targets = New-Object System.Collections.Generic.List[string]

  foreach ($p in $InputPaths) {
    $resolved = $null
    try {
      $resolved = Resolve-Path -Path $p -ErrorAction Stop
    } catch {
      if (-not [System.IO.Path]::IsPathRooted($p)) {
        $candidate = Join-Path -Path $testsRoot -ChildPath $p
        $resolved = Resolve-Path -Path $candidate -ErrorAction SilentlyContinue
      }
      if (-not $resolved) {
        throw "Test paths must be valid file or folder paths (absolute or relative to Tests\\Pester). Not found: $p"
      }
    }

    foreach ($item in $resolved) {
      $full = $item.Path
      $fullNormalized = (Resolve-Path -Path $full).Path
      if (-not $fullNormalized.StartsWith($testsRootNormalized, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Test paths must be under $testsRoot. Not allowed: $full"
      }
      if (Test-Path -Path $full -PathType Leaf) {
        if ($full -notmatch '\.Tests\.ps1$') {
          throw "Test file must end with .Tests.ps1: $full"
        }
        $targets.Add($full)
        continue
      }

      if (Test-Path -Path $full -PathType Container) {
        $found = Get-ChildItem -Path $full -Recurse -File -Filter '*.Tests.ps1' |
          Select-Object -ExpandProperty FullName
        foreach ($f in $found) { $targets.Add($f) }
        continue
      }

      throw "Path is neither file nor folder: $full"
    }
  }

  if ($targets.Count -eq 0) {
    throw "No *.Tests.ps1 files found for the provided paths."
  }

  # De-dupe while preserving order.
  $seen = @{}
  $deduped = foreach ($t in $targets) {
    if (-not $seen.ContainsKey($t)) { $seen[$t] = $true; $t }
  }

  # PESTER v5 FIX: Wrap in @() to ensure it's always an array (even with 1 item)
  # Otherwise .Count property won't exist and script will fail
  return @($deduped)
}

# Locate repo root by walking up until we see Run_BuildMain.ps1 (your repo contract).
function Find-RepoRoot {
  $start = (Resolve-Path '.').Path
  $cur = $start
  while ($true) {
    if (Test-Path -Path (Join-Path $cur 'Run_BuildMain.ps1') -PathType Leaf) { return $cur }
    $parent = Split-Path -Parent $cur
    if ($parent -eq $cur -or [string]::IsNullOrWhiteSpace($parent)) { break }
    $cur = $parent
  }
  # Fallback: current directory.
  return $start
}

$repoRoot = Find-RepoRoot
# PESTER v5 FIX: Cast to [array] so .Count property always works (even with single item)
[array]$testFiles = Resolve-TestTargets -InputPaths $Paths -ScriptRoot $PSScriptRoot

Write-Host "Pester runner:"
Write-Host "  Repo root:  $repoRoot"
Write-Host "  Test count: $($testFiles.Count)"
Write-Host "  Output:     $Output"

# Evidence output directory
$evidenceDir = Join-Path -Path $repoRoot -ChildPath 'Evidence\Pester'
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$resultPath = Join-Path -Path $evidenceDir -ChildPath "PesterResults_$timestamp.xml"

# Build Pester config
$cfg = New-PesterConfiguration
$cfg.Run.Path = $testFiles
$cfg.Output.Verbosity = $Output
$cfg.Run.Exit = $true  # non-zero exit code on failures (useful in automation)

if (-not $NoResultFile) {
  $cfg.TestResult.Enabled = $true
  $cfg.TestResult.OutputPath = $resultPath
  # PESTER v5 FIX: Property is 'OutputFormat' not 'Format'
  $cfg.TestResult.OutputFormat = 'NUnitXml'
  Write-Host "  Results:    $resultPath"
} else {
  Write-Host "  Results:    disabled"
}

Invoke-Pester -Configuration $cfg

