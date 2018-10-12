Note: this is still in development - but close to completion - in case you stumble upon it.

master: [![Build status](https://ci.appveyor.com/api/projects/status/1m6rgmj4h3p8m20q/branch/master?svg=true)](https://ci.appveyor.com/project/DTW-DanWard/invoke-docker-psobject/branch/master)   develop: [![Build status](https://ci.appveyor.com/api/projects/status/1m6rgmj4h3p8m20q/branch/develop?svg=true)](https://ci.appveyor.com/project/DTW-DanWard/invoke-docker-psobject/branch/develop)

# Invoke-Docker-PSObject
Invoke-Docker-PSObject runs Docker CLI commands in PowerShell but instead of returning an array of strings it returns proper PSObjects that you can use to filter, sort, return a specific member, etc.

## Strings, strings, strings, strings...
Because Docker.exe is a 'legacy' (not native PowerShell) command in PowerShell, it only returns strings for it's output - a single string per line of text - not objects with properties.  Having _only_ string output is OK if all you want to do is create and list a few images or containers.  However, once you have a lot of images/containers and you need to do something - sort by size, filter by date then programmatically remove by ID - those strings are a pain.  In the PowerShell world we are too ~~lazy~~ clever to spend our time parsing strings - that's why we use PowerShell in the first place - so I wrote this utility to wrap docker CLI calls and return PSObjects.


```PowerShell
PS > # using docker itself
PS > docker ps -a
CONTAINER ID  IMAGE        COMMAND  CREATED           STATUS                     PORTS   NAMES
a8b0bd9c9387  hello-world  "/hello" 34 seconds ago    Exited (0) 32 seconds ago          zen_khorana

PS > # using Invoke-DockerPSObject
PS > Invoke-DockerPSObject ps -a
ID            Image        Command  CreatedAt               Status                    Ports  Names
--            -----        -------  ---------               ------                    -----  -----
a8b0bd9c9387  hello-world  "/hello" 10/11/2018 11:01:41 AM  Exited (0) 5 seconds ago         zen_khorana

PS > # return just a few properties
PS > Invoke-DockerPSObject ps -a | select Image, Names, CreatedAt
Image        Names        CreatedAt
-----        -----        ---------
hello-world  zen_khorana  10/11/2018 11:01:41 AM
```

The CreatedAt field is a DateTime object so let's use it like one.
By the way, `Invoke-DockerPSObject` is too much text to type, so this module comes with alias `id` for it.

```PowerShell
PS > (id ps -a)[0].CreatedAt.AddDays(-5)

Saturday, October 6, 2018 11:01:41 AM
```


(asdf - more examples here, use screenshots, sort / filter, use in removing items)



## Developer's Note
I've been using this simple utility on my home machine for awhile.  When putting it online, though, I wanted to it this as an opportunity to create a module from complete scratch with all the latest and greatest PowerShell development techniques.  If you are new to module development or writing PowerShell with CI/CD and want something to review and learn, this project is a fairly small, self contained utility that features:
* PowerShell Module Release Pipeline using [Warren F's awesome utilities](http://ramblingcookiemonster.github.io/PSDeploy-Inception/)
* Copious Pester unit testing
* Lots of small stuff - like adding formatting to custom objects via ps1xml.  (You won't believe how many times I've been too ~~lazy~~ busy to actually add this to my projects.)
