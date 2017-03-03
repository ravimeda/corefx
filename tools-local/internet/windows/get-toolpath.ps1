<#
.SYNOPSIS
    Gets the path to the specified tool.
    Searches for the declared version of the tool in the Tools\downloads folder.
    If tool is not found then, attempts to downloads the tools from internet.
    Returns an empty string if unable to locate or download the tool.
.PARAMETER ToolName
    Name of the tool.
.PARAMETER DeclaredVersion
    Declared version of the specified tool.
.EXAMPLE
    .\get-toolpath.ps1 -ToolName "CMake" -DeclaredVersion "3.7.2"
    Gets the path to CMake executable.
    For example, "C:\Users\dotnet\Source\Repos\corefx\Tools\downloads\CMake\cmake-3.7.2-win64-x64\bin\cmake.exe"
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$ToolName,
    [parameter(Mandatory=$true, Position=1)]
    [string]$DeclaredVersion
)

function LocateCMakeExecutable
{
    # Check if the declared version of CMake is available in the downloads folder.
    $toolPath = & GetRepoToolPath -ToolName $ToolName -DeclaredVersion $DeclaredVersion

    if ([string]::IsNullOrWhiteSpace($toolPath) -or -not (Test-Path -Path $toolPath -PathType Leaf))
    {
        # Download CMake.
        $repoRoot = & GetRepoRoot
        $toolPath = $(& "$repoRoot\tools-local\internet\windows\get-tool.ps1" -ToolName $ToolName -DeclaredVersion $DeclaredVersion).ToolPath
    }

    if (IsCMakePathValid -CMakePath $toolPath)
    {
        return $toolPath
    }
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
            Write-Error "Tool is not supported. Tool name: $ToolName."
        }
    }
}
catch
{
    Write-Error $_.Exception.Message
}

return "$toolPath"
