<#
.SYNOPSIS
    Searches environment path and Program Files for the specified tool.

    If StrictToolVersionMatch is true then, attempts to locate for the 
    declared version of the tool in environment path and Program Files.
    Returns the path to the tool if found. Else, return empty string.

    If StrictToolVersionMatch is false then, attempts to locate the 
    path to the tool whose version is most preferred. Preference order 
    is declared version followed by the nearest version to declared version.
    Returns an empty string if unable to locate any version of tool.
.PARAMETER ToolName
    Name of the tool.
.PARAMETER StrictToolVersionMatch
    If the value is true, ensures the version of the tool searched matches the declared version.
.EXAMPLE
    .\get-toolpath.ps1 -ToolName "CMake"
    Gets the path to CMake executable. For example, "C:\Program Files\CMake\bin\cmake.exe".
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$ToolName,
    [string]$StrictToolVersionMatch
)

# Search for CMake.
function LocateCMakeExecutable
{
    $availableCMakePaths = @()

    # Search for CMake in environment path.
    $environmentCMakePath = (get-command cmake.exe -ErrorAction SilentlyContinue).Path

    if (IsCMakeDeclaredVersion -ToolPath "$environmentCMakePath")
    {
        # Declared version of CMake is found in environment path.
        return [System.IO.Path]::GetFullPath("$environmentCMakePath")
    }
    elseif (-not [string]::IsNullOrWhiteSpace("$environmentCMakePath"))
    {
        $availableCMakePaths += "$environmentCMakePath"
    }

    # Search for CMake under Program Files.
    $programFilesCMakePath = Join-Path "$($env:ProgramFiles)" "CMake\bin\cmake.exe"
    if (-not (Test-Path -Path $programFilesCMakePath -PathType Leaf))
    {
        $programFilesCMakePath = Join-Path "$(${env:ProgramFiles(x86)})" "CMake\bin\cmake.exe"
    }

    if (IsCMakeDeclaredVersion -ToolPath "$programFilesCMakePath")
    {
        # Declared version of CMake is found in Program files.
        return [System.IO.Path]::GetFullPath("$programFilesCMakePath")
    }
    elseif (-not [string]::IsNullOrWhiteSpace("$programFilesCMakePath"))
    {
        $availableCMakePaths += "$programFilesCMakePath"
    }

    # Declared version of CMake is neither in environment path nor in Program Files.
    # If StrictToolVersionMatch is true then return an empty string here.
    # Else return the path where any version of CMake is available.
    $toolPath = ""

    if ($StrictToolVersionMatch -ieq $false)
    {
        foreach ($path in $availableCMakePaths)
        {
            # TODO: Implement a preference order. If CMake is available in both environment path and Program Files then, 
            # compare the versions, and return the version closer/nearer to declared version.
            if (Test-Path -Path "$path" -PathType Leaf -ErrorAction SilentlyContinue)
            {
                $toolPath = [System.IO.Path]::GetFullPath("$path")
                break
            }
        }
    }

    return "$toolPath"
}

# Search for MyCustomTool.
function LocateMyCustomToolExecutable
{

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
        "MyCustomTool"
        {
            $toolPath = LocateMyCustomToolExecutable
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
