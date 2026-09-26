[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $OutputPath,

  [switch] $Offline
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot ".." -Resolve)).Path
$source = Get-Content -Raw (Join-Path $repoRoot "grammar-source.json") | ConvertFrom-Json
$revision = [string]$source.revision
$cacheRoot = Join-Path ([System.IO.Path]::GetTempPath()) "lithe-jenkinsfile-grammar-$revision"
$grammarRoot = Join-Path $cacheRoot "source"
$resolvedOutput = if ([System.IO.Path]::IsPathRooted($OutputPath)) { [System.IO.Path]::GetFullPath($OutputPath) } else { [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath)) }
$checksumPath = "$resolvedOutput.sha256"

function Invoke-NativeChecked {
  param(
    [Parameter(Mandatory = $true)][string] $File,
    [Parameter(Mandatory = $true)][string[]] $Arguments
  )

  & $File @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Command failed with exit code $LASTEXITCODE`: $File $($Arguments -join ' ')"
  }
}

if (-not (Test-Path -LiteralPath $grammarRoot)) {
  if ($Offline) {
    throw "Offline build requested but verified grammar cache is missing: $grammarRoot"
  }

  New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null
  Invoke-NativeChecked -File "git" -Arguments @(
    "clone", "--filter=blob:none", "--no-checkout", $source.repository, $grammarRoot
  )
}

$actualRevision = (& git -C $grammarRoot rev-parse HEAD 2>$null).Trim()
if ($actualRevision -ne $revision) {
  Invoke-NativeChecked -File "git" -Arguments @("-C", $grammarRoot, "fetch", "--depth", "1", "origin", $revision)
  Invoke-NativeChecked -File "git" -Arguments @("-C", $grammarRoot, "checkout", "--detach", $revision)
  $actualRevision = (& git -C $grammarRoot rev-parse HEAD).Trim()
}
if ($actualRevision -ne $revision) {
  throw "Grammar cache revision mismatch. Expected $revision, got $actualRevision."
}

Invoke-NativeChecked -File "git" -Arguments @("-C", $grammarRoot, "checkout", "--detach", $revision)
$grammarDirectory = Join-Path $grammarRoot ([string]$source.grammarPath)
$outputDirectory = Split-Path -Parent $resolvedOutput
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
  throw "npx is required to build the pinned Tree-sitter grammar."
}

Invoke-NativeChecked -File "npx" -Arguments @(
  "--no-install", "tree-sitter", "build", "--wasm",
  "--output", $resolvedOutput, $grammarDirectory
)

$hash = (Get-FileHash -LiteralPath $resolvedOutput -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath $checksumPath -Value "$hash  $(Split-Path -Leaf $resolvedOutput)" -Encoding ascii
Write-Output "Built $resolvedOutput"
Write-Output "SHA256 $hash"
