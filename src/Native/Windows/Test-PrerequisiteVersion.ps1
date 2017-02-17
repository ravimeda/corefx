<#
.SYNOPSIS
    Compares the version of the prerequisite executable at the given path with the declared version. 
    Returns true if versions match. Otherwise, false
.PARAMETER PrerequisitePath
    Path to the prerequisite executable for which version check is required.
.PARAMETER PrerequisiteName
    Name of the prerequisite.
.PARAMETER RepoRoot
    Repository root path.
.EXAMPLE
    .\Test-PrerequisiteVersion.ps1 
    -PrerequisitePath "C:\Users\dotnet\Source\Repos\corefx\Tools\Downloads\CMake\cmake-3.7.2-win64-x64\bin\cmake.exe" -RepoRoot "C:\Users\dotnet\Source\Repos\corefx"
    Returns true since declared version is 3.7.2, which is same as the version of the executable at the given path.
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$PrerequisitePath,
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=1)]
    [string]$PrerequisiteName,
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=2)]
    [string]$RepoRoot
)

if (-not (Test-Path -Path $PrerequisitePath -PathType Leaf))
{
    Write-Error "Unable to access the executable at the given path. Path: $PrerequisitePath"
    return $false
}

if (-not (Test-Path -Path $RepoRoot -PathType Container))
{
    Write-Error "Unable to access repository root. RepoRoot: $RepoRoot"
    return $false
}

function IsDeclaredVersion
{
    $declaredCMakeVersion = & $PSScriptRoot\Get-DeclaredPrerequisiteVersion.ps1 -PrerequisiteName $PrerequisiteName -RepoRoot $RepoRoot

    if ([string]::IsNullOrWhiteSpace($declaredCMakeVersion))
    {
        Write-Error "Unable to read the declared version of the prerequisite from .prerequisiteversions file."
        return $false
    }

    $versionText = & $PrerequisitePath "-version"

    if (-not [string]::IsNullOrWhiteSpace($versionText) -and $versionText -imatch "cmake version $declaredCMakeVersion")
    {
        return $true
    }
}

try
{
    switch ($PrerequisiteName)
    {
        "CMake"
        {
            return IsDeclaredVersion
        }
        default
        {
            Write-Error "Unable to test the version of prerequisite named $PrerequisiteName."
        }
    }
}
catch
{
    Write-Error $_.Exception.Message
}

return $false
