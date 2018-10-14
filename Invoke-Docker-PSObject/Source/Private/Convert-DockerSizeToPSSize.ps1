
<#
.SYNOPSIS
Converts Docker size string to size in KB, type Double
.DESCRIPTION
Converts Docker size string to a size in KB, data type number Double.
Docker size strings - for example image size - are text values like 123MB,
1.91kB, etc. - different numerical bases (KB, MB, etc.) not hole values.  
This function converts the string to a numerical value whose base is KB.
.PARAMETER DockerSize
Docker size string
.EXAMPLE
Convert-DockerSizeToPSSize '1.84kB'
1.84
.EXAMPLE
Convert-DockerSizeToPSSize '100MB'
107374182400
#>
function Convert-DockerSizeToPSSize {
  #region Function parameters
  [CmdletBinding()]
  [OutputType([double])]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DockerSize
  )
  #endregion
  process {
    $UnitB = 'B'
    $UnitKB = 'KB'
    $UnitMB = 'MB'
    $UnitGB = 'GB'
    $ValidUnits = $UnitB, $UnitKB, $UnitMB, $UnitGB
    #region Notes about Docker size string and validation/conversion
    # Examples of Docker size: 1.84kB, 123MB
    # I have not personally encounterd a Docker image that is gigabytes in size (I hope they are rare) so
    # I am guessing the suffix would be 'GB'. 
    # With this regex I assume only letters are at end and only numbers and . are at the beginning
    # Yes, this regex could allow some errors (multiple . in beginning, invalid suffix, etc., these will be
    # found in validation/parsing below.
    #endregion
    $Matches = $null
    $Valid = $DockerSize -match '^(?<Number>[0-9\.]+)(?<Unit>[a-z]+$)'
    if ($Valid -eq $false) {
      throw "DockerSize '$DockerSize' (no quotes) should be a number (no comma, decimal optional) followed by a unit ($ValidUnits)"
      return
    }

    # get/validate unit portion first; need to know in order to convert number between KB/MB/GB
    $Unit = $Matches.Unit.ToString().ToUpper()
    if ($Unit -notin $ValidUnits) {
      throw "DockerSize $DockerSize has invalid unit $Unit - expected value in: $ValidUnits"
      return
    }

    # get/validate number portion
    [double]$Number = $null
    $Valid = [double]::TryParse($Matches.Number, [ref]$Number)
    if ($Valid -eq $false) {
      throw "DockerSize $DockerSize is invalid number; should be only numbers and one optional decimal"
      return
    }

    # convert between units (MB -> KB or GB -> KB) and return value
    # KB -> KB conversation * 1 is completely unnecessary but pleasing in a symmetic way
    # no need for else block, units validated above
    if ($Unit -eq $UnitB) { $Number / 1KB }
    elseif ($Unit -eq $UnitKB) { $Number * 1 }
    elseif ($Unit -eq $UnitMB) { $Number * 1KB }
    elseif ($Unit -eq $UnitGB) { $Number * 1MB }
  }
}
