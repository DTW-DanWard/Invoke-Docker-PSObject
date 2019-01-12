Set-StrictMode -Version Latest

#region Set module/script-level variables
$ScriptLevelVariables = Join-Path -Path $env:BHModulePath -ChildPath 'Set-ScriptLevelVariables.ps1'
. $ScriptLevelVariables
#endregion

#region Dot-source Source file associated with this test file
# if no value returned just exit; specific error is already written in Get-SourceScriptFilePath call
. (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath Get-SourceScriptFilePath.ps1)
$SourceScript = Get-SourceScriptFilePath
if ($null -eq $SourceScript) { exit }
Describe "Re/loading: $SourceScript" { }
. $SourceScript
#endregion


#region Converts Docker size string to double type in KB
Describe 'Convert Docker size string value to type double object in unit KB' {
  #region Validates returns type double
  It 'accepts valid Docker size string in B and returns a double' {
    [double]$Size = 100
    [string]$SizeString = $Size.ToString() + 'B'
    Convert-DockerSizeToPSSize $SizeString | Should BeOfType 'double'
  }

  It 'accepts valid Docker size string in KB and returns a double' {
    [double]$Size = 100
    [string]$SizeString = $Size.ToString() + 'kB'
    Convert-DockerSizeToPSSize $SizeString | Should BeOfType 'double'
  }

  It 'accepts valid Docker size string in MB and returns a double' {
    [double]$Size = 100
    [string]$SizeString = $Size.ToString() + 'MB'
    Convert-DockerSizeToPSSize $SizeString | Should BeOfType 'double'
  }

  It 'accepts valid Docker size string in GB and returns a double' {
    [double]$Size = 100
    [string]$SizeString = $Size.ToString() + 'GB'
    Convert-DockerSizeToPSSize $SizeString | Should BeOfType 'double'
  }
  #endregion

  #region Validates returns converted number
  It 'converts valid Docker size string in B to KB' {
    [double]$Size = 512
    [string]$SizeString = $Size.ToString() + 'B'
    Convert-DockerSizeToPSSize $SizeString | Should Be ($Size / 1KB)
  }

  It 'converts valid Docker size string in KB to KB' {
    [double]$Size = 100
    [string]$SizeString = $Size.ToString() + 'kB'
    Convert-DockerSizeToPSSize $SizeString | Should Be $Size
  }

  It 'converts valid Docker size string in MB to KB' {
    [double]$Size = 100
    [string]$SizeString = $Size.ToString() + 'MB'
    Convert-DockerSizeToPSSize $SizeString | Should Be ($Size * 1KB)
  }

  It 'converts valid Docker size string in GB to KB' {
    [double]$Size = 100
    [string]$SizeString = $Size.ToString() + 'GB'
    Convert-DockerSizeToPSSize $SizeString | Should Be ($Size * 1MB)
  }
  #endregion
}
#endregion


#region Throws exceptions for invalid size values
Describe 'Throw exceptions for invalid size values' {
  It 'throws error if null passed' {
    { Convert-DockerSizeToPSSize $null } | Should throw
  }

  It 'throws error if empty string passed' {
    { Convert-DockerSizeToPSSize '' } | Should throw
  }

  It 'throws error if only spaces passed' {
    { Convert-DockerSizeToPSSize '   ' } | Should throw
  }

  It 'throws error if 1 letter passed' {
    { Convert-DockerSizeToPSSize 'W' } | Should throw
  }

  It 'throws error if completely invalid value passed' {
    { Convert-DockerSizeToPSSize 'ABC123XYZ' } | Should throw
  }

  It 'throws error if no number passed just valid suffix' {
    { Convert-DockerSizeToPSSize 'kb' } | Should throw
  }

  It 'throws error if no number passed just invalid suffix' {
    { Convert-DockerSizeToPSSize 'Qb' } | Should throw
  }

  It 'throws error if valid number passed but no suffix' {
    { Convert-DockerSizeToPSSize '100' } | Should throw
  }

  It 'throws error if number invalid - multiple . - but valid suffix' {
    { Convert-DockerSizeToPSSize '100.100.10MB' } | Should throw
  }

  It 'throws error if number invalid - junk number - but valid suffix' {
    { Convert-DockerSizeToPSSize '55ZZ55MB' } | Should throw
  }
}
#endregion
