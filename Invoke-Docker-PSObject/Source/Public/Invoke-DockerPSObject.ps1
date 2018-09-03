
function Invoke-DockerPSObject {


  #region Run docker command and capture results in $PSObjects
  # note: only do this for these docker sub-commands: images, ps, history, port
  # otherwise data is not tabular/worth/possible to convert to PSObjects
  # also, don't do this if user has passed in their own --format parameter

  $ValidSubCmds = 'images', 'ps', 'history', 'port'
  $Cmd = "docker"
  $SubCmd = $args[0]
  # if not a valid subcommand or user passed along special formatting then just invoke as-is and return
  if ($ValidSubCmds -notcontains $SubCmd -or $args -contains '--format') {
    & $Cmd $args
    return
  }

  $args += '--format', '{{ json . }}'
  $Results = & $Cmd $args
  if ($null -ne $Results -and $Results.ToString().Trim() -ne '') {
    $PSObjects = $Results | ConvertFrom-Json
  } else {
    $null
    return
  }
  #endregion

  #region Add type name (for Format.ps1xml), set datetime field to PowerShell date and return object
  $PSObjects | ForEach-Object {

    # add type name to PSObject for matching in Invoke-Docker.Format.ps1xml file
    $_.PSObject.TypeNames.Insert(0, 'Invoke-Docker-PSObject.' + $SubCmd)

    # CreatedAt date info for 'docker ps' and 'docker images' is in a format that doesn't get auto converted to PowerShell date
    # during the --format json call but, strangely, docker history CreatedAt does
    # so only do this for commands that fail
    if (('ps', 'images') -contains $SubCmd) {
      $_.CreatedAt = Convert-DockerDateToPSDate -DockerDate ($_.CreatedAt)
    }
    $_
  }
  #endregion
}
New-Alias -Name id -Value Invoke-DockerPSObject