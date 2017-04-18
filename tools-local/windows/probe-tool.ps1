<#
.SYNOPSIS
    Invokes an extension that calls the appropriate search and/or acquire scripts. 
    ToolName, OverrideScriptsFolderPath and StrictToolVersionMatch parameters are passed on to the extension.
.PARAMETER RepositoryRoot
    Path to repository root.
.PARAMETER ToolName
    Name of the tool to search and/or download.
.PARAMETER OverrideScriptsFolderPath
    If a path is specified then, search and acquire scripts from the specified folder will be invoked. 
    Otherwise, search will use the default search and acquire scripts located within the repository.
.PARAMETER StrictToolVersionMatch
    If specified then, search will ensure that the version of the tool searched is the declared version. 
    Otherwise, search will attempt to find a version of the tool, which may not be the declared version.
.EXAMPLE
    .\probe-tool.ps1 "C:\Users\dotnet\Source\Repos\corefx" cmake "" ""
    Probes for CMake, not necessarily the declared version, using the default search and acquire scripts located within the repository.
.EXAMPLE
    .\probe-tool.ps1 "C:\Users\dotnet\Source\Repos\corefx" cmake "" "strict"
    Probes for the declared version of CMake using the default search and acquire scripts located within the repository.
.EXAMPLE
    .\probe-tool.ps1 "C:\Users\dotnet\Source\Repos\corefx" cmake "D:\dotnet\MyCustomScripts" "strict"
    Probes for the declared version of CMake using the search and acquire scripts located under "D:\dotnet\MyCustomScripts".
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [parameter(Mandatory=$true, Position=0)]
    [string]$RepositoryRoot,
    [ValidateNotNullOrEmpty()]
    [parameter(Mandatory=$true, Position=1)]
    [string]$ToolName,
    [parameter(Position=2)]
    [string]$OverrideScriptsFolderPath,
    [parameter(Position=3)]
    [switch]$StrictToolVersionMatch
)

if (-not [string]::IsNullOrWhiteSpace($OverrideScriptsFolderPath) -and -not (Test-Path $OverrideScriptsFolderPath -PathType Container))
{
    return "Path specified as override-scripts-folder-path does not exist or is not accessible. Path: $OverrideScriptsFolderPath"
}

$RepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)
. $PSScriptRoot\tool-helper.ps1
$invokeCmd = "Invoke-ExtensionScript"
$invokeArgs = "search-tool.ps1 `"$RepositoryRoot`" $ToolName `"$OverrideScriptsFolderPath`""

if ($StrictToolVersionMatch)
{
    $invokeArgs += " -StrictToolVersionMatch"
}

# Search the tool.
$toolPath = Invoke-Expression "$invokeCmd $invokeArgs"

# If search failed then, attempt to download the tool.
if ([string]::IsNullOrWhiteSpace($toolPath) -or -not (Test-Path $toolPath -PathType Leaf))
{
    $invokeArgs = "acquire-tool.ps1 `"$RepositoryRoot`" $ToolName `"$OverrideScriptsFolderPath`""
    $toolPath = Invoke-Expression "$invokeCmd $invokeArgs"
}

if ([string]::IsNullOrWhiteSpace($toolPath) -or -not (Test-Path $toolPath -PathType Leaf))
{
    # Download failed too, and hence return an error message.
    $message = Get-ToolNotFoundMessage "$RepositoryRoot" "$ToolName"
    return "$message"
}

return "$toolPath"
