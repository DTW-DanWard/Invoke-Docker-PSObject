Set-StrictMode -Version Latest

#region Dot-source Source file associated with this test file
# if no value returned just exit; specific error is already written in Get-SourceScriptFilePath call
. $PSScriptRoot\Get-SourceScriptFilePath.ps1
$SourceScript = Get-SourceScriptFilePath
if ($null -eq $SourceScript) { exit }
Describe "Re/loading: $SourceScript" { }
. $SourceScript
#endregion


#region Docker integration tests
Describe -Tag 'DevMachine' 'Docker integration tests' {

  Get-Module -Name $env:BHProjectName -All | Remove-Module -Force
  Import-Module $env:BHPSModuleManifest -Force -ErrorAction Stop

  # need to pull Hello-World images

  InModuleScope $env:BHProjectName {

    # ensure at least one image is available on instance
    # note: don't change test image name without changing other tests below - they make assumptions
    # based on the fact that test image is hello-world (image size, image history size, etc.)
    $TestImageName = 'hello-world'
    docker pull $TestImageName > $null
    # get test image id using docker CLI (will later test this with our tool)
    # this may only work with hello world - simple single repo name
    $TestImageIdFromDockerCLI = docker images $TestImageName --format "{{.ID}}"

    # create unique prefix for container names so can use to find/delete containers
    $TestContainerNamePrefix = $TestImageName + '_' + (Get-Random -Minimum 1000 -Maximum 999999) + '_'
    # create random number of hello-world containers
    $TestContainerManualCount = 0
    $Minimum = 4
    $Maximum = 8
    1..(Get-Random -Minimum $Minimum -Maximum $Maximum) | ForEach-Object {
      $Index = $_
      docker run --name ($TestContainerNamePrefix + $_) $TestImageName
      $TestContainerManualCount += 1
    }

    # in testing output with no results, DO NOT want to forcibly delete images/containers from
    # local dev machine so instead test with filter with junk value to guarantee no results
    It "docker images with junk filter should return single object of type string (Header line only)" {
      (docker images --filter "label=zzzzzzzzzzzzzz") | Should BeOfType [string]
    }
    It "Invoke-DockerPSObject images with junk filter should return $null (no objects)" {
      (Invoke-DockerPSObject images --filter "label=zzzzzzzzzzzzzz") | Should BeNullOrEmpty
    }
    It "docker images with actual results (no filter) should return array with entries of type string" {
      (docker images)[1] | Should BeOfType [string]
    }
    It "Invoke-DockerPSObject images with actual results (no filter) should return array with entries of type PSCustomObject" {
      (Invoke-DockerPSObject images)[1] | Should BeOfType [PSCustomObject]
    }


    It "docker ps -a with junk filter should return single object of type string (Header line only)" {
      (docker ps -a --filter "name=zzzzzzzzzzzzzz") | Should BeOfType [string]
    }
    It "Invoke-DockerPSObject ps -a with junk filter should return $null (no objects)" {
      (Invoke-DockerPSObject ps -a --filter "name=zzzzzzzzzzzzzz") | Should BeNullOrEmpty
    }
    It "docker ps -a with actual results (no filter) should return object array of type string" {
      (docker ps -a)[1] | Should BeOfType [string]
    }
    It "Invoke-DockerPSObject ps -a with actual results (no filter) should return array of type PSCustomObject" {
      (Invoke-DockerPSObject ps -a)[1] | Should BeOfType [PSCustomObject]
    }


    # get test image id using Invoke-DockerPSObject and standard PowerShell filtering
    It "Invoke-DockerPSObject images returns images that can be filtered to find single test image" {
      (Invoke-DockerPSObject images | Where-Object { $_.Repository -eq 'hello-world' }).ID | Should Be $TestImageIdFromDockerCLI
    }
    # test calling history with test image id; PSObjects are returned
    It "Invoke-DockerPSObject history with valid id returns Object array" {
      # need to add , to ensure it doesn't get unwound in pipeline
      , (Invoke-DockerPSObject history $TestImageIdFromDockerCLI) | Should BeOfType [Object[]]
    }
    # hello-world history has two entries
    It "Invoke-DockerPSObject history for test image has correct number of entries" {
      (Invoke-DockerPSObject history $TestImageIdFromDockerCLI).Count | Should Be 2
    }


    # confirm test image found based on very small size
    # assuming hello-world image is less than 2KB - there are few (if any) images this small
    It "Invoke-DockerPSObject images returns container data that can be filtered by size to find test image" {
      ([object[]](Invoke-DockerPSObject images | Where-Object { $_.SizeKB -lt 2KB })).Count | Should BeGreaterThan 0
    }

    # confirm test containers found based on name prefix
    It "Invoke-DockerPSObject ps -a returns container data that can be filtered to find test data" {
      (Invoke-DockerPSObject ps -a | Where-Object { $_.Names -match $TestContainerNamePrefix }).Count | Should Be $TestContainerManualCount
    }

    # confirm alias id works
    It "alias id ps -a returns container data that can be filtered to find test data" {
      (id ps -a | Where-Object { $_.Names -match $TestContainerNamePrefix }).Count | Should Be $TestContainerManualCount
    }

    # cleanup: delete test images create earlier - find using prefix
    (id ps -a | Where-Object { $_.Names -match $TestContainerNamePrefix }).Names | ForEach-Object { id rm $_ }
  }
}
#endregion
