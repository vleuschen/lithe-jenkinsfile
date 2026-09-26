Describe "manual installer safety" {
  It "contains no broad root deletion" {
    $script = Get-Content (Join-Path $PSScriptRoot "..\scripts\uninstall.ps1") -Raw
    $script | Should Not Match 'Remove-Item\s+[A-Z]:\\\s+-Recurse'
  }
  It "targets the bundled Jenkinsfile directory" {
    (Get-Content (Join-Path $PSScriptRoot "..\scripts\install.ps1") -Raw) | Should Match 'languages\\jenkinsfile'
  }
}
