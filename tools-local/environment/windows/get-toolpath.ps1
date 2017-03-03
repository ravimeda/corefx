<#
.SYNOPSIS
    Gets the path to the specified tool. 
    Searches for the tool in the local environment path and Program Files.
    Attempts to locate the declared version of the tool.
    Returns an empty string if unable to locate any version of tool.
.PARAMETER ToolName
    Name of the tool.
.PARAMETER DeclaredVersion
    Declared version of the specified tool.
.EXAMPLE
    .\get-tool.ps1 -ToolName "CMake" -DeclaredVersion "3.7.2"
    Gets the path to CMake executable. For example, "C:\Program Files\CMake\bin\cmake.exe".
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$ToolName,
    [parameter(Mandatory=$true, Position=1)]
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
    $CMakePath = ""
    $searchPaths = @()

    # Search for CMake in environment path.
    $environmentCMakePath = (get-command cmake.exe -ErrorAction SilentlyContinue).Path

    if (IsCMakePathValid -CMakePath $environmentCMakePath)
    {
        return $environmentCMakePath
    }
    
    $searchPaths = $searchPaths + $environmentCMakePath

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

    $searchPaths = $searchPaths + $inDefaultPath

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

    $validVersions | % {
        if ($_ -ieq $DeclaredVersion)
        {
            $regCMakePath = $_.path
        }
    }

    if (IsCMakePathValid -CMakePath $regCMakePath)
    {
        return $regCMakePath
    }

    $searchPaths = $searchPaths + $regCMakePath
    foreach ($path in $searchPaths)
    {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -Path $path -PathType Leaf))
        {
            $CMakePath = $path
            break
        }
    }

    return $CMakePath
}

function IsCMakePathValid
{
    param(
        [string]$CMakePath
    )

    if (-not [string]::IsNullOrWhiteSpace($CMakePath) -and (Test-Path -Path $CMakePath -PathType Leaf) -and (TestVersion -ToolPath $CMakePath -DeclaredVersion $DeclaredVersion))
    {
        return $true
    }

    return $false
}

$toolPath = ""
# Dot source helper file.
. $PSScriptRoot\..\..\helper\windows\tool-helper.ps1

try 
{
    switch ($ToolName)
    {
        "CMake"
        {
            $toolPath = LocateCMakeExecutable
        }
        default
        {
            Write-Error "Tool name is not supported. Tool name: $ToolName."
        }
    }
}
catch
{
    Write-Error $_.Exception.Message
}

return "$toolPath"
