<#
.SYNOPSIS
Run docker.exe command with all arguments passed and returns results
.DESCRIPTION
Run docker.exe command with all arguments passed and returns results
.EXAMPLE
Invoke-DockerExe ps -a
<returns container information on machine>
#>
function Invoke-DockerExe {
  # Note: no arguments defined; we use $args
  Write-Verbose "Full list of user parameters passed: $args"
  & 'docker' $args
}