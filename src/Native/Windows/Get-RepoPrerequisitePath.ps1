<#
.SYNOPSIS
    Gets the path to the declared version of the prerequisite executable within the repository.
    If the executable is not found then, returns an empty string.
.PARAMETER PrerequisiteName
    Name of the prerequisite whose path needs to be determined.
.PARAMETER RepoRoot
    Repository root path.
.PARAMETER DeclaredVersion
    Declared version of the prerequisite for this repository. 
    If not specified, declared version will be determined by invoking ./Get-DeclaredPrerequisiteVersion.ps1.
.PARAMETER PrerequisitePackageName
    Package name corresponding to the declared version of the prerequisite . 
    If not specified, package name will be determined by invoking ./Get-PrerequisitePackageName.ps1.
.EXAMPLE
    .\Get-RepoPrerequisitePath.ps1 -PrerequisiteName "CMake" -RepoRoot "C:\Users\dotnet\Source\Repos\corefx"
    Gets the path to CMake executable, which is "C:\Users\dotnet\Source\Repos\corefx\Tools\Downloads\CMake\cmake-3.7.2-win64-x64\bin\cmake.exe", 
    for repository whose root is "C:\Users\dotnet\Source\Repos\corefx".
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$PrerequisiteName,
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=1)]
    [string]$RepoRoot,
    [string]$DeclaredVersion,
    [string]$PrerequisitePackageName
)

function GetCMakePackageName
{
    if ([string]::IsNullOrWhiteSpace($PrerequisitePackageName))
    {
        if ([string]::IsNullOrWhiteSpace($DeclaredVersion))
        {
            $DeclaredVersion = & $PSScriptRoot\Get-DeclaredPrerequisiteVersion.ps1 -PrerequisiteName "$PrerequisiteName" -RepoRoot "$RepoRoot"

            if ([string]::IsNullOrWhiteSpace($DeclaredVersion))
            {
                Write-Error "Unable to read the declared version of $PrerequisiteName from .prerequisiteversions file."
                return ""
            }
        }

        $PrerequisitePackageName = & $PSScriptRoot\Get-PrerequisitePackageName.ps1 -PrerequisiteName "$PrerequisiteName" -DeclaredVersion $DeclaredVersion

        if([string]::IsNullOrWhiteSpace($PrerequisitePackageName))
        {
            Write-Error "Unable to determine the package name corresponding to $PrerequisiteName version $DeclaredVersion"
            return ""
        }
    }

    return $PrerequisitePackageName
}

if (-not (Test-Path -Path $RepoRoot -PathType Container))
{
    Write-Error "Unable to access repository root. RepoRoot: $RepoRoot"
    return ""
}

$downloadsPrereqPath = ""

try 
{
    switch ($PrerequisiteName)
    {
        "CMake"
        {
            $PrerequisitePackageName = GetCMakePackageName
            $downloadsPrereqPath = [System.IO.Path]::GetFullPath($(Join-Path "$RepoRoot" "Tools\Downloads\CMake\$PrerequisitePackageName\bin\cmake.exe"))
        }
        default
        {
            Write-Error "Unable to determine the path to the executable corresponding to prerequisite named $PrerequisiteName."
        }
    }
}
catch
{
    Write-Error $_.Exception.Message
}

return $downloadsPrereqPath
