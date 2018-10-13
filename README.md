Note: this is still in development - but close to completion - in case you stumble upon it.

master: [![Build status](https://ci.appveyor.com/api/projects/status/1m6rgmj4h3p8m20q/branch/master?svg=true)](https://ci.appveyor.com/project/DTW-DanWard/invoke-docker-psobject/branch/master)   develop: [![Build status](https://ci.appveyor.com/api/projects/status/1m6rgmj4h3p8m20q/branch/develop?svg=true)](https://ci.appveyor.com/project/DTW-DanWard/invoke-docker-psobject/branch/develop)

# Invoke-DockerPSObject
Invoke-DockerPSObject runs Docker CLI commands in PowerShell but instead of returning an array of strings it returns proper PSObjects that you can use to filter, sort, return a specific member, etc.

Invoke-DockerPSObject returns PSObjects for Docker commands that return tabular data, i.e. `docker images`, `docker ps` and `docker history`. For all other docker commands it runs the docker command and returns the results as-is.

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


(asdf - more examples here including size, use screenshots, sort / filter, use in removing items, etc)


## How it Works

(asdf - description of --format {{ json . }}, date and size conversions, as a result, if --format passed, runs as-is)


## Developer's Note
I've been using this simple utility on my home machine for awhile.  When finally putting it online, though, I wanted to use this as an opportunity to create a module from complete scratch with all the latest and greatest PowerShell development techniques.  If you are new to module development or writing PowerShell with CI/CD and want something to review and learn, this project is a fairly small, self-contained utility that features:
* PowerShell Module Release Pipeline using [Warren F's awesome utilities](http://ramblingcookiemonster.github.io/PSDeploy-Inception/)
* Copious Pester unit testing
* Lots of small stuff like dynamically loading/exporting Private/Public functions and custom object output formatting via ps1xml.  (You won't believe how many times I've been too ~~lazy~~ busy to actually add this to my projects.)
