
Set-StrictMode -Version Latest

#region Dot-source Source file associated with this test file
# if no value returned just exit; specific error is already written in Get-SourceScriptFilePath call
. $PSScriptRoot\Get-SourceScriptFilePath.ps1
$SourceScript = Get-SourceScriptFilePath
if ($null -eq $SourceScript) { exit }
Write-Host "Re/loading: $SourceScript"
. $SourceScript
#endregion


#region Converts Docker date string to System.DateTime object
Describe "Convert Docker date string to System.DateTime object" {
  It "converts valid Docker date strings with timezone correctly" {
    Convert-DockerDateToPSDate '2018-07-19 20:39:27 -0400 EDT' | Should BeOfType 'datetime'
  }

  It "converts valid Docker date strings with no timezone correctly" {
    Convert-DockerDateToPSDate '2018-07-19 20:39:27' | Should BeOfType 'datetime'
  }
}
#endregion


#region Throws exceptions for invalid date strings
Describe "Throw exceptions for invalid date strings" {
  It "throws errors for non-Docker date strings" {
    { Convert-DockerDateToPSDate 'Saturday, October 6, 2018 9:19:27 PM' } | Should throw
  }

  It "throws errors for completely invalid date strings" {
    { Convert-DockerDateToPSDate 'NOT_VALID_DATE_STRING' } | Should throw
  }
}
#endregion
