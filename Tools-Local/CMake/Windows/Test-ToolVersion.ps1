<#
.SYNOPSIS
    Compares the version of the tool executable at the given path with the declared version. 
    Returns true if versions match. Otherwise, false
.PARAMETER toolPath
    Path to the tool executable for which version check is required.
.PARAMETER toolName
    Name of the tool.
.PARAMETER RepoRoot
    Repository root path.
.EXAMPLE
    .\Test-toolVersion.ps1 
    -toolPath "C:\Users\dotnet\Source\Repos\corefx\Tools-Local\Downloads\CMake\cmake-3.7.2-win64-x64\bin\cmake.exe" -RepoRoot "C:\Users\dotnet\Source\Repos\corefx"
    Returns true since declared version is 3.7.2, which is same as the version of the executable at the given path.
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$toolPath,
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=1)]
    [string]$toolName,
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=2)]
    [string]$RepoRoot
)

if (-not (Test-Path -Path $toolPath -PathType Leaf))
{
    Write-Error "Unable to access the executable at the given path. Path: $toolPath"
    return $false
}

if (-not (Test-Path -Path $RepoRoot -PathType Container))
{
    Write-Error "Unable to access repository root. RepoRoot: $RepoRoot"
    return $false
}

function IsDeclaredVersion
{
    $declaredCMakeVersion = & $PSScriptRoot\Get-DeclaredtoolVersion.ps1 -toolName $toolName -RepoRoot $RepoRoot

    if ([string]::IsNullOrWhiteSpace($declaredCMakeVersion))
    {
        Write-Error "Unable to read the declared version of the tool from .toolversions file."
        return $false
    }

    $versionText = & $toolPath "-version"

    if (-not [string]::IsNullOrWhiteSpace($versionText) -and $versionText -imatch "cmake version $declaredCMakeVersion")
    {
        return $true
    }
}

try
{
    switch ($toolName)
    {
        "CMake"
        {
            return IsDeclaredVersion
        }
        default
        {
            Write-Error "Unable to test the version of tool named $toolName."
        }
    }
}
catch
{
    Write-Error $_.Exception.Message
}

return $false
