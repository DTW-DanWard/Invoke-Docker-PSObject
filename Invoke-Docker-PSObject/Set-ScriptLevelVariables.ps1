
Set-StrictMode -Version Latest

Write-Verbose "$($MyInvocation.MyCommand) :: Creating script-level variables"

# script-level variables
# web site url
$script:ProjectUrl = 'https://github.com/DTW-DanWard/Invoke-Docker-PSObject'

# define alias/function mappings
$AliasesToExport = @{
  id   = 'Invoke-DockerPSObject'
}
Set-Variable OfficialAliasExports -Value $AliasesToExport -Scope Script
