<#
.SYNOPSIS
    Gets the path to the specified tool. Searches for the tool in the local machine. 
    If the tool is not found then, attempts to acquire the tool.
    Returns an error message if unable to get the path.
.PARAMETER ToolName
    Name of the tool.
.PARAMETER StrictToolVersionMatch
    If specified then, ensures the version of CMake to be searched matches the declared version.
.PARAMETER DeclaredVersion
    Declared version of the specified tool. 
    If not specified then, will determine using GetDeclaredVersion helper function.
.EXAMPLE
    .\Get-Tool.ps1 -ToolName "CMake"
    Gets the path to CMake executable. For example, "C:\Program Files\CMake\bin\cmake.exe".
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$ToolName,
    [switch]$StrictToolVersionMatch,
    [string]$DeclaredVersion
)

function IsCMakePathValid
{
    param(
        [string]$CMakePath
    )

    if (-not [string]::IsNullOrWhiteSpace($CMakePath) -and (Test-Path -Path $CMakePath -PathType Leaf))
    {
        if ($StrictToolVersionMatch -and -not (TestVersion -ToolPath $CMakePath -RepoRoot $repoRoot -DeclaredVersion $DeclaredVersion))
        {
            # Version of CMake available for the build is not the same as the declared version.
            return $false
        }

        # A version of CMake is available for the build.
        return $true
    }

    # CMake is not available, and could not be downloaded.
    return $false
}

function GetCMakePath
{
    # Search for CMake in environment path and Program Files.
    $CMakePath = & ..\..\..\tools-local\environment\windows\get-toolpath.ps1 -ToolName $ToolName -DeclaredVersion $DeclaredVersion

    if (-not (IsCMakePathValid -CMakePath $CMakePath))
    {
        # Get CMake from internet.
        $CMakePath = & ..\..\..\tools-local\internet\windows\get-toolpath.ps1 -ToolName $ToolName -DeclaredVersion $DeclaredVersion
    }

    # Check if the path obtained is valid.
    if ([string]::IsNullOrWhiteSpace($CMakePath))
    {
        return "CMake is a tool to build this repository but it was not found on the path. " + "`r`n" +
                "Please try one of the following options to acquire CMake version $DeclaredVersion. " + "`r`n" +
                    "1. Install CMake version from http://www.cmake.org/download/, and ensure cmake.exe is on your path. " + "`r`n" +
                    "2. Run the script located at $((Resolve-Path -Path "..\..\..\tools-local\internet\windows\get-toolpath.ps1").Path) " + "`r`n"
    }

    return $([System.IO.Path]::GetFullPath($CMakePath))
}

$toolPath = ""

# Dot source helper file.
. ..\..\..\tools-local\helper\windows\tool-helper.ps1

if ([string]::IsNullOrWhiteSpace($DeclaredVersion))
{
    $DeclaredVersion = GetDeclaredVersion -ToolName $ToolName
}

try 
{
    switch ($ToolName)
    {
        "CMake"
        {
            $toolPath = GetCMakePath
        }
        default
        {
            Write-Error "Tool is not supported. Tool name: $ToolName."
        }
    }

    return "$toolPath"
}
catch
{
    Write-Error $_.Exception.Message
}
