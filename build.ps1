param(
  [string]$Task = 'Default'
)

# adapted from Warren F's (ramblingcookiemonster) excellent PowerShell build/deploy utilties

# Grab nuget bits, install modules, set build variables, start build.
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

'InvokeBuild', 'BuildHelpers', 'Pester', 'PSDeploy' | ForEach-Object {
  if ($null -eq (Get-Module -Name $_ -ListAvailable)) { Install-Module -Name $_ -Force }
  Import-Module -Name $_
}

# only call Set-BuildEnvironment if BuildHelpers env variables don't exist yet; check for a particular variable
if ($false -eq (Test-Path env:BHBranchName)) { Set-BuildEnvironment }

Invoke-Build -File .\Invoke-Docker-PSObject.build.ps1 -Task $Task -Result Result
if ($Result.Error) {
  exit 1
} else {
  exit 0
}
