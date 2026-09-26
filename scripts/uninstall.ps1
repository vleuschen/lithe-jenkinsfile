[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter(Mandatory = $true)] [string] $LitheSourcePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$source = (Resolve-Path -LiteralPath $LitheSourcePath).Path
$patch = (Resolve-Path (Join-Path $PSScriptRoot "..\patches\lithe-0.5.4.patch")).Path
$target = Join-Path $source "windows\tauri\src\extensions\bundled\languages\jenkinsfile"
$manifest = Join-Path $source "windows\tauri\src\extensions\bundled\bundled-extension-manifests.ts"

if ($PSCmdlet.ShouldProcess($target, "Remove Jenkinsfile extension assets") -and (Test-Path $target)) {
  Remove-Item -LiteralPath $target -Recurse -Force
}
if (Test-Path $manifest) {
  & git -C $source apply --reverse --check $patch
  if ($LASTEXITCODE -eq 0 -and $PSCmdlet.ShouldProcess($source, "Reverse Lithe Jenkinsfile manifest patch")) { & git -C $source apply --reverse $patch }
}
Write-Output "Removed Jenkinsfile highlighting sources from $source"
