[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter(Mandatory = $true)] [string] $LitheSourcePath,
  [string] $PluginPath = (Join-Path $PSScriptRoot "..\extension"),
  [switch] $SkipPatch
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$source = (Resolve-Path -LiteralPath $LitheSourcePath).Path
$plugin = (Resolve-Path -LiteralPath $PluginPath).Path
$patch = (Resolve-Path (Join-Path $PSScriptRoot "..\patches\lithe-0.5.4.patch")).Path
$monacoPatch = (Resolve-Path (Join-Path $PSScriptRoot "..\patches\lithe-0.5.4-monaco.patch")).Path
$target = Join-Path $source "windows\tauri\src\extensions\bundled\languages\jenkinsfile"

if (-not (Test-Path (Join-Path $source ".git"))) { throw "LitheSourcePath must be a Git checkout: $source" }
$version = ((& git -C $source describe --tags --exact-match HEAD 2>$null) -join "").Trim()
if ($version -and $version -ne "v0.5.4") { throw "Expected Lithe v0.5.4 checkout, got $version" }

if (-not $SkipPatch) {
  & git -C $source apply --check $patch
  if ($LASTEXITCODE -eq 0) {
    if ($PSCmdlet.ShouldProcess($source, "Apply Lithe Jenkinsfile manifest patch")) { & git -C $source apply $patch }
  } elseif ((Select-String -LiteralPath (Join-Path $source "windows\tauri\src\extensions\bundled\bundled-extension-manifests.ts") -Pattern "languages/jenkinsfile" -Quiet)) {
    Write-Verbose "Manifest patch already applied."
  } else { throw "The Lithe patch does not apply cleanly. Check out the supported v0.5.4 source." }

  & git -C $source apply --check $monacoPatch
  if ($LASTEXITCODE -eq 0) {
    if ($PSCmdlet.ShouldProcess($source, "Apply Lithe Jenkinsfile Monaco tokenizer patch")) { & git -C $source apply $monacoPatch }
  } elseif ((Select-String -LiteralPath (Join-Path $source "frontend\editor\src\language-contributions.ts") -Pattern "jenkinsfileMonarchLanguage" -Quiet)) {
    Write-Verbose "Monaco tokenizer patch already applied."
  } else { throw "The Lithe Monaco tokenizer patch does not apply cleanly. Check out the supported v0.5.4 source." }
}

if ($PSCmdlet.ShouldProcess($target, "Install Jenkinsfile extension assets")) {
  New-Item -ItemType Directory -Force -Path $target | Out-Null
  Get-ChildItem -LiteralPath $plugin -Force | Copy-Item -Destination $target -Recurse -Force
}
Write-Output "Installed Jenkinsfile highlighting sources into $source"
