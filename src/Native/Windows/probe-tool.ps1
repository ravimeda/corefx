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

# Checks if the given tool path exists.
# True, if exists. False, otherwise.
function IsPathNullOrWhiteSpace
{
    param(
        [string]$ToolPath
    )

    try
    {
        if ([string]::IsNullOrWhiteSpace($ToolPath) -or -not (Test-Path -LiteralPath "$ToolPath" -PathType Leaf -ErrorAction SilentlyContinue))
        {
            return $true
        }
    }
    catch
    {}

    return $false
}

# Prepares a tool specific error message.
# Error message will include the tool name, version and URL from where the tool can be downloaded.
# Message will also provide an option where a script, on behalf of the user, downloads the tool 
# and make the tool available for build.
function GetErrorMessage
{
    # Dot source helper file.
    . $PSScriptRoot\..\..\..\tools-local\helper\windows\tool-helper.ps1
    $repoRoot = GetRepoRoot
    $declaredVersion = GetDeclaredVersion -ToolName $ToolName

    switch ($ToolName)
    {
        "CMake"
        {
            return "CMake is a prerequisite to build this repository but it was not found on the path. " + "`r`n" +
                    "Please try one of the following options to acquire CMake version $declaredVersion. " + "`r`n" +
                        "1. Install CMake version from http://www.cmake.org/download/, and ensure cmake.exe is on your path. " + "`r`n" +
                        "2. Run the script located at $([System.IO.Path]::GetFullPath(`"$repoRoot\tools-local\internet\windows\get-tool.ps1`")) " + "`r`n"
        }
        "MyCustomTool"
        {
            return "MyCustomTool is a prerequisite to build this repository but it was no found on the path..."
        }
        default
        {
            return ""
        }
    }
}


$toolPath = ""
try
{
    # Get search locations and download URLs for the specified tool.
    [xml]$toolVersionsInfo = Get-Content -Path "..\..\..\.toolversions"
    $searchLocations = @()
    $downloadUrls = @()

    foreach ($tool in $toolVersionsInfo.BuildTools.Tool)
    {
        if ($tool.Name -ieq $ToolName)
        {
            $declaredVersion = $tool.DeclaredVersion
            $searchLocations = $tool.SearchLocations
            $downloadUrls = $tool.DownloadURLs
            break
        }
    }

    # Check if the tool is already available.
    $toolPath = Search-Tool -SearchLocations $searchLocations -ToolName $ToolName -DeclaredVersion $declaredVersion -StrictToolVersionMatch $StrictToolVersionMatch

    # If available then, return the path.
    if (IsPathNullOrWhiteSpace -ToolPath $toolPath)
    {
        return $toolPath
    }

    # Since the tool was not found, download the tool.
    $toolPath = Get-Tool -DownloadURLs $downloadUrls -ToolName $ToolName -DeclaredVersion $declaredVersion -StrictToolVersionMatch $StrictToolVersionMatch
    if (IsPathNullOrWhiteSpace -ToolPath $toolPath)
    {
        return $toolPath
    }

    # Return an error message since all attempts to get the tool have failed.
    return GetErrorMessage
}
catch
{
    Write-Error $_.Exception.Message
}
