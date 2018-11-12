Set-StrictMode -Version Latest

#region Dot-source Source file associated with this test file
# if no value returned just exit; specific error is already written in Get-SourceScriptFilePath call
. $PSScriptRoot\Get-SourceScriptFilePath.ps1
$SourceScript = Get-SourceScriptFilePath
if ($null -eq $SourceScript) { exit }
Describe "Re/loading: $SourceScript" { }
. $SourceScript
#endregion


#region Docker integration tests
Describe 'Docker integration tests' {

  Get-Module -Name $env:BHProjectName -All | Remove-Module -Force
  Import-Module $env:BHPSModuleManifest -Force -ErrorAction Stop

  InModuleScope $env:BHProjectName {

  It "should have 8 images" {
    Write-Host "Has $((id images).Count) images"
    (id images).Count | Should Be 8
  }
}
}
#endregion
