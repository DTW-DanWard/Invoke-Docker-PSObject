
[![Build status](https://ci.appveyor.com/api/projects/status/1m6rgmj4h3p8m20q/branch/master?svg=true)](https://ci.appveyor.com/project/DTW-DanWard/invoke-docker-psobject/branch/master)  ![Test Coverage](https://img.shields.io/badge/coverage-98%25-brightgreen.svg?maxAge=60)

# Invoke-DockerPSObject
Invoke-DockerPSObject is a function that runs Docker CLI commands in PowerShell but instead of returning an array of strings it returns proper PSObjects.  You can use these objects to filter, sort, return a specific member, etc. like any object in PowerShell.

Invoke-DockerPSObject returns PSObjects for Docker commands that return tabular data, specifically `docker images`, `docker ps` and `docker history`. For all other docker commands Invoke-DockerPSObject will still run the docker command but just returns the docker output as-is.

`Invoke-DockerPSObject` is long; the module includes alias: **`id`**


## Setup and Usage
Download the Invoke-Docker-PSObject utility. Clone it, zip it or get it from the PowerShell Gallery:
```PowerShell
Install-Module -Name Invoke-Docker-PSObject
```
Instead of typing `docker` use the function alias `id` or type the whole function name: `Invoke-DockerPSObject`
```PowerShell
id ps -a
```
But now you can *DO* stuff with the Docker results in the pipeline!
```PowerShell
# Get all the containers created from the nginx image
id ps -a | ? Image -eq 'nginx'

# Get the total size of all the images
(id images | Measure-Object -Sum -Property SizeKB).Sum

# Delete all images whose name begins with `hello-world_`
(id ps -a | ? Names -match '^hello-world_').Names | % { id rm $_ }

# Get the history for the 3rd oldest image:
id history (id images | sort CreatedAt)[2].ID
```


## Strings, strings, strings, strings...
Because docker.exe is a 'legacy' (non-native PowerShell) command in PowerShell, it's output is only a single string of text per row (item) - not an object with properties.  Having _only_ string output is OK if all you want to do is list a few images or containers.  However, once you have a lot of images/containers and you need to do something - sort by size, filter by date then programmatically remove by ID - those strings are a pain.  In the PowerShell world we are too ~~lazy~~ clever to spend our time parsing strings; so using this utility will simplify Docker PowerShell CLI experience.



## How it Works
docker.exe has a format parameter that allows the user to specify a particular output of the results (which columns, order, format, whitespace, etc.). One barely documented option of this format parameter is that you can specify the output as `json`.  So this utility works by:
* Adding `--format {{ json . }}` to the other arguments passed by the user;
* Runs docker command with all these arguments, get json results and converts to PSObjects;
* On PSObject objects: converts Docker text date to DateTime property for proper comparisons/sorting;
* On PSObject objects: converts Docker text file size (with B, KB, MB text extensions) to value in KB for proper comparisons/sorting.

Note: it only does this for docker commands: images, ps and history.


### Release Testing
*For each release* the Invoke-Docker-PSObject is tested on:
* Windows PowerShell (v5+) (native);
* PowerShell Core - Windows (native);

[Change log](ChangeLog.md)

## Developer's Note
I've been using this simple utility on my home machine for awhile.  When finally putting it online, though, I wanted to use this as an opportunity to create a module from complete scratch with all the latest and greatest PowerShell development techniques.  If you are new to module development or writing PowerShell with CI/CD and want something to review and learn, this project is a fairly small, self-contained utility that features:
* PowerShell module release pipeline using [Warren F's awesome utilities](http://ramblingcookiemonster.github.io/PSDeploy-Inception/) to automatically build on AppVeyor and deploy to PowerShellGallery;
* copious Pester unit testing;
* lots of small stuff like dynamically loading/exporting Private/Public functions and custom object output formatting via ps1xml.  (You won't believe how many times I've been too ~~lazy~~ busy to actually add this to my projects.)
