<#
.SYNOPSIS
Run Docker commands and get PSObjects not strings
.DESCRIPTION
For Docker commands that return tabular data - images, ps and history -
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
a8b0bd9c9387   hello-world   "/hello"  34 seconds ago           Exited (0) 32 seconds ago           zen_khorana

PS > # using Invoke-DockerPSObject
PS > Invoke-DockerPSObject ps -a
ID             Image         Command   CreatedAt                Status                      Ports   Names
--             -----         -------   ---------                ------                      -----   -----
a8b0bd9c9387   hello-world   "/hello"  10/11/2018 11:01:41 AM   Exited (0) 5 seconds ago            zen_khorana

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
a8b0bd9c9387   hello-world   "/hello"  10/11/2018 11:01:41 AM   Exited (0) 5 seconds ago            zen_khorana
.LINK
https://github.com/DTW-DanWard/Invoke-Docker-PSObject
#>
function Invoke-DockerPSObject {
  # Note: no arguments defined; we use $args

  #region Identify subcommand type to process
  # note: only do this for these docker subcommands: images, ps and history
  # otherwise data is not tabular/possible to convert to PSObjects
  # also, don't do this if user has passed in their own --format parameter
  $ProcessedSubCmds = 'images', 'ps', 'history'
  Write-Verbose "Subcommands processed by this utility: $ProcessedSubCmds"
  $SubCmd = $args[0]
  Write-Verbose "Subcommand passed this time: $SubCmd"
  Write-Verbose "Full list of user parameters passed: $args"
  #endregion

  #region If not a subcommand to convert to PSObjects, just run and return results
  # we don't process every Docker request; for ones we don't we just run docker with user args without
  # modificatino and return as-is
  # these are the Docker requests we skip:
  #  - not a valid sub command (not in: images, ps, history)
  #  - contains special formatting (even if valid sub command)
  #  - is a help request
  if ($ProcessedSubCmds -notcontains $SubCmd -or $args -contains '--format' -or $args -contains '--help' -or $args -contains '-h') {
    Write-Verbose "Subcommand '$SubCmd' output does not get converted to PSObjects"
    Invoke-DockerExe @args
    return
  }
  #endregion

  #region Run Docker, get PSObjects, convert date info to proper datetime field, add SizeKB and add custom type (for Format.ps1xml)
  $args += '--format', '{{ json . }}'
  Write-Verbose "Parameters to pass to docker.exe when invoking: $args"
  $Results = Invoke-DockerExe @args

  # convert Results from json to PSObjects
  $Results = $Results | ConvertFrom-Json

  $Results | ForEach-Object {
    # add unique type name based on Docker command type to PSObject for matching in Invoke-Docker-PSObject.Format.ps1xml file
    $_.PSObject.TypeNames.Insert(0, 'Invoke-DockerPSObject.' + $SubCmd)
    # convert preexisting CreatedAt field to DateTime (or ensure it already is one)
    $_.CreatedAt = Convert-DockerDateToPSDate -DockerDate ($_.CreatedAt)
    # add field SizeKB based on converted value in Size
    Add-Member -InputObject $_ -MemberType NoteProperty -Name SizeKB -Value (Convert-DockerSizeToPSSize -DockerSize $_.Size)
    $_
  }
  #endregion
}
