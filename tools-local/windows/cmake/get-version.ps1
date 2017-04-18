<#
.SYNOPSIS
    Gets the version number of CMake executable at the specified path.
.PARAMETER RepositoryRoot
    This argument is ignored.
.PARAMETER OverrideScriptsFolderPath
    This argument is ignored.
.PARAMETER ToolPath
    Path to CMake executable or the folder containing the executable.
#>

[CmdletBinding()]
param(
    [parameter(Mandatory=$true, Position=0)]
    [string]$RepositoryRoot,
    [parameter(Mandatory=$true, Position=1)]
    [string]$ToolName,
    [parameter(Position=2)]
    [string]$OverrideScriptsFolderPath,
    [parameter(Mandatory=$true, Position=3)]
    [string]$ToolPath,
    [parameter(ValueFromRemainingArguments=$true)]
    [string]$ExtraArgs
)

if ($ToolName -ne "cmake")
{
    Write-Host "Second argument should be cmake."
    return
}

if ([string]::IsNullOrWhiteSpace($ToolPath) -or -not (Test-Path -Path $ToolPath -PathType Any))
{
    Write-Host "Argument specified as tool-path does not exist or is not accessible. Path: $ToolPath"
    return
}

# Extract version number. For example, 3.6.0 in text below.
#cmake version 3.6.0
#
#CMake suite maintained and supported by Kitware (kitware.com/cmake).

# Assumed that one or more digits followed by a decimal point is the start of version number.
$toolVersion = & $ToolPath -version
$regexPattern = "(?<=cmake version )[0-9][.]([0-9]|[.])+"
$versionNumber = [regex]::Match($toolVersion, $regexPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline).Value

if ([string]::IsNullOrWhiteSpace($versionNumber))
{
    return "Unable to determine the version of CMake at $ToolPath."
}

return "$versionNumber"
