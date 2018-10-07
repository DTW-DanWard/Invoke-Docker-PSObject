
# dot-source source file for this test file; exit if not found
. $PSScriptRoot\Get-SourceScriptFilePath.ps1
$SourceScript = Get-SourceScriptFilePath
if ($null -eq $SourceScript) { exit }
. $SourceScript



# Valid date: 2018-07-19 20:39:27 -0400 EDT
# Not valid:  2018-07-19 20:39:27
# Not valid:  NOT_VALID
