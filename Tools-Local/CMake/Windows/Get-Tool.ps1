<#
.SYNOPSIS
    Downloads the package corresponding to the declared version of the specified tool name, and 
    extracts the downloaded package to Tools-Local/Downloads/ folder in the repository root.
.PARAMETER ToolName
    Name of the tool.
    If not specified then, default is "CMake".
.PARAMETER RepoRoot
    Repository root path. 
    If not specified then, will be determined as 3 levels up the current working folder.
.PARAMETER DeclaredVersion
    Declared version of the tool. 
    If not specified, declared version will be determined by invoking GetDeclaredtoolVersion helper function.
.EXAMPLE
    .\Get-Tool.ps1
    On successful completion, returns the folder path where the declared version of CMake executable is available. 
    For example, "C:\Users\dotnet\Source\Repos\corefx\Tools-Local\Downloads\CMake\cmake-3.7.2-win64-x64\bin\cmake.exe"
#>

[CmdletBinding()]
param(
    [string]$ToolName="CMake",
    [string]$RepoRoot,
    [string]$DeclaredVersion
)

# Setup folders to save the download package and extract and store logs.
function SetupDownloadFolders
{
    $uncompressedFolder = Join-Path $($prereqObject.DownloadsFolder) $($prereqObject.PackageName)

    if (-not (Test-Path -Path $($prereqObject.DownloadsFolder)))
    {
        New-Item -Path $($prereqObject.DownloadsFolder) -ItemType directory | Out-Null
    }
    else
    {
        if (Test-Path -Path $($prereqObject.PackagePath) -PathType Leaf )
        {
            Remove-Item -Path $($prereqObject.PackagePath) -Force -ErrorAction Continue
        }

        if (Test-Path -Path $uncompressedFolder)
        {
            Remove-Item -Path $uncompressedFolder -Recurse -Force
        }
    }
}

function DownloadPackage
{
    # Download the package.
    Write-Host "Attempting to download $($prereqObject.ToolName) from $($prereqObject.PackageUrl) to $($prereqObject.DownloadsFolder)"
    $downloadResult = Invoke-WebRequest -Uri $($prereqObject.PackageUrl) -OutFile $($prereqObject.PackagePath) -DisableKeepAlive -UseBasicParsing -PassThru
    $downloadResult | Out-File (Join-Path $($prereqObject.DownloadsFolder) "download.log")
}

function ExtractPackage
{
    # Expand the package.
    Write-Host "Download successful. Attempting to expand the downloaded package."
    Expand-Archive -Path $($prereqObject.PackagePath) -DestinationPath $($prereqObject.DownloadsFolder) -Force | Out-File (Join-Path $($prereqObject.DownloadsFolder) "expand.log")

    # Remove the downloaded compressed binary file.
    Remove-Item $($prereqObject.PackagePath) -Force -ErrorAction Continue
}

# Get the URL from where the package can be downloaded.
function GetPackageUrl
{
    # Example URL is https://cmake.org/files/v3.7/cmake-3.7.2-win64-x64.zip
    $MajorMinorCMakeVersion = $($prereqObject.DeclaredVersion).Split('.')[0..1] -join '.'
    return "https://cmake.org/files/v$MajorMinorCMakeVersion/$($prereqObject.PackageNameWithExtension)"
}

function InitializePrereqObject
{
    $prereqObject = New-Object -TypeName PSObject
    Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name ToolName -Value $ToolName
    Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name RepoRoot -Value $(GetRepoRoot)
    Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name DeclaredVersion -Value $(GetDeclaredVersion -RepoRoot "$prereqObject.RepoRoot")
    Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name DownloadsFolder -Value $(GetRepoDownloadsFolderPath -RepoRoot "$prereqObject.RepoRoot")
    Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name ToolPath -Value $(GetRepoToolPath -RepoRoot $prereqObject.RepoRoot -DeclaredVersion $prereqObject.DeclaredVersion)
    Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name PackageName -Value $(GetPackageName -DeclaredVersion $prereqObject.DeclaredVersion)
    Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name PackageNameWithExtension -Value $($prereqObject.PackageName + ".zip")
    Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name PackagePath -Value $(Join-Path $($prereqObject.DownloadsFolder) $($prereqObject.PackageNameWithExtension))
    Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name PackageUrl -Value $(GetPackageUrl)
    return $prereqObject
}

# Dot source helper file.
. .\CMake-Helper.ps1

try
{
    # Initialize.
    $prereqObject = InitializePrereqObject

    # Acquire.
    SetupDownloadFolders
    DownloadPackage
    ExtractPackage

    # Validate.
    if (TestVersion -ToolPath $($prereqObject.ToolPath) -RepoRoot "$($prereqObject.RepoRoot)" -DeclaredVersion $($prereqObject.DeclaredVersion))
    {
        Write-Host "$($prereqObject.ToolName) is available at $($prereqObject.ToolPath)"
        return $prereqObject
    }

    Write-Error "Version of $($prereqObject.ToolName) downloaded does not match the declared version.
                    Downloaded $($prereqObject.ToolName) is at $($prereqObject.ToolPath)
                    Declared version is $($prereqObject.DeclaredVersion)"

}
catch
{
    Write-Error $_.Exception.Message
}
