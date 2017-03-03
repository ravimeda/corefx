<#
.SYNOPSIS
    Downloads the package corresponding to the declared version of the specified tool name, and 
    extracts the downloaded package to Tools/downloads folder in the repository root.
.PARAMETER ToolName
    Name of the tool.
.PARAMETER DeclaredVersion
    Declared version of the specified tool. 
    If not specified then, will determine using GetDeclaredVersion helper function.
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
    [parameter(Mandatory=$true, Position=1)]
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
    #Write-Host "Attempting to download $($prereqObject.ToolName) from $($prereqObject.PackageUrl) to $($prereqObject.DownloadsFolder)"
    $downloadResult = Invoke-WebRequest -Uri $($prereqObject.PackageUrl) -OutFile $($prereqObject.PackagePath) -DisableKeepAlive -UseBasicParsing -PassThru
    $downloadResult | Out-File (Join-Path $($prereqObject.DownloadsFolder) "download.log")
}

function ExtractPackage
{
    # Expand the package.
    #Write-Host "Download successful. Attempting to expand the downloaded package."
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

function GetCMake
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
        #Write-Host "$($prereqObject.ToolName) is available at $($prereqObject.ToolPath)"
        return $prereqObject
    }
}

$prereqObject = ""
. $PSScriptRoot\..\..\helper\windows\tool-helper.ps1

try
{
    switch ($ToolName)
    {
        "CMake"
        {
            $prereqObject = GetCMake
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

return $prereqObject
