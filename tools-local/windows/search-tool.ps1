<#
.SYNOPSIS
    Searches for the tool in the environment path, and a path specified for the tool in the .toolversions file. 
    If search is successful then, returns the path to the tool.
.PARAMETER RepositoryRoot
    Path to repository root.
.PARAMETER ToolName
    Name of the tool to search.
.PARAMETER OverrideScriptsFolderPath
    If a path is specified then, scripts from the specified folder will be invoked. 
    Otherwise, the default scripts located within the repository will be invoked.
.PARAMETER ExtraArgs
    Additional parameters. For example, specifying StrictToolVersionMatch switch will ensure that the version of the tool searched is the declared version. 
    Otherwise, search will attempt to find a version of the tool, which may not be the declared version.
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
    [parameter(ValueFromRemainingArguments=$true)]
    [string]$ExtraArgs
)

. $PSScriptRoot\tool-helper.ps1
$DeclaredVersion = Get-ToolConfigValue "$RepositoryRoot" "$ToolName" "DeclaredVersion"

# Searches the tool in environment path.
function Find-Environment
{
    Write-LogMessage "$RepositoryRoot" "Searching for $ToolName in environment path."
    $toolPath = (Get-Command $ToolName -ErrorAction SilentlyContinue).Path

    if ([string]::IsNullOrWhiteSpace($toolPath) -or -not (Test-Path $toolPath -PathType Leaf))
    {
        return
    }

    $toolVersion = Invoke-ExtensionScript "get-version.ps1" "$RepositoryRoot" "$ToolName" "$OverrideScriptsFolderPath" "$toolPath"
    Write-LogMessage "$RepositoryRoot" "Version of $ToolName at $toolPath is $ToolVersion."

    if (-not $StrictToolVersionMatch)
    {
        # No strictToolVersionMatch. Hence, return the path found without version check.
        return "$toolPath"
    }

    # If strictToolVersionMatch is required then, ensure the version in environment path is same as declared version.
    if ("$toolVersion" -eq "$DeclaredVersion")
    {
        return "$toolPath"
    }

    Write-LogMessage "$RepositoryRoot" "Version of $ToolName at $toolPath is $toolVersion. This version does not match the declared version $DeclaredVersion."
}

# Searches the tool in install locations specified in the .toolversions file.
function Find-InstallLocations
{
    $searchPaths = Get-ToolConfigValue "$RepositoryRoot" "$ToolName" "SearchPathsWindows" -IsMultiLine
    $searchPaths = Update-PathText $searchPaths
    $pathsVersions = @{}

    # Prepare a hashtable where the key is a path where the tool is available, and the corresponding value is the version of the executable at that path.
    foreach ($toolPath in $searchPaths)
    {
        Write-LogMessage "$RepositoryRoot" "Searching for $ToolName in $toolPath."

        if (Test-Path -Path "$toolPath" -PathType Any)
        {
            $toolVersion = Invoke-ExtensionScript "get-version.ps1" "$RepositoryRoot" "$ToolName" "$OverrideScriptsFolderPath" "$toolPath"
            $pathsVersions.Add($toolPath, $toolVersion)
        }
    }

    # Return the path where declared version of the tool is available.
    $pathsVersions.GetEnumerator() | % {
        if ($_.Value -eq "$DeclaredVersion") 
        {
            $toolPath = "$_.Key"
            $toolVersion = "$_.Value"
            Write-LogMessage "$RepositoryRoot" "Version of $ToolName at $toolPath is $toolVersion."
            return "$toolPath"
        }
    }

    # Since declared version is not available, return the first path in the table only if strictToolVersionMatch is not required.
    if (-not $StrictToolVersionMatch)
    {
        $pathsVersions.GetEnumerator() | % {
            if (-not [string]::IsNullOrWhiteSpace($_.Key)) 
            {
                $toolPath = "$_.Key"
                $toolVersion = "$_.Value"
                Write-LogMessage "$RepositoryRoot" "Version of $ToolName at $toolPath is $toolVersion."
                return "$toolPath"
            }
        }
    }
}

# Searches the tool in the local tools cache.
function Find-Cache
{
    Write-LogMessage "$RepositoryRoot" "Searching for $ToolName in local tools cache."
    $toolPath = Get-LocalSearchPath "$RepositoryRoot" "$ToolName"

    if (-not (Test-Path -Path "$toolPath" -PathType Leaf))
    {
        Write-LogMessage "$RepositoryRoot" "Unable to locate $ToolName at $toolPath."
        return
    }

    $toolVersion = Invoke-ExtensionScript "get-version.ps1" "$RepositoryRoot" "$ToolName" "$OverrideScriptsFolderPath" "$toolPath"

    if ("$toolVersion" -eq "$DeclaredVersion")
    {
        Write-LogMessage "$RepositoryRoot" "Version of $ToolName at $toolPath is $toolVersion."
        return "$toolPath"
    }
}

$searchResult=""

# Begin search in the environment path
$searchResult = Find-Environment

# Search in Program Files
if ([string]::IsNullOrWhiteSpace($searchResult))
{
    $searchResult = Find-InstallLocations
}

# Since the tool or the required version was not found in environment and system wide install locations, 
# search the tool in the local tools cache specified in the .toolversions file.
if ([string]::IsNullOrWhiteSpace($searchResult))
{
    $searchResult = Find-Cache
}

return "$searchResult"
