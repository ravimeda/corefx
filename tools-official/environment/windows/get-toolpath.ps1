<#
.SYNOPSIS
    Searches environment path and Program Files for the declared version of the specified tool.
    Returns the path to tool if found. Otherwise, returns an empty string.
.PARAMETER ToolName
    Name of the tool.
.EXAMPLE
    .\get-toolpath.ps1 -ToolName "CMake"
    Gets the path to CMake executable. For example, "C:\Program Files\CMake\bin\cmake.exe".
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$ToolName
)

# Search for CMake.
function LocateCMakeExecutable
{
    # Search for CMake in environment path.
    $environmentCMakePath = (get-command "cmake.exe" -ErrorAction SilentlyContinue).Path

    if (IsCMakeDeclaredVersion -ToolPath "$environmentCMakePath")
    {
        # Declared version of CMake is found in environment path.
        return [System.IO.Path]::GetFullPath("$environmentCMakePath")
    }

    # Search for CMake in Program Files.
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

    # Declared version of CMake is neither in environment path nor in Program Files.
    return ""
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
