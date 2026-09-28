#requires -Version 5.1
<#
.SYNOPSIS
  Clone or pull all WebCorp migrated site repos into the current user's Projects folder.

.DESCRIPTION
  Target layout:
    C:\Users\<you>\Projects\<domain>\

  Repos live under GitHub org: webcorpg/<domain>

  First run: git clone
  Later runs: git pull --ff-only (falls back to pull if ff-only fails)

.EXAMPLE
  # Double-click clone-all-sites.cmd, or:
  powershell -ExecutionPolicy Bypass -File .\clone-all-sites.ps1

.EXAMPLE
  # Custom Projects root + SSH remotes
  .\clone-all-sites.ps1 -ProjectsRoot "D:\Sites" -UseSsh
#>
[CmdletBinding()]
param(
  [string]$ProjectsRoot = (Join-Path $env:USERPROFILE "Projects"),
  [string]$GitHubOrg = "webcorpg",
  [switch]$UseSsh,
  [string]$DomainsFile = ""
)

$ErrorActionPreference = "Stop"

function Get-Domains {
  param([string]$Path)
  if ($Path -and (Test-Path -LiteralPath $Path)) {
    return Get-Content -LiteralPath $Path |
      ForEach-Object { $_.Trim() } |
      Where-Object { $_ -and ($_ -notmatch '^\s*#') }
  }

  # Fallback list (kept in sync with repo domains.txt)
  @(
    "albaalmare.com"
    "bluesea-kalyves.com"
    "casaarmoniazakynthos.com"
    "dianaparasxi.gr"
    "eliastudioszakynthos.com"
    "estiasiscatering.com"
    "familymarketzante.com"
    "galasvilla.gr"
    "gkalogerias.gr"
    "gounelis.gr"
    "islandretreats.gr"
    "ixoxromazakynthos.gr"
    "kipivillage.com"
    "loukouloschania.gr"
    "magnoliazakynthos.com"
    "mareasuiteszante.gr"
    "marrymeinzante.com"
    "milkhoneyresidence.gr"
    "movida.gr"
    "mtidesign.gr"
    "myprivatekitchen.gr"
    "onarresidence.gr"
    "perlabeachvilla.com"
    "roulagouskou.gr"
    "sanleonzante.com"
    "soleilvillas.gr"
    "stravopodis.gr"
    "varrestennisclub.gr"
    "villa-phoenix.com"
    "windmillrestovasilikos.com"
    "yakinthosflowers.gr"
    "zanteskysuites.com"
    "zoupanou.gr"
    "albadorozante.gr"
    "delphisdigital.com"
    "deckboatrentals.gr"
  )
}

function Get-RepoUrl {
  param([string]$Domain)
  if ($UseSsh) {
    return "git@github.com:${GitHubOrg}/${Domain}.git"
  }
  return "https://github.com/${GitHubOrg}/${Domain}.git"
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Error "git is not installed or not on PATH. Install Git for Windows first: https://git-scm.com/download/win"
}

# Prefer domains.txt next to this script, then sibling ../domains.txt
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $DomainsFile) {
  $candidates = @(
    (Join-Path $scriptDir "domains.txt"),
    (Join-Path (Split-Path -Parent $scriptDir) "domains.txt")
  )
  foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c) { $DomainsFile = $c; break }
  }
}

$domains = @(Get-Domains -Path $DomainsFile)
if ($domains.Count -eq 0) {
  Write-Error "No domains found."
}

New-Item -ItemType Directory -Force -Path $ProjectsRoot | Out-Null

Write-Host "Projects root : $ProjectsRoot"
Write-Host "GitHub org    : $GitHubOrg"
Write-Host "Auth mode     : $(if ($UseSsh) { 'SSH' } else { 'HTTPS' })"
Write-Host "Domains       : $($domains.Count)"
Write-Host ""

$ok = 0
$fail = 0
$skipped = 0

foreach ($domain in $domains) {
  $target = Join-Path $ProjectsRoot $domain
  $repoUrl = Get-RepoUrl -Domain $domain

  Write-Host "==== $domain ====" -ForegroundColor Cyan

  try {
    if (Test-Path -LiteralPath (Join-Path $target ".git")) {
      Write-Host "PULL  $target"
      Push-Location -LiteralPath $target
      try {
        git pull --ff-only 2>$null
        if ($LASTEXITCODE -ne 0) {
          git pull
          if ($LASTEXITCODE -ne 0) { throw "git pull failed (exit $LASTEXITCODE)" }
        }
      } finally {
        Pop-Location
      }
      Write-Host "OK    pulled" -ForegroundColor Green
      $ok++
    }
    elseif (Test-Path -LiteralPath $target) {
      $items = Get-ChildItem -LiteralPath $target -Force -ErrorAction SilentlyContinue
      if ($items -and $items.Count -gt 0) {
        Write-Host "SKIP  folder exists and is not a git repo: $target" -ForegroundColor Yellow
        $skipped++
      } else {
        Write-Host "CLONE $repoUrl"
        git clone $repoUrl $target
        if ($LASTEXITCODE -ne 0) { throw "git clone failed (exit $LASTEXITCODE)" }
        Write-Host "OK    cloned" -ForegroundColor Green
        $ok++
      }
    }
    else {
      Write-Host "CLONE $repoUrl"
      git clone $repoUrl $target
      if ($LASTEXITCODE -ne 0) { throw "git clone failed (exit $LASTEXITCODE)" }
      Write-Host "OK    cloned" -ForegroundColor Green
      $ok++
    }
  }
  catch {
    Write-Host "FAIL  $domain — $_" -ForegroundColor Red
    $fail++
  }

  Write-Host ""
}

Write-Host "==== DONE ===="
Write-Host "OK=$ok  FAIL=$fail  SKIP=$skipped  root=$ProjectsRoot"

if ($fail -gt 0) { exit 1 }
exit 0
