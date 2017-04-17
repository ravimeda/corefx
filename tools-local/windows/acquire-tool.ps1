<#
.SYNOPSIS
    Downloads the declared version of the specified tool from the corresponding URL specified in the .toolversions file. 
    If download succeeds then, returns the path to the executable.
.PARAMETER RepositoryRoot
    Path to repository root.
.PARAMETER ToolName
    Name of the tool to download.
.PARAMETER OverrideScriptsFolderPath
    If a path is specified then, scripts from the specified folder will be invoked. 
    Otherwise, the default scripts located within the repository will be invoked.
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
    [string]$OverrideScriptsFolderPath
)

. $PSScriptRoot\tool-helper.ps1
$DeclaredVersion = get_tool_config_value "$RepositoryRoot" "$ToolName" "DeclaredVersion"

# Downloads the package corresponding to the tool, and extracts the package.
function download_extract
{
    # Get the download URL
    $downloadUrl = get_tool_config_value "$RepositoryRoot" "$ToolName" "DownloadUrl"
    $downloadPackageFilename = get_download_file "$RepositoryRoot" "$ToolName"
    $downloadUrl = "$downloadUrl$downloadPackageFilename"

    # Create folder to save the downloaded package, and extract the package contents.
    $toolFolder = get_local_tool_folder "$RepositoryRoot" "$ToolName"
    Remove-Item -Path "$toolFolder" -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path "$toolFolder" -ItemType Directory | Out-Null
    $downloadPackagePath = Join-Path "$toolFolder" "$downloadPackageFilename"

    log_message "$RepositoryRoot" "Attempting to download $ToolName from $downloadUrl to $downloadPackagePath."
    $downloadLog = Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPackagePath -DisableKeepAlive -UseBasicParsing -PassThru -ErrorAction Stop
    log_message "$RepositoryRoot" "Download Status Code: $($downloadLog.StatusCode)"

    log_message "$RepositoryRoot" "Attempting to extract $downloadPackagePath to $toolFolder."
    Expand-Archive -Path $downloadPackagePath -DestinationPath $toolFolder -Force -ErrorAction Stop | Out-Null
    log_message "$RepositoryRoot" "Extracted successfully to $toolFolder."
}

# Validates if the tool is available at toolPath, and the version of the tool is the declared version.
function validate_toolpath
{
    $toolPath = get_local_search_path "$RepositoryRoot" "$ToolName"

    if (-not (Test-Path -Path "$toolPath" -PathType Leaf))
    {
        return "Unable to locate $ToolName at $toolPath."
    }

    $toolVersion = invoke_extension "get-version.ps1" "$RepositoryRoot" "$ToolName" "$OverrideScriptsFolderPath" "$toolPath"

    if ("$toolVersion" -ne "$DeclaredVersion")
    {
        return "Version of $toolPath is $toolVersion, which does not match the declared version $DeclaredVersion."
    }

    log_message "$RepositoryRoot" "$ToolName is available at $toolPath. Version is $toolVersion."
    return "$toolPath"
}

# Download and extract the tool.
download_extract

# Validate the download.
return validate_toolpath
