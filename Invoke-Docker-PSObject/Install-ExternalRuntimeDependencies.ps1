
# This script installs external run-time dependencies.

# Please note: build.ps1 also installs dependencies required by the build process but most end-users will not
# be performing builds.

# No external runtime dependencies for this project
<#
'Dependency1', 'Dependency1' | ForEach-Object {
  $ProgressPreference = 'SilentlyContinue'
  if ($null -eq (Get-Module -Name $_ -ListAvailable)) { Install-Module -Name $_ -Force -AllowClobber }
}
#>
