<#
.SYNOPSIS
    Gets the name of prerequisite package corresponding to the given declared version. 
    Reads the declared version of prerequisite from .prerequisiteversions file. 
    Detects the architecture of the operating system, and determines the package name.
    Returns an empty string if unable to determine the package name.
.PARAMETER PrerequisiteName
    Name of the prerequisite whose package name is to be obtained.
.PARAMETER DeclaredVersion
    Declared version of prerequisite for which package name is to be obtained.
.EXAMPLE
    .\Get-PrerequisitePackageName.ps1 -PrerequisiteName "CMake" -DeclaredVersion "3.7.2"
    Gets the package name for version 3.7.2, which is cmake-3.7.2-win64-x64 for 64-bit operating system.
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$PrerequisiteName,
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
    switch ($PrerequisiteName)
    {
        "CMake"
        {
            $prereqPackageName = GetCMakePackageName
        }
        default
        {
            Write-Error "Unable to get the package name for prerequisite named $PrerequisiteName."
        }
    }
}
catch
{
    Write-Error $_.Exception.Message
}

return $prereqPackageName
