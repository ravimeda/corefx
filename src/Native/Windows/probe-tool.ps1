<#
.SYNOPSIS
    Gets the path to the specified tool. Searches for the tool in the local machine. 
    If the tool is not found then, attempts to acquire the tool.
    Returns an error message if unable to get the path.
.PARAMETER ToolName
    Name of the tool.
.PARAMETER StrictToolVersionMatch
    If specified then, ensures the version of tool searched matches the declared version.
.EXAMPLE
    .\get-tool.ps1 -ToolName "CMake"
    Gets the path to CMake executable. For example, "C:\Program Files\CMake\bin\cmake.exe".
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$ToolName,
    [switch]$StrictToolVersionMatch
)

# Search. If tool found then, return.
# Acquire. If successful then, return.
# Return an error message.
