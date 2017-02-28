<#
.SYNOPSIS
    Gets the path to CMake executable. Searches for the tool on the local machine. 
    If the tool is not found then, attempts to acquire the tool.
    Returns an error message if unable to get the path.
.PARAMETER StrictToolVersionMatch
    If specified then, ensures the version of CMake to be searched matches the declared version.
.PARAMETER DeclaredVersion
    Declared version of the tool. 
    If not specified, declared version will be determined by invoking GetDeclaredtoolVersion helper function.
.EXAMPLE
    .\Search-tool.ps1 -ToolName "CMake"
    Gets the path to CMake executable. For example, "C:\Users\dotnet\Source\Repos\corefx\Tools-Local\Downloads\CMake\cmake-3.7.2-win64-x64\bin\cmake.exe".
#>

[CmdletBinding()]
param(
    [switch]$StrictToolVersionMatch,
    [string]$DeclaredVersion
)

function GetCMakeVersions
{
    $items = @()
    $items += @(Get-ChildItem hklm:\SOFTWARE\Wow6432Node\Kitware -ErrorAction SilentlyContinue)
    $items += @(Get-ChildItem hklm:\SOFTWARE\Kitware -ErrorAction SilentlyContinue)
    return $items | where { $_.PSChildName.StartsWith("CMake ") }
}

function GetCMakeInfo($regKey)
{
    # This no longer works for versions 3.5+
    try
    {
        $version = [System.Version] $regKey.PSChildName.Split(' ')[1]
    }
    catch
    {
        return $null
    }

    $cmakeDir = (Get-ItemProperty $regKey.PSPath).'(default)'
    $cmakePath = [System.IO.Path]::Combine($cmakeDir, "bin\cmake.exe")

    if (![System.IO.File]::Exists($cmakePath))
    {
        return $null
    }
    return @{'version' = $version; 'path' = $cmakePath}
}

function LocateCMakeExecutable
{
    $environmentCMakePath = (get-command cmake.exe -ErrorAction SilentlyContinue).Path
    if ($environmentCMakePath -ne $null)
    {
        if (IsCMakePathValid -CMakePath $environmentCMakePath)
        {
            return $environmentCMakePath
        }
    }

    # Check the default installation directory
    $inDefaultPath = Join-Path "$($env:ProgramFiles)" "CMake\bin\cmake.exe"
    if (-not (Test-Path -Path $inDefaultPath -PathType Leaf))
    {
        $inDefaultPath = Join-Path "$(${env:ProgramFiles(x86)})" "CMake\bin\cmake.exe"
    }

    if (IsCMakePathValid -CMakePath $inDefaultPath)
    {
        return $inDefaultPath
    }

    # Let us hope that CMake keep using their current version scheme
    $validVersions = @()

    foreach ($regKey in GetCMakeVersions)
    {
        $info = GetCMakeInfo($regKey)

        if ($info -ne $null)
        {
            $validVersions += @($info)
        }
    }

    $newestCMakePath = ($validVersions | Sort-Object -property @{Expression={$_.version}; Ascending=$false} | Select -first 1).path
    if ($newestCMakePath -ne $null -and (IsCMakePathValid -CMakePath $newestCMakePath))
    {
        return $newestCMakePath
    }

    # Check if the declared version of CMake is available in the downloads folder.
    $CMakePath = GetRepoToolPath -RepoRoot $repoRoot -DeclaredVersion $DeclaredVersion

    if (-not [string]::IsNullOrWhiteSpace($CMakePath) -and (Test-Path -Path $CMakePath -PathType Leaf))
    {
        $newestCMakePath = $CMakePath
    }
    else
    {
        # Acquire CMake.
        Invoke-Expression -Command ".\Get-Tool.ps1 -RepoRoot $repoRoot -DeclaredVersion $DeclaredVersion *>&1" -OutVariable newestCMakePath | Out-Null

        if ($newestCMakePath -ne $null)
        {
            $newestCMakePath = $newestCMakePath.ToolPath
        }
    }

    if (IsCMakePathValid -CMakePath $newestCMakePath)
    {
        return $newestCMakePath
    }

    return ""
}

function IsCMakePathValid
{
    param(
        [ValidateNotNullOrEmpty()] 
        [parameter(Mandatory=$true, Position=0)]
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
    $CMakeExecutablePath = LocateCMakeExecutable

    # Check if the path obtained is valid.
    if ([string]::IsNullOrWhiteSpace($CMakeExecutablePath))
    {
        return "CMake is a tool to build this repository but it was not found on the path. " + "`r`n" +
                "Please try one of the following options to acquire CMake version $DeclaredVersion. " + "`r`n" +
                    "1. Install CMake version from http://www.cmake.org/download/, and ensure cmake.exe is on your path. " + "`r`n" +
                    "2. Run the script located at $((Get-Location).Path)\Get-tool.ps1 " + "`r`n"
    }

    return $([System.IO.Path]::GetFullPath($CMakeExecutablePath))
}

# Dot source the helper file.
. .\CMake-Helper.ps1

$repoRoot = GetRepoRoot

if ([string]::IsNullOrWhiteSpace($DeclaredVersion))
{
    $DeclaredVersion = GetDeclaredVersion -RepoRoot $repoRoot
}

try 
{
    # Get the path to CMake executable.
    $CMakePath = GetCMakePath

    return "$CMakePath"
}
catch
{
    Write-Error $_.Exception.Message
}
