<#
.SYNOPSIS
  Read-only Git preflight probe. Produces a compact JSON report about one
  repository or directory without modifying any Git state.

.DESCRIPTION
  Accepts a path (default: current directory) and reports: canonical root,
  bare/non-bare, branch or detached state, HEAD, upstream, ahead/behind,
  tracked/staged/unstaged/untracked counts, worktree count, stash count,
  .gitmodules presence, and a safe submodule status summary.

  Safety contract:
  - Read-only: only git commands with no write side effects are invoked.
  - Never prints remote URLs, configuration values, or file contents.
  - Handled states (invalid path, not a Git repository, missing probes) are
    reported as JSON with ok=false and exit code 0.
  - Exit code is nonzero only for a real execution failure that prevented
    producing a report (e.g. git not found, catastrophic error).

.PARAMETER Path
  Directory to probe. Defaults to the current directory.

.EXAMPLE
  powershell -NoProfile -File git_preflight.ps1 -Path C:\work\repo
#>
param(
  [Parameter(Position = 0)]
  [string]$Path = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
# PowerShell 7 can promote a native program's non-zero exit into a terminating
# error before the script can inspect $LASTEXITCODE. Git uses non-zero exits for
# ordinary probe states (for example, "not a repository" or "no upstream"), so
# keep native exit handling explicit and deterministic in this read-only probe.
if (Test-Path -LiteralPath 'variable:PSNativeCommandUseErrorActionPreference') {
  $PSNativeCommandUseErrorActionPreference = $false
}
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$Report = @{
  ok                 = $false
  error              = $null
  tool               = 'git_preflight'
  version            = '1.0.0'
  path               = $null
  canonical_root     = $null
  bare               = $null
  branch             = $null
  detached           = $null
  head               = $null
  unborn             = $null
  upstream           = $null
  ahead              = $null
  behind             = $null
  status             = $null
  worktrees          = $null
  stashes            = $null
  gitmodules_present = $null
  submodules         = $null
  warnings           = @()
}

function Write-Report {
  $Report | ConvertTo-Json -Compress -Depth 6
}

function Add-Warning {
  param([string]$Message)
  $Report.warnings += $Message
}

function Invoke-Git {
  param([string[]]$GitArgs)
  # Runs a read-only git command against the target path. Git prints expected
  # probe misses (not-a-repository, no-upstream, unborn HEAD) to stderr. Under
  # Windows PowerShell, ErrorActionPreference='Stop' can promote that stderr to
  # a terminating NativeCommandError before $LASTEXITCODE is inspected, so
  # suppress error-record promotion only for this bounded native probe.
  $previousErrorAction = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'SilentlyContinue'
    $out = & git -C $Report.path @GitArgs 2>$null
    $exitCode = $LASTEXITCODE
  }
  finally {
    $ErrorActionPreference = $previousErrorAction
  }
  if ($exitCode -ne 0) { return $null }
  return ($out -join "`n").Trim()
}

