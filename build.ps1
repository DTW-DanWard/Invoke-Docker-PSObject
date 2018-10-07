param(
  [string]$Task = 'Default'
)

# adapted from Warren F's (ramblingcookiemonster) excellent PowerShell build/deploy utilties

# Grab nuget bits, install modules, set build variables, start build.
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
Install-Module InvokeBuild, BuildHelpers, Pester, PSDeploy -Force
Import-Module InvokeBuild, BuildHelpers

Set-BuildEnvironment

Invoke-Build -File .\Invoke-Docker-PSObject.build.ps1 -Task $Task -Result Result
if ($Result.Error) {
  exit 1
} else {
  exit 0
}
