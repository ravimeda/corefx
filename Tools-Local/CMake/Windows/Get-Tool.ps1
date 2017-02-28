<#
.SYNOPSIS
    Downloads the package corresponding to the declared version of the given tool, 
    and extracts the downloaded package to Tools/Downloads/ folder in the repository root.
.PARAMETER ToolName
    Name of the tool that needs to be downloaded.
.PARAMETER RepoRoot
    Repository root path. 
    If not specified then, will be determined as 3 levels up the current working folder.
.PARAMETER DeclaredVersion
    Declared version of the tool. 
    If not specified, declared version will be determined by invoking ./Get-DeclaredtoolVersion.ps1.
.PARAMETER DeclaredVersion
    URL of the tool package from where the package will be downloaded.
.EXAMPLE
    .\Get-tool.ps1 -ToolName "CMake"
    On successful completion, returns the folder path where the declared version of CMake executable is available. 
    For example, "C:\Users\dotnet\Source\Repos\corefx\Tools-Local\Downloads\CMake\cmake-3.7.2-win64-x64\bin\cmake.exe"
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$ToolName,
    [string]$RepoRoot,
    [string]$DeclaredVersion,
    [string]$DownloadUrl
)

# Get the repository root path
function GetRepoRoot
{
    if ([string]::IsNullOrWhiteSpace($RepoRoot))
    {
        $RepoRoot = Join-Path $PSScriptRoot "/../../.."
    }

    if (-not (Test-Path -Path $RepoRoot -PathType Container))
    {
        Write-Error "Unable to access repository root. RepoRoot: $RepoRoot"
        return
    }

    return [System.IO.Path]::GetFullPath($RepoRoot)
}

# Get the declared version of the tool.
function GetDeclaredVersion
{
    if ([string]::IsNullOrWhiteSpace($DeclaredVersion))
    {
        $DeclaredVersion = $(& $PSScriptRoot\Get-DeclaredtoolVersion.ps1 -ToolName $($prereqObject.ToolName) -RepoRoot "$($prereqObject.RepoRoot)")

        if ([string]::IsNullOrWhiteSpace($DeclaredVersion))
        {
            Write-Error "Declared version of $($prereqObject.ToolName) is empty."
            return
        }
    }

    return $DeclaredVersion
}

# Get the package name corresponding to the declared version.
function GetPackageName
{
    if ([string]::IsNullOrWhiteSpace($($prereqObject.PackageName)))
    {
        $PackageName = & $PSScriptRoot\Get-toolPackageName.ps1 -ToolName $($prereqObject.ToolName) -DeclaredVersion $($prereqObject.DeclaredVersion)

        if ([string]::IsNullOrWhiteSpace($PackageName))
        {
            Write-Error "Unable to determine the package name."
            return
        }
        else
        {
            return $PackageName
        }
    }

    return $($prereqObject.PackageName)
}

function GetPackageNameWithExtension
{
    if ([string]::IsNullOrWhiteSpace($($prereqObject.PackageNameWithExtension)))
    {
        if ([string]::IsNullOrWhiteSpace($($prereqObject.PackageName)))
        {
            $PackageName = & $PSScriptRoot\Get-toolPackageName.ps1 -ToolName $($prereqObject.ToolName) -DeclaredVersion $($prereqObject.DeclaredVersion)
        }
        else
        {
            $PackageName= $($prereqObject.PackageName)
        }

        return $PackageName + ".zip"
    }

    return $($prereqObject.PackageNameWithExtension)
}

# Get the URL from where the package can be downloaded.
function GetPackageUrl
{
    # TODO: 
    #   Do not download directly from internet. 
    #   Follow the practice described at https://www.1eswiki.com/wiki/Introducing_OSS_Component_Governance
    #   Likely we will host the tool at https://ossmsft.visualstudio.com/, and the below logic will change.

    if ([string]::IsNullOrWhiteSpace($($prereqObject.PackageUrl)))
    {
        # Example URL is https://cmake.org/files/v3.7/cmake-3.7.2-win64-x64.zip
        $MajorMinorCMakeVersion = $($prereqObject.DeclaredVersion).Split('.')[0..1] -join '.'

        if ([string]::IsNullOrWhiteSpace($($prereqObject.PackageNameWithExtension)))
        {
            $PackageNameWithExtension = GetPackageNameWithExtension
        }
        else
        {
            $PackageNameWithExtension = $($prereqObject.PackageNameWithExtension)
        }

        return "https://cmake.org/files/v$MajorMinorCMakeVersion/$PackageNameWithExtension"
    }

    return $($prereqObject.PackageUrl)
}

