[CmdletBinding()]
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
if ($env:BHBranchName -ne "master" -or $env:BHCommitMessage -match "!verbose") {
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
  Get-Item env:BH* | Sort-Object Name
  "`n"
}

# Synopsis: Run unit tests in current PowerShell instance
task Test Init, {
  $Line
  "`nTesting with PowerShell $PSVersion"

  $Params = @{
    Path         = "$ProjectRoot\Tests"
    PassThru     = $true
    OutputFormat = "NUnitXml"
    OutputFile   = "$ProjectRoot\$TestFile"
  }
  # DevMachine tagged tests are only run on the native developer machine; not on build server, not in test container
  # these tests typically are integration tests - blackbox testing against actual docker.exe
  if (($env:BHBuildSystem -ne 'Unknown') -or ($null -eq (Get-Command -Name 'docker.exe' -ErrorAction SilentlyContinue))) {
    $Params.ExcludeTag = @('DevMachine')
  }

  # Gather test results. Store them in a variable and file
  $TestResults = Invoke-Pester @Params

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
task Test_Ubuntu Init, {
  $Line
  "`nTesting PowerShell in Ubuntu container"

  # needs error handling
  # this should only be run on local developer machine, not on build server, and should not be a
  # required part of the deployment to PowerShell Gallery
  if ($env:BHBuildSystem -ne 'Unknown') { Write-Error 'Task Test_Ubuntu should only be run on local dev machine' }

  # simple hard-coded version for now; use Ubuntu 16.04 image on local machine
  $ContainerName = $env:BHProjectName + '_test_' + (Get-Random -Minimum 1000 -Maximum 999999)
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
  # Invoke-Build fails if the /build.ps1 command is not run relative to the project - so run from project root
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
      Write-Build Red "PSScriptAnalyzer found issues in: $($_.Name)"
      $Results | ForEach-Object {
        Write-Build Red "$($_.Line) : $($_.Message)"
      }
      Write-Build Cyan "See full results with: Invoke-ScriptAnalyzer -Path $($_.FullName)"
      Write-Error 'Fix above issues'
    }
  }
  Write-Build Cyan "Analyze successful"
}

# Synopsis: Set public functions in PSD, increment version
Task Build Test, Analyze, {
  $Line
  "`nRunning Build"

  # only run build if on AppVeyor build server and on branch master
  if (! ($env:BHBuildSystem -ne 'Unknown' -and $env:BHBranchName -eq 'master')) {
    Write-Build Red 'Build task only runs on build server on master branch'
    return
  }

  # Load the module, read the exported functions/aliases and update the psd1 *ToExport fields
  Set-ModuleFunctions @Verbose
  Set-ModuleAliases @Verbose

  # Bump the module version if we didn't manually bump it
  try {
    # adapted from Get-NextNugetPackageVersion and PSGraph; should be refactored
    # this only uses the publish version of the module when increment; whatever text in psd1 is ignored and overwritten
    $PackageSourceUrl = 'https://www.powershellgallery.com/api/v2/'
    $CurrentPackage = Find-NugetPackage -Name $env:BHProjectName -PackageSourceUrl $PackageSourceUrl -IsLatest -ErrorAction Stop
    $CurrentVersion = '0.0.0'
    if ($null -ne $CurrentPackage) {
      $CurrentVersion = $CurrentPackage.Version
    }
    "Current published version: $CurrentVersion"
    # convert to version type so easier to work with
    $CurrentVersion = [version]$CurrentVersion

    if ($env:BHCommitMessage -match '!major') {
      $NewVersion = New-Object System.Version (($CurrentVersion.Major + 1), 0, 0)
    } elseif ($env:BHCommitMessage -match '!minor') {
      $NewVersion = New-Object System.Version ($CurrentVersion.Major, ($CurrentVersion.Minor + 1), 0)
    } else {
      $NewVersion = New-Object System.Version ($CurrentVersion.Major, $CurrentVersion.Minor, ($CurrentVersion.Build + 1))
    }

    "New version: $NewVersion"
    "Updating module metadata ModuleVersion and FunctionsToExport"
    Update-Metadata -Path $env:BHPSModuleManifest -PropertyName ModuleVersion -Value ($NewVersion.ToString()) -ErrorAction Stop
  } catch {
    "Failed to update version for '$env:BHProjectName': $_.`nContinuing with existing version"
  }
}

# Synopsis: Build and deploy module to PowerShell Gallery
Task Deploy Build, {
  $Line

  # only run build if on AppVeyor build server and on branch master
  if (! ($env:BHBuildSystem -ne 'Unknown' -and $env:BHBranchName -eq 'master')) {
    Write-Build Red 'Deploy task only runs on build server on master branch'
    return
  }

  $Params = @{
    Path    = $ProjectRoot
    Force   = $true
    Recurse = $false # We keep psdeploy artifacts, avoid deploying those : )
  }
  Invoke-PSDeploy @Verbose @Params
}