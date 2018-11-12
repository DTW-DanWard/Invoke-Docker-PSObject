
<#
.SYNOPSIS
Converts Docker date to DateTime object
.DESCRIPTION
Converts Docker date to DateTime object, typically converting a string in the
format of yyyy-MM-dd HH:mm:ss -0400EDT to a DateTime object.  Removes timezone if found.
Note: docker images and ps commands return date string that is in this format but docker
history returns a value that does auto-convert to DateTime.
.PARAMETER DockerDate
Docker date object or string
.EXAMPLE
Convert-DockerDateToPSDate '2018-08-12 18:13:50 -0400 EDT'
Sunday, August 12, 2018 6:13:50 PM  (DateTime object)
.EXAMPLE
Convert-DockerDateToPSDate (Get-Date '01/01/2018 06:00:00')   # already DateTime; returns as-as
Monday, January 1, 2018 6:00:00 AM  (DateTime object)

#>
function Convert-DockerDateToPSDate {
  #region Function parameters
  [CmdletBinding()]
  [OutputType([datetime])]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $DockerDate
  )
  #endregion
  process {
    if ($DockerDate -is [DateTime]) {
      # return as-is
      Write-Verbose 'DockerDate is already [DateTime]'
      $DockerDate
    } else {
      # ensure it is a string
      $DockerDate = $DockerDate.ToString()
      Write-Verbose "DockerDate string passed to function: $DockerDate"
      $DockerDateRegex = '^(?<Date>\d\d\d\d-\d\d-\d\d)[^\d](?<Time>\d\d:\d\d:\d\d).*'
      Write-Verbose "RegEx used to parse this value: : $DockerDateRegex"

      $Matches = $null
      $Valid = $DockerDate -match $DockerDateRegex
      if ($Valid -eq $false) {
        Write-Verbose "Not a valid date string: $DockerDate"
        throw "DockerDate '$DockerDate' (no quotes) could not be parsed by regex: $DockerDateRegex"
        return
      }
      Write-Verbose "Calling Get-Date with combined date ($($Matches.Date)) and time ($($Matches.Time))"
      # create date time with values and return
      Get-Date ($Matches.Date + ' ' + $Matches.Time)
    }
  }
}
