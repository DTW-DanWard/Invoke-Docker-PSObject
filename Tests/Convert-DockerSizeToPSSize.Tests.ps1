
Set-StrictMode -Version Latest

#region Dot-source Source file associated with this test file
# if no value returned just exit; specific error is already written in Get-SourceScriptFilePath call
. $PSScriptRoot\Get-SourceScriptFilePath.ps1
$SourceScript = Get-SourceScriptFilePath
if ($null -eq $SourceScript) { exit }
Write-Host "Re/loading: $SourceScript"
. $SourceScript
#endregion


#region Converts Docker size string to double type in KB
Describe "Convert Docker size string to double object in KB" {
  #region Validates returns type double correct
  It "accepts valid Docker size string in KB and returns a double" {
    [double]$Size = 123
    [string]$SizeString = $Size.ToString() + 'kB'
    Convert-DockerSizeToPSSize $SizeString | Should BeOfType 'double'
  }

  It "accepts valid Docker size string in MB and returns a double" {
    [double]$Size = 100
    [string]$SizeString = $Size.ToString() + 'MB'
    Convert-DockerSizeToPSSize $SizeString | Should BeOfType 'double'
  }

  It "accepts valid Docker size string in GB and returns a double" {
    [double]$Size = 100
    [string]$SizeString = $Size.ToString() + 'GB'
    Convert-DockerSizeToPSSize $SizeString | Should BeOfType 'double'
  }
  #endregion

  #region Validates returns converted number correctly
  It "converts valid Docker size string in KB to KB correctly" {
    [double]$Size = 100
    [string]$SizeString = $Size.ToString() + 'kB'
    Convert-DockerSizeToPSSize $SizeString | Should Be $Size
  }

  It "converts valid Docker size string in MB to KB correctly" {
    [double]$Size = 100
    [string]$SizeString = $Size.ToString() + 'MB'
    Convert-DockerSizeToPSSize $SizeString | Should Be ($Size * 1MB)
  }

  It "converts valid Docker size string in GB to KB correctly" {
    [double]$Size = 100
    [string]$SizeString = $Size.ToString() + 'GB'
    Convert-DockerSizeToPSSize $SizeString | Should Be ($Size * 1GB)
  }

  # asdf need to test GB here

  #endregion

}
#endregion



# need tests for nothing passed

# need tests for incorrect type passed

# need tests for no number passed

# need tests for incorrect number passed (also multple . in number)

# need tests for no suffix, invalid suffix


<#
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
#>