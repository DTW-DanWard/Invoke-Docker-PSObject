
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

# Synopsis: By default run Test
task Default Test

# Synopsis: List tasks in this build file
task . { Invoke-Build ? }

# Synopsis: Initialze build helpers and displays settings
task Init {
  $Line
  Set-Location $ProjectRoot
  'Build System Details:'
  Get-Item env:BH*
  "`n"
}

# Synopsis: Run unit tests in current PowerShell instance
task Test Init, {
  $Line
  "`nTesting with PowerShell $PSVersion"

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

# Synopsis: Run unit tests in PowerShell Core Ubuntu Docker instance
task Test_Ubuntu {
  $Line
  "`nTesting PowerShell in Ubuntu container"

  # this should only be run on local developer machine, not on build server, and should not be a
  # required part of the deployment to PowerShell Gallery
  if ($env:BHBuildSystem -ne 'Unknown') { Write-Error 'Task Test_MultiOS should only be run on local dev machine' }

  # simple hard-coded version for now; use Ubuntu 16.04 on local machine
  $ContainerName = 'TestContainer'
  "`nStop and remove container with name: $ContainerName"
  docker stop $ContainerName
  docker rm $ContainerName
  "`nCreate new container and start (non-interactive):"
  docker run -t -d --name $ContainerName microsoft/powershell:ubuntu-16.04
  "`napt-get update"
  docker exec $ContainerName pwsh -Command "& { apt-get update }"
  '`napt-get install git-core'
  docker exec $ContainerName pwsh -Command "& { apt-get --assume-yes install git-core }"
  "`nCopy $ProjectRoot to $ContainerName"
  docker cp $ProjectRoot ($ContainerName + ':/tmp')
  docker start $ContainerName
  "`nRun /build.ps1 Test"
  # Invoke-Build fails if the /build.ps1 command is not run relative to the project - from the project root
  docker exec $ContainerName pwsh -Command "& { cd /tmp/Invoke-Docker-PSObject; ./build.ps1 }"
  docker stop $ContainerName
}

# Synopsis: Run PSScriptAnalyzer on PowerShell code files
Task Analyze Init, {
  $Line
  "`nRunning PSScriptAnalyzer"

  # run script analyzer on all files EXCEPT build files in project root
  Get-ChildItem -Path $ProjectRoot -Recurse | Where-Object { @('.ps1', '.psm1') -contains $_.Extension -and $_.DirectoryName -ne $ProjectRoot } | ForEach-Object {
    $Results = Invoke-ScriptAnalyzer -Path $_.FullName
    if ($null -ne $Results) {
      Write-Host "Bad results found for: $($_.Name)"
      $Results
      Write-Error "Fix ScriptAnalyzer results above"
    }
  }
}



# Synopsis: Set public functions in PSD, increment version
Task Build Test, Analyze, {
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

# Synopsis: Build and deploy module to PowerShell Gallery
Task Deploy Build, {
  $Line

  Write-Build Red 'Not implemented yet!'

  # $Params = @{
  #     Path = $ProjectRoot
  #     Force = $true
  #     Recurse = $false # We keep psdeploy artifacts, avoid deploying those : )
  # }
  # Invoke-PSDeploy @Verbose @Params
}
