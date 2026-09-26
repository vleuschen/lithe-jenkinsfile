[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)] [string] $Version,
  [Parameter(Mandatory = $true)] [string] $OutputDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$out = if ([System.IO.Path]::IsPathRooted($OutputDirectory)) { [System.IO.Path]::GetFullPath($OutputDirectory) } else { [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputDirectory)) }
$stageRoot = Join-Path ([System.IO.Path]::GetTempPath()) "lithe-jenkinsfile-release-$Version"
$stage = Join-Path $stageRoot "lithe-jenkinsfile-$Version"
if (Test-Path $stageRoot) { Remove-Item -LiteralPath $stageRoot -Recurse -Force }
New-Item -ItemType Directory -Force -Path $stage | Out-Null
New-Item -ItemType Directory -Force -Path $out | Out-Null
Copy-Item -LiteralPath (Join-Path $root "extension") -Destination $stage -Recurse
Copy-Item -LiteralPath (Join-Path $root "patches") -Destination $stage -Recurse
Copy-Item -LiteralPath (Join-Path $root "scripts\install.ps1") -Destination $stage
Copy-Item -LiteralPath (Join-Path $root "scripts\uninstall.ps1") -Destination $stage
Copy-Item -LiteralPath (Join-Path $root "LICENSE") -Destination $stage
Copy-Item -LiteralPath (Join-Path $root "THIRD_PARTY_NOTICES.md") -Destination $stage
$archive = Join-Path $out "lithe-jenkinsfile-$Version.zip"
if (Test-Path $archive) { Remove-Item -LiteralPath $archive -Force }
Compress-Archive -Path $stage -DestinationPath $archive
$hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath "$archive.sha256" -Value "$hash  $(Split-Path -Leaf $archive)" -Encoding ascii
Write-Output $archive
