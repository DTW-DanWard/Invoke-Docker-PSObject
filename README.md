
master: [![Build status](https://ci.appveyor.com/api/projects/status/1m6rgmj4h3p8m20q/branch/master?svg=true)](https://ci.appveyor.com/project/DTW-DanWard/invoke-docker-psobject/branch/master)   develop: [![Build status](https://ci.appveyor.com/api/projects/status/1m6rgmj4h3p8m20q/branch/develop?svg=true)](https://ci.appveyor.com/project/DTW-DanWard/invoke-docker-psobject/branch/develop)

# Invoke-DockerPSObject
Invoke-DockerPSObject is a simple function that runs Docker CLI commands in PowerShell but instead of returning an array of strings it returns proper PSObjects.  You can use these objects to filter, sort, return a specific member, etc. like any object in PowerShell.

Invoke-DockerPSObject returns PSObjects for Docker commands that return tabular data, i.e. `docker images`, `docker ps` and `docker history`. For all other docker commands Invoke-DockerPSObject will still run the docker command but just returns the standard docker output as-is.

`Invoke-DockerPSObject` is a lot of text to type so the module includes alias: **`id`**

## Strings, strings, strings, strings...
Because docker.exe is a 'legacy' (non-native PowerShell) command in PowerShell, it's output is only a single string of text per row (item) - not an object with properties.  Having _only_ string output is OK if all you want to do is list a few images or containers.  However, once you have a lot of images/containers and you need to do something - sort by size, filter by date then programmatically remove by ID - those strings are a pain.  In the PowerShell world we are too ~~lazy~~ clever to spend our time parsing strings; so using this utility will simplify Docker PowerShell CLI experience.


```PowerShell
PS > # using docker itself
PS > docker ps -a
CONTAINER ID  IMAGE        COMMAND  CREATED                 STATUS                    PORTS   NAMES
a8b0bd9c9387  hello-world  "/hello" 34 seconds ago          Exited (0) 5 seconds ago          zen_khorana

PS > # using Invoke-DockerPSObject
PS > Invoke-DockerPSObject ps -a
ID            Image        Command  CreatedAt               Status                    Ports   Names
--            -----        -------  ---------               ------                    -----   -----
a8b0bd9c9387  hello-world  "/hello" 10/11/2018 11:01:41 AM  Exited (0) 5 seconds ago          zen_khorana

PS > # return just a few properties - use alias id instead
PS > id ps -a | select Image, Names, CreatedAt
Image        Names        CreatedAt
-----        -----        ---------
hello-world  zen_khorana  10/11/2018 11:01:41 AM
```



The CreatedAt field is a DateTime object so let's use it like one.

```PowerShell
PS > (id ps -a)[0].CreatedAt

Saturday, October 11, 2018 11:01:41 AM

PS > (id ps -a)[0].CreatedAt.AddDays(-5)

Saturday, October 6, 2018 11:01:41 AM
```

## How it Works
docker.exe has a format parameter that allows the user to specify a specific output of the results. One barely documented option of this format parameter is that you can specify the output as json.  So this utility works by:
* Adding --format {{ json . }} to the other arguments passed by the user;
* Runs docker command with these arguments, get json results, convert to PSObjects;
* Converts Docker text date to DateTime property for proper comparisons/sorting;
* Converts Docker text file size (with B, KB, MB text extensions) to value in KB for proper comparisons/sorting.

Note: it only does this work for docker commands: images, ps and history.


## Developer's Note
I've been using this simple utility on my home machine for awhile.  When finally putting it online, though, I wanted to use this as an opportunity to create a module from complete scratch with all the latest and greatest PowerShell development techniques.  If you are new to module development or writing PowerShell with CI/CD and want something to review and learn, this project is a fairly small, self-contained utility that features:
* PowerShell module release pipeline using [Warren F's awesome utilities](http://ramblingcookiemonster.github.io/PSDeploy-Inception/) to automatically build on AppVeyor and deploy to PowerShellGallery;
* copious Pester unit testing;
* lots of small stuff like dynamically loading/exporting Private/Public functions and custom object output formatting via ps1xml.  (You won't believe how many times I've been too ~~lazy~~ busy to actually add this to my projects.)
