<#
.SYNOPSIS
    Searches for the declared version of the tool in Tools\downloads folder.
    If tool is not found then, attempts to downloads the tools from internet.
    Returns an empty string if unable to locate or download the tool.
.PARAMETER ToolName
    Name of the tool.
.PARAMETER StrictToolVersionMatch
    If specified then, ensures the version of the tool searched matches the declared version.
.EXAMPLE
    .\Get-Tool.ps1 -ToolName "CMake"
    Gets the path to CMake executable. For example, "C:\Program Files\CMake\bin\cmake.exe".
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$ToolName,
    [string]$StrictToolVersionMatch
)

# Search for CMake in Tools\downloads.
function LocateCMakeExecutable
{
    # Check if the declared version of CMake is available in the downloads folder.
    $toolPath = & GetCMakeRepoToolPath

    if (-not (IsCMakeDeclaredVersion -ToolPath $toolPath))
    {
        # CMake is not available in Tools\downloads folder. Hence attempt to download CMake from internet.
        $repoRoot = GetRepoRoot
        $declaredVersion = GetDeclaredVersion -ToolName $ToolName
        $toolPath = & "$repoRoot\tools-local\internet\windows\get-tool.ps1" -ToolName $ToolName -DeclaredVersion $declaredVersion
    }

    return $toolPath
}

# Search for MyCustomTool in Tools\downloads.
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
            Write-Error "Tool is not supported. Tool name: $ToolName."
        }
    }
}
catch
{
    Write-Error $_.Exception.Message
}

return "$toolPath"