try {
  $Report.path = [System.IO.Path]::GetFullPath($Path)

  if (-not (Test-Path -LiteralPath $Report.path -PathType Container)) {
    $Report.error = 'path-not-found-or-not-a-directory'
    Write-Report
    exit 0
  }

  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git executable not found on PATH'
  }

  # --- repository discovery (read-only) -------------------------------------
  $gitDir = Invoke-Git @('rev-parse', '--absolute-git-dir')
  if ($null -eq $gitDir) {
    $Report.error = 'not-a-git-repository'
    Write-Report
    exit 0
  }

  $bareRaw = Invoke-Git @('rev-parse', '--is-bare-repository')
  $Report.bare = ($bareRaw -eq 'true')

  if (-not $Report.bare) {
    $topLevel = Invoke-Git @('rev-parse', '--show-toplevel')
    if ($null -ne $topLevel) { $Report.canonical_root = $topLevel }
    else { $Report.canonical_root = $gitDir }
  } else {
    $Report.canonical_root = $gitDir
  }

  # --- branch / HEAD --------------------------------------------------------
  $branch = Invoke-Git @('symbolic-ref', '--short', '-q', 'HEAD')
  $Report.detached = ($null -eq $branch)
  $Report.branch = $branch

  $head = Invoke-Git @('rev-parse', 'HEAD')
  if ($null -eq $head) {
    $Report.head = $null
    $Report.unborn = $true
  } else {
    $Report.head = $head
    $Report.unborn = $false
  }

  # --- upstream / ahead-behind ----------------------------------------------
  $upstream = Invoke-Git @('rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{upstream}')
  if ($null -ne $upstream) {
    $Report.upstream = $upstream
    $counts = Invoke-Git @('rev-list', '--left-right', '--count', 'HEAD...@{upstream}')
    if ($null -ne $counts) {
      $parts = $counts -split "`t"
      if ($parts.Count -ge 2) {
        $null = [int]::TryParse($parts[0], [ref]$Report.ahead)
        $null = [int]::TryParse($parts[1], [ref]$Report.behind)
      }
    } else {
      Add-Warning 'ahead/behind unavailable (unborn HEAD or unusual history)'
    }
  }

  # --- status counts (read-only porcelain) ----------------------------------
  $statusLines = & git -C $Report.path status --porcelain=v1 2>$null
  if ($LASTEXITCODE -ne 0) {
    Add-Warning 'git status failed; counts unavailable'
  } else {
    if ($null -eq $statusLines) { $statusLines = @() }
    elseif ($statusLines -isnot [array]) { $statusLines = @($statusLines) }
    $staged = 0; $unstaged = 0; $untracked = 0; $tracked = 0
    foreach ($line in $statusLines) {
      if ($line.Length -lt 2) { continue }
      $codes = $line.Substring(0, 2)
      if ($codes -eq '??') {
        $untracked++
      } else {
        $tracked++
        if ($codes[0] -ne ' ' -and $codes[0] -ne '?') { $staged++ }
        if ($codes[1] -ne ' ' -and $codes[1] -ne '?') { $unstaged++ }
      }
    }
    $Report.status = @{
      tracked_changes = $tracked
      staged          = $staged
      unstaged        = $unstaged
      untracked       = $untracked
    }
  }

  # --- worktree count -------------------------------------------------------
  $wtLines = & git -C $Report.path worktree list --porcelain 2>$null
  if ($LASTEXITCODE -eq 0 -and $null -ne $wtLines) {
    if ($wtLines -isnot [array]) { $wtLines = @($wtLines) }
    $Report.worktrees = @($wtLines | Where-Object { $_ -like 'worktree *' }).Count
  } else {
    Add-Warning 'worktree count unavailable'
  }

  # --- stash count ----------------------------------------------------------
  $stashLines = & git -C $Report.path stash list 2>$null
  if ($LASTEXITCODE -eq 0) {
    if ($null -eq $stashLines) { $Report.stashes = 0 }
    else {
      if ($stashLines -isnot [array]) { $stashLines = @($stashLines) }
      $Report.stashes = $stashLines.Count
    }
  } else {
    Add-Warning 'stash count unavailable'
  }

  # --- .gitmodules presence and safe submodule summary ----------------------
  $Report.gitmodules_present = $false
  if (-not $Report.bare -and $null -ne $Report.canonical_root) {
    $Report.gitmodules_present = Test-Path -LiteralPath (Join-Path $Report.canonical_root '.gitmodules')
  }
  if ($Report.gitmodules_present) {
    $smLines = & git -C $Report.path submodule status 2>$null
    if ($LASTEXITCODE -eq 0 -and $null -ne $smLines) {
      if ($smLines -isnot [array]) { $smLines = @($smLines) }
      $Report.submodules = @()
      foreach ($sm in $smLines) {
        if ($sm.Length -lt 42) { continue }
        $stateChar = $sm.Substring(0, 1)
        $sha = $sm.Substring(1, 40)
        $rest = $sm.Substring(41).Trim()
        if ($rest -match '^(.*?) \(.+\)$') { $rest = $Matches[1] }
        $state = switch ($stateChar) {
          ' ' { 'clean' }
          '+' { 'different-commit' }
          '-' { 'not-initialized' }
          'U' { 'conflict' }
          default { 'unknown' }
        }
        $Report.submodules += @{ path = $rest; sha = $sha; state = $state }
      }
    } else {
      Add-Warning 'submodule status unavailable'
    }
  }

  $Report.ok = $true
  Write-Report
  exit 0
}
catch {
  # Real execution failure: report to stderr, exit nonzero.
  $err = @{
    ok      = $false
    error   = 'execution-failure'
    message = $_.Exception.Message
    path    = $Report.path
  } | ConvertTo-Json -Compress
  try { [Console]::Error.WriteLine($err) } catch { }
  exit 1
}
