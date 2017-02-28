<#
.SYNOPSIS
    Gets the name of tool package corresponding to the given declared version. 
    Reads the declared version of tool from .toolversions file. 
    Detects the architecture of the operating system, and determines the package name.
    Returns an empty string if unable to determine the package name.
.PARAMETER toolName
    Name of the tool whose package name is to be obtained.
.PARAMETER DeclaredVersion
    Declared version of tool for which package name is to be obtained.
.EXAMPLE
    .\Get-toolPackageName.ps1 -toolName "CMake" -DeclaredVersion "3.7.2"
    Gets the package name for version 3.7.2, which is cmake-3.7.2-win64-x64 for 64-bit operating system.
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$toolName,
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=1)]
    [string]$DeclaredVersion
)

function GetCMakePackageName
{
    $prereqPackageName = "cmake-$($DeclaredVersion)-"

    if ([Environment]::Is64BitOperatingSystem)
    {
        $prereqPackageName += "win64-x64"
    }
    else
    {
        $prereqPackageName += "win32-x86"
    }

    return $prereqPackageName
}

$prereqPackageName = ""

try
{
    switch ($toolName)
    {
        "CMake"
        {
            $prereqPackageName = GetCMakePackageName
        }
        default
        {
            Write-Error "Unable to get the package name for tool named $toolName."
        }
    }
}
catch
{
    Write-Error $_.Exception.Message
}

return $prereqPackageName
