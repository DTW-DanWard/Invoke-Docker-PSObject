#region Function: Get-SourceScriptFilePath

<#
.SYNOPSIS
For <source>.Tests.ps1 script gets full path to corresponding source file <source>.ps1
.DESCRIPTION
Get full path for a source file for a given .Tests.ps1 file.  Assumes:
 - Script in <source>.Tests.ps1 is directly calling this function.
 - This function located in file in root of Tests folder which is in project root.
 - Source code is found under Source folder which is located under <module name> folder
   and this <module name> folder contains the .psd1 file.
 - There is only 1 .psd1 file in the module.
 - There is only 1 source file matching the .Tests.ps1 name
#>
function Get-SourceScriptFilePath {
  # get current test script name (the script calling this function)
  $TestScriptName = Split-Path -Path $MyInvocation.PSCommandPath -Leaf
  # source script is test script name minus .Tests
  $SourceScriptName = $TestScriptName -replace '\.Tests',''

  # get module file, go up one folder and look for .psd1 file; make sure exactly one found
  [object[]]$ModuleFile = Get-ChildItem -Path (Split-Path -Path $PSScriptRoot -Parent) -Include *.psd1 -Recurse
  if ($ModuleFile.Count -eq 0) {
    Write-Error -Message "No .psd1 file found in this module"
    return
  } elseif ($ModuleFile.Count -gt 1) {
    Write-Error -Message "Multiple .psd1 files found in this module: $($ModuleFile.Name)"
    return
  }

  # Source folder is located in folder that also contains module file
  $SourceFolderPath = Join-Path -Path (Split-Path -Path ($ModuleFile[0].FullName) -Parent) -ChildPath 'Source'
  # confirm Source path is good
  if ($false -eq (Test-Path -Path $SourceFolderPath)) {
    Write-Error "Source path not found: $SourceFolderPath"
    return
  }
  
  # now find $SourceScriptName under Source; make sure exactly one found
  [object[]]$SourceFile = Get-ChildItem -Path $SourceFolderPath -Include $SourceScriptName -Recurse
  if ($SourceFile.Count -eq 0) {
    Write-Error -Message "No corresponding source file $SourceScriptName found found for $TestScriptName"
    return
  } elseif ($SourceFile.Count -gt 1) {
    Write-Error -Message "Multiple source files named $SourceScriptName found found for $TestScriptName"
    return
  }
  # return the full path
  $SourceFile[0].FullName
}
#endregion