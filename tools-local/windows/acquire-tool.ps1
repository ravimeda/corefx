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
.PARAMETER ExtraArgs
    Additional parameters passed to this script. These are ignored.
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

# Downloads the package corresponding to the tool, and extracts the package.
function Start-DownloadExtract
{
    # Get the download URL
    $downloadUrl = Get-ToolConfigValue "$RepositoryRoot" "$ToolName" "DownloadUrl"
    $downloadPackageFilename = Get-DownloadFile "$RepositoryRoot" "$ToolName"
    $downloadUrl = "$downloadUrl$downloadPackageFilename"

    # Create folder to save the downloaded package, and extract the package contents.
    $toolFolder = Get-LocalToolFolder "$RepositoryRoot" "$ToolName"
    Remove-Item -Path "$toolFolder" -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path "$toolFolder" -ItemType Directory | Out-Null
    $downloadPackagePath = Join-Path "$toolFolder" "$downloadPackageFilename"

    Write-LogMessage "$RepositoryRoot" "Attempting to download $ToolName from $downloadUrl to $downloadPackagePath."
    $downloadLog = Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPackagePath -DisableKeepAlive -UseBasicParsing -PassThru -ErrorAction Stop
    Write-LogMessage "$RepositoryRoot" "Download Status Code: $($downloadLog.StatusCode)"

    Write-LogMessage "$RepositoryRoot" "Attempting to extract $downloadPackagePath to $toolFolder."
    Expand-Archive -Path $downloadPackagePath -DestinationPath $toolFolder -Force -ErrorAction Stop | Out-Null
    Write-LogMessage "$RepositoryRoot" "Extracted successfully to $toolFolder."
}

# Validates if the tool is available at toolPath, and the version of the tool is the declared version.
function Confirm-Toolpath
{
    $toolPath = Get-LocalSearchPath "$RepositoryRoot" "$ToolName"

    if (-not (Test-Path -Path "$toolPath" -PathType Leaf))
    {
        return "Unable to locate $ToolName at $toolPath."
    }

    $toolVersion = Invoke-ExtensionScript "get-version.ps1" "$RepositoryRoot" "$ToolName" "$OverrideScriptsFolderPath" "$toolPath"

    if ("$toolVersion" -ne "$DeclaredVersion")
    {
        return "Version of $toolPath is $toolVersion, which does not match the declared version $DeclaredVersion."
    }

    Write-LogMessage "$RepositoryRoot" "$ToolName is available at $toolPath. Version is $toolVersion."
    return "$toolPath"
}

# Begin downloading the package, and extract the package.
Start-DownloadExtract

# Validate the download.
return Confirm-Toolpath
