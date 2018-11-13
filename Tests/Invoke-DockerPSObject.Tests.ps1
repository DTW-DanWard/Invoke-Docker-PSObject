Set-StrictMode -Version Latest

#region Dot-source Source file associated with this test file
# if no value returned just exit; specific error is already written in Get-SourceScriptFilePath call
. $PSScriptRoot\Get-SourceScriptFilePath.ps1
$SourceScript = Get-SourceScriptFilePath
if ($null -eq $SourceScript) { exit }
Describe "Re/loading: $SourceScript" { }
. $SourceScript
#endregion


#region Docker unit tests
# tests that will work on any machine - mocking call to docker.exe so not needed
InModuleScope $env:BHProjectName {
  Describe 'Docker unit tests' {
    Context 'Test docker ps -a with empty results' {
      Mock -CommandName 'Invoke-DockerExe' -MockWith { $null }
      It 'Invoke-DockerPSObject returns no objects' {
        Invoke-DockerPSObject ps -a | Should Be $null
      }
    }

    Context 'Test docker ps -a with results' {
      Mock -CommandName 'Invoke-DockerExe' -MockWith {
        @(
          '{"Command":"\"/hello\"","CreatedAt":"2018-11-13 14:50:01 -0500 EST","ID":"d8d321e45a2b","Image":"hello-world","Labels":"","LocalVolumes":"0","Mounts":"","Names":"hello-world_765707_4","Networks":"bridge","Ports":"","RunningFor":"3 hours ago","Size":"0B","Status":"Exited (0) 3 hours ago"}',
          '{"Command":"\"/hello\"","CreatedAt":"2018-11-13 14:49:59 -0500 EST","ID":"d9554895f3e3","Image":"hello-world","Labels":"","LocalVolumes":"0","Mounts":"","Names":"hello-world_765707_3","Networks":"bridge","Ports":"","RunningFor":"3 hours ago","Size":"0B","Status":"Exited (0) 3 hours ago"}',
          '{"Command":"\"/hello\"","CreatedAt":"2018-11-13 14:49:57 -0500 EST","ID":"2829c668ee74","Image":"hello-world","Labels":"","LocalVolumes":"0","Mounts":"","Names":"hello-world_765707_2","Networks":"bridge","Ports":"","RunningFor":"3 hours ago","Size":"0B","Status":"Exited (0) 3 hours ago"}',
          '{"Command":"\"/hello\"","CreatedAt":"2018-11-13 14:49:55 -0500 EST","ID":"26a65c256a07","Image":"hello-world","Labels":"","LocalVolumes":"0","Mounts":"","Names":"hello-world_765707_1","Networks":"bridge","Ports":"","RunningFor":"3 hours ago","Size":"0B","Status":"Exited (0) 3 hours ago"}',
          '{"Command":"\"nginx -g daemon","CreatedAt":"2018-10-13 15:20:01 -0400 EDT","ID":"df6bb9f185f0","Image":"nginx","Labels":"maintainer=NGINX Docker Maintainers \u003cdocker-maint@nginx.com\u003e","LocalVolumes":"0","Mounts":"","Names":"nginx123","Networks":"bridge","Ports":"","RunningFor":"4 weeks ago","Size":"0B","Status":"Exited (0) 4 weeks ago"}',
          '{"Command":"\"nginx -g daemon","CreatedAt":"2018-10-13 15:02:51 -0400 EDT","ID":"81ff3c07b47b","Image":"nginx","Labels":"maintainer=NGINX Docker Maintainers \u003cdocker-maint@nginx.com\u003e","LocalVolumes":"0","Mounts":"","Names":"nginx-1","Networks":"bridge","Ports":"","RunningFor":"4 weeks ago","Size":"0B","Status":"Created"}'
        )
      }
      It 'Invoke-DockerPSObject ps -a returns objects' {
        (Invoke-DockerPSObject ps -a).Count | Should Be 6
      }
      It 'Invoke-DockerPSObject ps -a returns objects than can be filtered by Image name' {
        (Invoke-DockerPSObject ps -a | Where-Object { $_.Image -eq 'nginx' }).Count | Should Be 2
      }
    }

    Context 'Test docker images with results' {
      Mock -CommandName 'Invoke-DockerExe' -MockWith {
        @(
          '{"Containers":"N/A","CreatedAt":"2018-10-02 15:20:03 -0400 EDT","CreatedSince":"6 weeks ago","Digest":"\u003cnone\u003e","ID":"be1f31be9a87","Repository":"nginx","SharedSize":"N/A","Size":"109MB","Tag":"latest","UniqueSize":"N/A","VirtualSize":"109.1MB"}',
          '{"Containers":"N/A","CreatedAt":"2018-09-07 15:25:39 -0400 EDT","CreatedSince":"2 months ago","Digest":"\u003cnone\u003e","ID":"4ab4c602aa5e","Repository":"hello-world","SharedSize":"N/A","Size":"1.84kB","Tag":"latest","UniqueSize":"N/A","VirtualSize":"1.84kB"}'
        )
      }
      It 'Invoke-DockerPSObject images returns objects' {
        (Invoke-DockerPSObject ps -a).Count | Should Be 2
      }
    }

  }
}
#endregion


