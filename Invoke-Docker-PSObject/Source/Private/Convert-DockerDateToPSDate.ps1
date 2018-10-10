
<#
.SYNOPSIS
Converts Docker date string to DateTime object
.DESCRIPTION
Converts Docker date string to DateTime object, converting a string in the 
format of yyyy-MM-dd HH:mm:ss to a DateTime object.  Removes timezone if found.
.PARAMETER DockerDate
Docker date string
#>
function Convert-DockerDateToPSDate {
  #region Function parameters
  [CmdletBinding()]
  [OutputType([datetime])]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DockerDate
  )
  #endregion
  process {
    # Example of Docker date: 2018-08-12 18:13:50 -0400 EDT
    # first remove timezone suffix if exists
    if (($DockerDate.IndexOf(' -')) -gt 0) {
      $DockerDate =  $DockerDate.Substring(0, $DockerDate.IndexOf(' -'))
    }
    # convert to proper PowerShell date and return
    [System.DateTime]::ParseExact($DockerDate, "yyyy-MM-dd HH:mm:ss", [CultureInfo]::InvariantCulture)
  }
}
