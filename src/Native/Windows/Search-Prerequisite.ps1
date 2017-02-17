<#
.SYNOPSIS
    Gets the path to the specified prerequisite. Searches for the prerequisite on the local machine. 
    If the prerequisite is not found then, attempts to acquire the prerequisite.
    Returns an error message if unable to get the path.
.PARAMETER PrerequisiteName
    Name of the prerequisite for which declared version needs to be obtained.
.PARAMETER StrictPrerequisiteVersionMatch
    If specified then, ensures the version of the specified prerequisite available for the build matches the declared version.
.EXAMPLE
    .\Search-Prerequisite.ps1 -PrerequisiteName "CMake"
    Gets the path to CMake executable. For example, "C:\Users\dotnet\Source\Repos\corefx\Tools\Downloads\CMake\cmake-3.7.2-win64-x64\bin\cmake.exe".
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$PrerequisiteName,
    [switch]$StrictPrerequisiteVersionMatch
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
    $inDefaultPath = [System.IO.Path]::Combine(${Env:ProgramFiles(x86)}, "CMake\bin\cmake.exe")
    if ([System.IO.File]::Exists($inDefaultPath))
    {
        if (IsCMakePathValid -CMakePath $inDefaultPath)
        {
            return $inDefaultPath
        }
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
    $prerequisitePath = & $PSScriptRoot\Get-RepoPrerequisitePath.ps1 -PrerequisiteName $PrerequisiteName -RepoRoot $repoRoot

    if (-not [string]::IsNullOrWhiteSpace($prerequisitePath) -and (Test-Path -Path $prerequisitePath -PathType Leaf))
    {
        $newestCMakePath = $prerequisitePath
    }
    else
    {
        # Acquire CMake.
        Invoke-Expression -Command ".\Get-Prerequisite.ps1 -PrerequisiteName $PrerequisiteName -RepoRoot $repoRoot -DeclaredVersion $declaredVersion *>&1" -OutVariable newestCMakePath | Out-Null

        if ($newestCMakePath -ne $null)
        {
            $newestCMakePath = $newestCMakePath.PrerequisitePath
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
        if ($StrictPrerequisiteVersionMatch -and -not (& $PSScriptRoot\Test-PrerequisiteVersion.ps1 -PrerequisitePath $CMakePath -PrerequisiteName $PrerequisiteName -RepoRoot $repoRoot))
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
    $CMakePath = LocateCMakeExecutable

    # Check if the path obtained is valid.
    if ([string]::IsNullOrWhiteSpace($CMakePath))
    {
        return "CMake is a prerequisite to build this repository but it was not found on the path. " + "`r`n" +
                        "Please try one of the following options to acquire CMake version $declaredVersion. " + "`r`n" +
                            "1. Install CMake version from http://www.cmake.org/download/, and ensure cmake.exe is on your path. " + "`r`n" +
                            "2. Run the script located at $((Get-Location).Path)\Get-Prerequisite.ps1 " + "`r`n"
    }

    return $([System.IO.Path]::GetFullPath($CMakePath))
}

$PrerequisitePath = ""
$repoRoot = Join-Path $PSScriptRoot "/../../.."
$declaredVersion = & $PSScriptRoot\Get-DeclaredPrerequisiteVersion.ps1 -PrerequisiteName $PrerequisiteName -RepoRoot $repoRoot

try 
{
    switch ($PrerequisiteName)
    {
        "CMake"
            {
                $PrerequisitePath = GetCMakePath
            }
    }

    return "$PrerequisitePath"
}
catch
{
    Write-Error $_.Exception.Message
}
