<#
.SYNOPSIS
    Gets the path to the declared version of the tool executable within the repository.
    If the executable is not found then, returns an empty string.
.PARAMETER ToolName
    Name of the tool whose path needs to be determined.
.PARAMETER RepoRoot
    Repository root path.
.PARAMETER DeclaredVersion
    Declared version of the tool for this repository. 
    If not specified, declared version will be determined by invoking ./Get-DeclaredtoolVersion.ps1.
.PARAMETER toolPackageName
    Package name corresponding to the declared version of the tool . 
    If not specified, package name will be determined by invoking ./Get-toolPackageName.ps1.
.EXAMPLE
    .\Get-RepotoolPath.ps1 -ToolName "CMake" -RepoRoot "C:\Users\dotnet\Source\Repos\corefx"
    Gets the path to CMake executable, which is "C:\Users\dotnet\Source\Repos\corefx\Tools-Local\Downloads\CMake\cmake-3.7.2-win64-x64\bin\cmake.exe", 
    for repository whose root is "C:\Users\dotnet\Source\Repos\corefx".
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$ToolName,
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=1)]
    [string]$RepoRoot,
    [string]$DeclaredVersion,
    [string]$toolPackageName
)

function GetCMakePackageName
{
    if ([string]::IsNullOrWhiteSpace($toolPackageName))
    {
        if ([string]::IsNullOrWhiteSpace($DeclaredVersion))
        {
            $DeclaredVersion = & $PSScriptRoot\Get-DeclaredtoolVersion.ps1 -ToolName "$ToolName" -RepoRoot "$RepoRoot"

            if ([string]::IsNullOrWhiteSpace($DeclaredVersion))
            {
                Write-Error "Unable to read the declared version of $ToolName from .toolversions file."
                return ""
            }
        }

        $toolPackageName = & $PSScriptRoot\Get-toolPackageName.ps1 -ToolName "$ToolName" -DeclaredVersion $DeclaredVersion

        if([string]::IsNullOrWhiteSpace($toolPackageName))
        {
            Write-Error "Unable to determine the package name corresponding to $ToolName version $DeclaredVersion"
            return ""
        }
    }

    return $toolPackageName
}

if (-not (Test-Path -Path $RepoRoot -PathType Container))
{
    Write-Error "Unable to access repository root. RepoRoot: $RepoRoot"
    return ""
}

$downloadsPrereqPath = ""

try 
{
    switch ($ToolName)
    {
        "CMake"
        {
            $toolPackageName = GetCMakePackageName
            $downloadsPrereqPath = [System.IO.Path]::GetFullPath($(Join-Path "$RepoRoot" "Tools-Local\Downloads\CMake\$toolPackageName\bin\cmake.exe"))
        }
        default
        {
            Write-Error "Unable to determine the path to the executable corresponding to tool named $ToolName."
        }
    }
}
catch
{
    Write-Error $_.Exception.Message
}

return $downloadsPrereqPath