#region Docker integration tests
Describe -Tag 'DevMachine' 'Docker integration tests' {

  Get-Module -Name $env:BHProjectName -All | Remove-Module -Force
  Import-Module $env:BHPSModuleManifest -Force -ErrorAction Stop

  InModuleScope $env:BHProjectName {

    # ensure at least one image is available on instance
    # note: don't change test image name without changing other tests below - they make assumptions
    # based on the fact that test image is hello-world (image size, image history size, etc.)
    $TestImageName = 'hello-world'
    docker pull $TestImageName > $null
    # get test image id using docker CLI (will later test this with our tool)
    # this may only work with hello world - simple single repo name
    $TestImageIdFromDockerCLI = docker images $TestImageName --format '{{.ID}}'

    # create unique prefix for container names so can use to find/delete containers
    $TestContainerNamePrefix = $TestImageName + '_' + (Get-Random -Minimum 1000 -Maximum 999999) + '_'
    # create random number of hello-world containers
    $TestContainerManualCount = 0
    $Minimum = 2
    $Maximum = 4
    1..(Get-Random -Minimum $Minimum -Maximum $Maximum) | ForEach-Object {
      docker run --name ($TestContainerNamePrefix + $_) $TestImageName
      $TestContainerManualCount += 1
    }

    # in testing output with no results, DO NOT want to forcibly delete images/containers from
    # local dev machine so instead test with filter with junk value to guarantee no results
    It 'docker images with junk filter should return single object of type string (Header line only)' {
      (docker images --filter 'label=zzzzzzzzzzzzzz') | Should BeOfType [string]
    }
    It 'Invoke-DockerPSObject images with junk filter should return $null (no objects)' {
      (Invoke-DockerPSObject images --filter 'label=zzzzzzzzzzzzzz') | Should BeNullOrEmpty
    }
    It 'docker images with actual results (no filter) should return array with entries of type string' {
      (docker images)[1] | Should BeOfType [string]
    }
    It 'Invoke-DockerPSObject images with actual results (no filter) should return array with entries of type PSCustomObject' {
      (Invoke-DockerPSObject images)[1] | Should BeOfType [PSCustomObject]
    }


    It 'docker ps -a with junk filter should return single object of type string (Header line only)' {
      (docker ps -a --filter 'name=zzzzzzzzzzzzzz') | Should BeOfType [string]
    }
    It 'Invoke-DockerPSObject ps -a with junk filter should return $null (no objects)' {
      (Invoke-DockerPSObject ps -a --filter 'name=zzzzzzzzzzzzzz') | Should BeNullOrEmpty
    }
    It 'docker ps -a with actual results (no filter) should return object array of type string' {
      (docker ps -a)[1] | Should BeOfType [string]
    }
    It 'Invoke-DockerPSObject ps -a with actual results (no filter) should return array of type PSCustomObject' {
      (Invoke-DockerPSObject ps -a)[1] | Should BeOfType [PSCustomObject]
    }


    # get test image id using Invoke-DockerPSObject and standard PowerShell filtering
    It 'Invoke-DockerPSObject images returns images that can be filtered to find single test image' {
      (Invoke-DockerPSObject images | Where-Object { $_.Repository -eq 'hello-world' }).ID | Should Be $TestImageIdFromDockerCLI
    }
    # test calling history with test image id; PSObjects are returned
    It 'Invoke-DockerPSObject history with valid id returns Object array' {
      # need to add , to ensure it doesn't get unwound in pipeline
      , (Invoke-DockerPSObject history $TestImageIdFromDockerCLI) | Should BeOfType [Object[]]
    }
    # hello-world history has two entries
    It 'Invoke-DockerPSObject history for test image has correct number of entries' {
      (Invoke-DockerPSObject history $TestImageIdFromDockerCLI).Count | Should Be 2
    }


    # confirm test image found based on very small size
    # assuming hello-world image is less than 2KB - there are few (if any) images this small
    It 'Invoke-DockerPSObject images returns container data that can be filtered by size to find test image' {
      ([object[]](Invoke-DockerPSObject images | Where-Object { $_.SizeKB -lt 2KB })).Count | Should BeGreaterThan 0
    }

    # confirm test containers found based on name prefix
    It 'Invoke-DockerPSObject ps -a returns container data that can be filtered to find test data' {
      (Invoke-DockerPSObject ps -a | Where-Object { $_.Names -match $TestContainerNamePrefix }).Count | Should Be $TestContainerManualCount
    }

    # cleanup: delete test images create earlier - find using prefix
    (Invoke-DockerPSObject ps -a | Where-Object { $_.Names -match $TestContainerNamePrefix }).Names | ForEach-Object { Invoke-DockerPSObject rm $_ }
  }
}
#endregion
