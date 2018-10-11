
Set-StrictMode -Version Latest

# dot-source source file for this test file; exit if not found
. $PSScriptRoot\Get-SourceScriptFilePath.ps1
$SourceScript = Get-SourceScriptFilePath
if ($null -eq $SourceScript) { exit }
Write-Host "Reloading: $SourceScript"
. $SourceScript


Describe "Converts Docker date string to System.DateTime object" {
  It "converts valid Docker date strings with timezone correctly" {
    Convert-DockerDateToPSDate '2018-07-19 20:39:27 -0400 EDT' | Should BeOfType 'datetime'
  }

  It "converts valid Docker date strings with no timezone correctly" {
    Convert-DockerDateToPSDate '2018-07-19 20:39:27' | Should BeOfType 'datetime'
  }
}

Describe "Throws exceptions for invalid date strings" {
  It "throws errors for non-Docker date strings" {
    { Convert-DockerDateToPSDate 'Saturday, October 6, 2018 9:19:27 PM' } | Should throw
  }

  It "throws errors for completely invalid date strings" {
    { Convert-DockerDateToPSDate 'NOT_VALID_DATE_STRING' } | Should throw
  }
}
