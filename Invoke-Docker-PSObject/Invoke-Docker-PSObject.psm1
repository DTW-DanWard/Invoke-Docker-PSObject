
$SourceRootPath = Join-Path -Path $PSScriptRoot -ChildPath (Join-Path -Path 'Invoke-Docker-PSObject' -ChildPath 'Source')
# dot source all ps1 scripts under Source; note: no pester test files not stored under Source
Get-ChildItem -Path $SourceRootPath -Filter *.ps1 -Recurse | ForEach-Object {
  . $_.FullName
}

# use Zachary Loeber AST method to get names of public functions instead of storing/assuming function per file
# https://www.the-little-things.net/blog/2015/10/03/powershell-thoughts-on-module-design/
$PublicSourceRootPath = Join-Path -Path $SourceRootPath -ChildPath 'Public'
Get-ChildItem -Path $PublicSourceRootPath -Filter *.ps1 -Recurse | ForEach-Object {
  ([System.Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $_.FullName -Raw), [ref]$null, [ref]$null)).FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false) | ForEach-Object {
    Export-ModuleMember -Function $_.Name
  }
}

# also export alias id
Export-ModuleMember -Alias id