param(
  [string]$Task = 'Default'
)

# adapted from Warren F's (ramblingcookiemonster) excellent PowerShell build/deploy utilties

# Grab nuget bits, install modules, set build variables, start build.
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
# asdf re-add to install modules: PSDeploy
Install-Module InvokeBuild, BuildHelpers, Pester -Force
Import-Module InvokeBuild, BuildHelpers

Set-BuildEnvironment

Invoke-Build -File .\Invoke-Docker-PSObject.build.ps1 -Task $Task

# asdf get Invoke-Build result value - 0 or 1
# exit ( [int]( -not $psake.build_success ) )
