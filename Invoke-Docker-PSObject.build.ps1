
[CmdletBinding()]
# Write-Host is used (shudder!) in the Pester test files
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingWriteHost', '')]
[System.Diagnostics.CodeAnalysis.SuppressMessage('PSAvoidUsingEmptyCatchBlock', '')]
param()

# all the build/deploy code you see if adapted from from Warren F's (ramblingcookiemonster) excellent PowerShell build/deploy utilties
# with a few details borrowed from JiraPS build/deploy Invoke-Build details

$WarningPreference = "Continue"
if ($PSBoundParameters.ContainsKey('Verbose')) {
  $VerbosePreference = "Continue"
}
if ($PSBoundParameters.ContainsKey('Debug')) {
  $DebugPreference = "Continue"
}

Set-StrictMode -Version Latest

$ProjectRoot = $env:BHProjectPath
if (-not $ProjectRoot) {
  $ProjectRoot = $PSScriptRoot
}

$Timestamp = "{0:yyyyMMdd-HHmmss}" -f (Get-Date)
$PSVersion = $PSVersionTable.PSVersion.Major
$TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"
$Line = '-' * 70

$Verbose = @{}
if ($env:BHCommitMessage -match "!verbose") {
  $Verbose = @{Verbose = $True}
}


task Default Test
task . Test

task Init {
  $Line
  Set-Location $ProjectRoot
  "Build System Details:"
  Get-Item env:BH*
  "`n"
}

task Test Init, {
  $Line
  "`nSTATUS: Testing with PowerShell $PSVersion"

  # Gather test results. Store them in a variable and file
  $TestResults = Invoke-Pester -Path $ProjectRoot\Tests -PassThru -OutputFormat NUnitXml -OutputFile "$ProjectRoot\$TestFile"

  # In Appveyor?  Upload our tests! #Abstract this into a function?
  If ($env:BHBuildSystem -eq 'AppVeyor') {
    (New-Object 'System.Net.WebClient').UploadFile(
      "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
      "$ProjectRoot\$TestFile" )
  }

  Remove-Item "$ProjectRoot\$TestFile" -Force -ErrorAction SilentlyContinue

  # if failed tests then write an error to ensure does not continue to deploy steps
  if ($TestResults.FailedCount -gt 0) {
    Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
  }
  "`n"
}

Task Build Test, {
  $Line

  # Load the module, read the exported functions, update the psd1 FunctionsToExport
  Set-ModuleFunctions @Verbose

  # Bump the module version if we didn't manually bump it
  try {
    $NextGalleryVersion = Get-NextPSGalleryVersion -Name $env:BHProjectName -ErrorAction Stop
    $SourceVersion = Get-MetaData -Path $env:BHPSModuleManifest -PropertyName ModuleVersion -ErrorAction Stop
    if ($NextGalleryVersion -ge $SourceVersion) {
      Update-Metadata -Path $env:BHPSModuleManifest -PropertyName ModuleVersion -Value $NextGalleryVersion -ErrorAction stop
    }
  } catch {
    "Failed to update version for '$env:BHProjectName': $_.`nContinuing with existing version"
  }
}

Task Deploy Build, {
  $Line

  Write-Build Red "Not implemented yet!"

  # $Params = @{
  #     Path = $ProjectRoot
  #     Force = $true
  #     Recurse = $false # We keep psdeploy artifacts, avoid deploying those : )
  # }
  # Invoke-PSDeploy @Verbose @Params
}
