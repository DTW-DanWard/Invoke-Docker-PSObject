
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
Describe 'convert Docker date string to System.DateTime object' {
  It 'converts valid Docker date strings with timezone' {
    Convert-DockerDateToPSDate '2018-07-19 20:39:27 -0400 EDT' | Should BeOfType 'datetime'
  }

  It 'converts valid Docker date strings with no timezone' {
    Convert-DockerDateToPSDate '2018-07-19 20:39:27' | Should BeOfType 'datetime'
  }

  It 'keeps valid DateTime object as-is' {
    $SampleDate = Get-Date '01/01/2018 06:00:00'
    Convert-DockerDateToPSDate $SampleDate | Should BeExactly $SampleDate
  }

}
#endregion


#region Throws exceptions for invalid date strings
Describe 'throw exceptions for invalid date strings' {
  It 'throws errors for non-Docker date strings' {
    { Convert-DockerDateToPSDate 'Saturday, October 6, 2018 9:19:27 PM' } | Should throw
  }

  It 'throws errors for completely invalid date strings' {
    { Convert-DockerDateToPSDate 'NOT_VALID_DATE_STRING' } | Should throw
  }
}
#endregion
