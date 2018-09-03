
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
    # first remove timezone suffix
    $DockerDate =  $DockerDate.Substring(0, $DockerDate.IndexOf(' -'))
    # convert to proper PowerShell date and return
    [System.DateTime]::ParseExact($DockerDate, "yyyy-MM-dd HH:mm:ss", [CultureInfo]::InvariantCulture)
  }
}