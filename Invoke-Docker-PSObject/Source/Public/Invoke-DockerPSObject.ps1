<#
.SYNOPSIS
Runs Docker command, returns PSObjects instead of strings
.DESCRIPTION
For Docker commands that return tabular data - images, ps, history and port - 
Invoke-DockerPSObject runs the Docker command, converts the results to PSObjects
and returns them.  It also converts the Docker date time info from a string to
a DateTime object and size info from string to a number in KB so you can sort &
filter by these properties.
For Docker commands that do not return tabular data, it runs the Docker command
and returns the results as-is.
Note: Invoke-DockerPSObject uses the docker --format parameter in order to get 
the data and do the conversion.  If you run a Docker command and pass in the 
--format parameter Invoke-DockerPSObject will not convert, returning results as-is.

'Invoke-DockerPSObject' is a lot to type so an alias is created for it: id
.EXAMPLE
# legacy docker output first
PS > docker ps -a
CONTAINER ID   IMAGE         COMMAND   CREATED                  STATUS                      PORTS   NAMES
a8b0bd9c9387   hello-world   "/hello"  34 seconds ago           Exited (0) 32 seconds ago           boring_mestorf

PS > # using Invoke-DockerPSObject
PS > Invoke-DockerPSObject ps -a
ID             Image         Command   CreatedAt                Status                      Ports   Names
--             -----         -------   ---------                ------                      -----   -----
a8b0bd9c9387   hello-world   "/hello"  10/11/2018 11:01:41 AM   Exited (0) 5 seconds ago            boring_mestorf

# notice the CreatedAt field output is a proper DateTime?

# we now use the results as proper objects
PS > $D = Invoke-DockerPSObject ps -a
PS > $D[0].CreatedAt
Thursday, October 11, 2018 11:01:41 AM
PS > $D[0].CreatedAt.GetType().FullName
System.DateTime

.EXAMPLE
# using short alias
PS > id ps -a
ID             Image         Command   CreatedAt                Status                      Ports   Names
--             -----         -------   ---------                ------                      -----   -----
a8b0bd9c9387   hello-world   "/hello"  10/11/2018 11:01:41 AM   Exited (0) 5 seconds ago            boring_mestorf
#>
function Invoke-DockerPSObject {


  #region Run docker command and capture results in $PSObjects
  # note: only do this for these docker sub-commands: images, ps, history, port
  # otherwise data is not tabular/worth/possible to convert to PSObjects
  # also, don't do this if user has passed in their own --format parameter
  $ValidSubCmds = 'images', 'ps', 'history', 'port'
  $Cmd = "docker"
  $SubCmd = $args[0]
  # we don't process every Docker request; for ones we don't we invoke docker args without modificatino and return as-is
  # these are the Docker requests we skip:
  #  - not a valid sub command
  #  - contains special formatting (even if valid sub command)
  #  - is a help request
  if ($ValidSubCmds -notcontains $SubCmd -or $args -contains '--format' -or $args -contains '--help') {
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