# Get the path to the tool executable.
# Path will be in Tools/Downloads folder under repository root.
function GetDownloadsFoldertoolPath
{
    if ([string]::IsNullOrWhiteSpace($($prereqObject.toolPath)))
    {
        $toolPath = $(& $PSScriptRoot\Get-RepotoolPath.ps1 -ToolName $($prereqObject.ToolName) -RepoRoot "$($prereqObject.RepoRoot)" -DeclaredVersion $($prereqObject.DeclaredVersion) -toolPackageName $($prereqObject.PackageName))

        if ([string]::IsNullOrWhiteSpace($toolPath))
        {
            Write-Error "Unable to determine the path to tool in downloads folder."
            return
        }

        return $toolPath
    }

    return $($prereqObject.toolPath)
}

# Determine the folder within the repository where the package will be downloaded, 
# extracted, and made available for the build process to consume.
# This folder will be in Tools/Downloads folder under repository root.
function GetDownloadsFolder
{
    if ([string]::IsNullOrWhiteSpace($($prereqObject.DownloadsFolder)))
    {
        if ([string]::IsNullOrWhiteSpace($($prereqObject.toolPath)))
        {
            $toolPath = GetDownloadsFoldertoolPath
        }
        else
        {
            $toolPath = $($prereqObject.toolPath)
        }

        if ([string]::IsNullOrWhiteSpace($($prereqObject.PackageName)))
        {
            $PackageName = GetDownloadsFoldertoolPath
        }
        else
        {
            $PackageName = $($prereqObject.PackageName)
        }

        return $toolPath.Substring(0, $toolPath.LastIndexOf("\$PackageName"))
    }

    return $($prereqObject.DownloadsFolder)
}

# Get the path to the folder where the compressed package will be downloaded to.
function GetDownloadsFolderCompressedPackagePath
{
    if ([string]::IsNullOrWhiteSpace($($prereqObject.PackagePath)))
    {
        if ([string]::IsNullOrWhiteSpace($($prereqObject.DownloadsFolder)))
        {
            $DownloadsFolder = GetDownloadsFolder
        }
        else
        {
            $DownloadsFolder = $($prereqObject.DownloadsFolder)
        }

        if ([string]::IsNullOrWhiteSpace($($prereqObject.PackageNameWithExtension)))
        {
            $PackageNameWithExtension = GetPackageNameWithExtension
        }
        else
        {
            $PackageNameWithExtension = $($prereqObject.PackageNameWithExtension)
        }

        return (Join-Path $DownloadsFolder $PackageNameWithExtension)
    }

    return $($prereqObject.PackagePath)
}

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

function ValidateAcquiredPrereq
{
    if (& $PSScriptRoot\Test-toolVersion.ps1 -toolPath $($prereqObject.toolPath) -ToolName $($prereqObject.ToolName) -RepoRoot "$($prereqObject.RepoRoot)")
    {
        return $true
    }

    return $false
}

function InitializePrereqObject
{
    $prereqObject = New-Object -TypeName PSObject
    Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name ToolName -Value $ToolName
    Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name RepoRoot -Value $(GetRepoRoot)
    Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name DeclaredVersion -Value $(GetDeclaredVersion)

    switch ($ToolName)
    {
        "CMake"
        {
            Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name PackageName -Value $(GetPackageName)
            Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name PackageNameWithExtension -Value $(GetPackageNameWithExtension)
            Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name PackageUrl -Value $(GetPackageUrl)
            Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name DownloadsFolder -Value $(GetDownloadsFolder)
            Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name toolPath -Value $(GetDownloadsFoldertoolPath)
            Add-Member -InputObject $prereqObject -MemberType NoteProperty -Name PackagePath -Value $(GetDownloadsFolderCompressedPackagePath)
        }
    }

    return $prereqObject
}

function GetPrereq
{
    SetupDownloadFolders
    DownloadPackage
    ExtractPackage
}

try
{
    # Initialize.
    switch ($ToolName)
    {
        "CMake"
        {
            $prereqObject = InitializePrereqObject -ToolName $ToolName
        }
        default
        {
            Write-Error "Unable to get tool named $ToolName."
        }
    }

    # Acquire.
    GetPrereq

    # Validate.
    if (ValidateAcquiredPrereq)
    {
        Write-Host "$($prereqObject.ToolName) is available at $($prereqObject.toolPath)"
        return $prereqObject
    }

    Write-Error "Version of $($prereqObject.ToolName) downloaded does not match the declared version.
                    Downloaded $($prereqObject.ToolName) is at $($prereqObject.toolPath)
                    Declared version is $($prereqObject.DeclaredVersion)"
}
catch
{
    Write-Error $_.Exception.Message
}
