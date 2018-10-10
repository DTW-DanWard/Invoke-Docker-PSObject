
Set-StrictMode -Version Latest

# dot-source source file for this test file; exit if not found
. $PSScriptRoot\Get-SourceScriptFilePath.ps1
$SourceScript = Get-SourceScriptFilePath
if ($null -eq $SourceScript) { exit }
Write-Host "Reloading: $SourceScript"
. $SourceScript

Describe "Confirms all functions have help defined: Synopsis, Description & Parameters" {
  $Functions = ([System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $SourceScript -Raw), [ref]$null, [ref]$null)).FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false)
  It "confirms help section exists for each function" {
    $Functions | Where-Object { $null -eq $_.GetHelpContent() } | Select-Object Name | Should BeNullOrEmpty
  }

  It "confirms Synopsis has content for each function" {
    $Functions | Where-Object { ($null -ne $_.GetHelpContent()) -and (($null -eq $_.GetHelpContent().Synopsis) -or ($_.GetHelpContent().Synopsis -eq '')) } | Select-Object Name | Should BeNullOrEmpty
  }

  It "confirms Description has content for each function" {
    $Functions | Where-Object { ($null -ne $_.GetHelpContent()) -and (($null -eq $_.GetHelpContent().Description) -or ($_.GetHelpContent().Description -eq '')) } | Select-Object Name | Should BeNullOrEmpty
  }

  It "confirms Parameter count in help matches defined parameter count on function" {
    $Functions | ForEach-Object {
      if ($_.GetHelpContent().Parameters.Keys.Count -ne $_.Body.ParamBlock.Parameters.Count) { $_.Name }
    } | Should BeNullOrEmpty
  }

  It "confirms Parameter name(s) in help matches defined parameter name(s) on function" {
    $Functions | ForEach-Object {
      $Function = $_
      # only do if parameters actually defined on function (else .Name will fail with null error)
      if ($Function.Body.ParamBlock.Parameters.Count -gt 0) {
        # use string expansion to get values as strings; 
        $HelpParameters = "$($Function.GetHelpContent().Parameters.Keys | Sort-Object)"
        $DefinedParameters = "$($Function.Body.ParamBlock.Parameters.Name.VariablePath.UserPath | Sort-Object)"
        if ($HelpParameters -ne $DefinedParameters) { $_.Name }
      }
    } | Should BeNullOrEmpty
  }

  It "confirms Parameter(s) have content for each function" {
    $Functions | ForEach-Object {
      $Function = $_
      # only do if parameters actually defined on function (else .Name will fail with null error)
      if ($Function.Body.ParamBlock.Parameters.Count -gt 0) {
        $EmptyContentFound = $false
        $Function.GetHelpContent().Parameters.Keys | ForEach-Object {
          $ParamName = $_
          if ($Function.GetHelpContent().Parameters[$ParamName] -eq '') { $EmptyContentFound = $true }
        }
        if ($EmptyContentFound -eq $true) { $_.Name + ":" + $ParamName }
      }
    } | Should BeNullOrEmpty
  }
}

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
