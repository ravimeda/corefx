<#
.SYNOPSIS
    Downloads the package corresponding to the declared version of the specified tool name, and 
    extracts the downloaded package to Tools/downloads folder in the repository root.
.PARAMETER ToolName
    Name of the tool.
.PARAMETER DeclaredVersion
    Declared version of the specified tool.
.EXAMPLE
    .\get-tool.ps1 -ToolName "CMake" -DeclaredVersion "3.7.2"
    On successful completion, returns the folder path where the declared version of CMake executable is available. 
    For example, "C:\Users\dotnet\Source\Repos\corefx\Tools\downloads\CMake\cmake-3.7.2-win64-x64\bin\cmake.exe"
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$ToolName,
    [ValidateNotNullOrEmpty()]
    [parameter(Mandatory=$true, Position=1)]
    [string]$DeclaredVersion
)

# Setup folders to save the download package and extract and store logs.
function SetupDownloadFolders
{
    $uncompressedFolder = Join-Path $($downloadObject.DownloadsFolder) $($downloadObject.PackageName)

    if (-not (Test-Path -Path $($downloadObject.DownloadsFolder)))
    {
        New-Item -Path $($downloadObject.DownloadsFolder) -ItemType directory | Out-Null
    }
    else
    {
        if (Test-Path -Path $($downloadObject.PackagePath) -PathType Leaf )
        {
            Remove-Item -Path $($downloadObject.PackagePath) -Force -ErrorAction Continue
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
    #Write-Host "Attempting to download $($downloadObject.ToolName) from $($downloadObject.PackageUrl) to $($downloadObject.DownloadsFolder)"
    $downloadResult = Invoke-WebRequest -Uri $($downloadObject.PackageUrl) -OutFile $($downloadObject.PackagePath) -DisableKeepAlive -UseBasicParsing -PassThru
    $downloadResult | Out-File (Join-Path $($downloadObject.DownloadsFolder) "download.log")
}

function ExtractPackage
{
    # Expand the package.
    #Write-Host "Download successful. Attempting to expand the downloaded package."
    Expand-Archive -Path $($downloadObject.PackagePath) -DestinationPath $($downloadObject.DownloadsFolder) -Force | Out-File (Join-Path $($downloadObject.DownloadsFolder) "expand.log")

    # Remove the downloaded compressed binary file.
    Remove-Item $($downloadObject.PackagePath) -Force -ErrorAction Continue
}

# Get the URL from where the package can be downloaded.
function GetCMakePackageUrl
{
    # Example URL is https://cmake.org/files/v3.7/cmake-3.7.2-win64-x64.zip
    $MajorMinorCMakeVersion = $($downloadObject.DeclaredVersion).Split('.')[0..1] -join '.'
    return "https://cmake.org/files/v$MajorMinorCMakeVersion/$($downloadObject.PackageNameWithExtension)"
}

function GetCMakePath
{
    # Initialize download object.
    $downloadObject = New-Object -TypeName PSObject
    Add-Member -InputObject $downloadObject -MemberType NoteProperty -Name ToolName -Value $ToolName
    Add-Member -InputObject $downloadObject -MemberType NoteProperty -Name DeclaredVersion -Value $DeclaredVersion
    Add-Member -InputObject $downloadObject -MemberType NoteProperty -Name RepoRoot -Value $(GetRepoRoot)
    Add-Member -InputObject $downloadObject -MemberType NoteProperty -Name DownloadsFolder -Value $(GetRepoDownloadsFolderPath -ToolName $ToolName)
    Add-Member -InputObject $downloadObject -MemberType NoteProperty -Name ToolPath -Value $(GetCMakeRepoToolPath)
    Add-Member -InputObject $downloadObject -MemberType NoteProperty -Name PackageName -Value $(GetCMakePackageName)
    Add-Member -InputObject $downloadObject -MemberType NoteProperty -Name PackageNameWithExtension -Value $($downloadObject.PackageName + ".zip")
    Add-Member -InputObject $downloadObject -MemberType NoteProperty -Name PackagePath -Value $(Join-Path $($downloadObject.DownloadsFolder) $($downloadObject.PackageNameWithExtension))
    Add-Member -InputObject $downloadObject -MemberType NoteProperty -Name PackageUrl -Value $(GetCMakePackageUrl)

     # Download the package, and extract to Tools\downloads.
    SetupDownloadFolders
    DownloadPackage
    ExtractPackage

    # Ensure that the version of CMake executable downloaded is the declared version.
    if (IsCMakeDeclaredVersion -ToolPath $($downloadObject.ToolPath))
    {
        #Write-Host "$($downloadObject.ToolName) is available at $($downloadObject.ToolPath)"
        return [System.IO.Path]::GetFullPath($downloadObject.ToolPath)
    }

    return ""
}

# Download MyCustomTool from internet.
function GetMyCustomToolPath
{
    # Initialize MyCustomTool download object.
    # Download and extract package.
    # Validate download, and return the path.
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
            $toolPath = GetCMakePath
        }
        "MyCustomTool"
        {
            $toolPath = GetMyCustomToolPath
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

return $toolPath
