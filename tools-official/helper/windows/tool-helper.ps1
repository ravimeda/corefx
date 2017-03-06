<#
.SYNOPSIS
    Provides helper functions.
#>

# Gets the repository root path.
function GetRepoRoot
{
    try
    {
        $RepoRoot = Join-Path $((Get-Location).Path) "..\..\.."

        if ([string]::IsNullOrWhiteSpace($RepoRoot) -or -not (Test-Path -Path $RepoRoot -PathType Container))
        {
            Write-Error "Unable to locate or access repository root. RepoRoot: $RepoRoot"
        }

        return [System.IO.Path]::GetFullPath($RepoRoot)
    }
    catch
    {
        Write-Error $_.Exception.Message
    }

    return $RepoRoot
}

# Gets the declared version of the specified tool.
function GetDeclaredVersion
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()] 
        [parameter(Mandatory=$true, Position=0)]
        [string]$ToolName
    )

    $RepoRoot = GetRepoRoot
    $declaredVersion = ""

    try
    {
        $toolVersionsFilePath = Join-Path "$RepoRoot" ".toolversions"
        $toolVersionsContent = Get-Content -Path $toolVersionsFilePath

        foreach ($line in $toolVersionsContent)
        {
            $name, $version = $line.Split('=', [StringSplitOptions]::RemoveEmptyEntries)

            if ($name -ieq "$ToolName")
            {
                $declaredVersion = $version
                break
            }
        }
    }
    catch
    {
        Write-Error $_.Exception.Message
    }

    if ([string]::IsNullOrWhiteSpace($declaredVersion))
    {
        Write-Error "Unable to read the declared version of $ToolName from .toolversions file."
    }

    return $declaredVersion
}

# Gets the path within the repository where the downloaded copy of the specified tool will be saved.
function GetRepoDownloadsFolderPath
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()] 
        [parameter(Mandatory=$true, Position=0)]
        [string]$ToolName
    )

    $RepoRoot = GetRepoRoot
    $dowloadsPath = ""

    try 
    {
        $dowloadsPath = [System.IO.Path]::GetFullPath($(Join-Path "$RepoRoot" "Tools\downloads\$ToolName"))
    }
    catch
    {
        Write-Error $_.Exception.Message
    }

    if([string]::IsNullOrWhiteSpace($dowloadsPath))
    {
        Write-Error "Unable to determine the downloads folder path."
    }

    return $dowloadsPath
}

# Gets the name of CMake package corresponding to the declared version.
function GetCMakePackageName
{
    $declaredVersion = GetDeclaredVersion -ToolName "CMake"
    $packageName = ""

    try
    {
        $packageName = "cmake-$($declaredVersion)-"

        if ([Environment]::Is64BitOperatingSystem)
        {
            $packageName += "win64-x64"
        }
        else
        {
            $packageName += "win32-x86"
        }
    }
    catch
    {
        Write-Error $_.Exception.Message
    }

    if([string]::IsNullOrWhiteSpace($packageName))
    {
        Write-Error "Unable to determine the package name corresponding to CMake version $declaredVersion"
    }

    return $packageName
}

# Gets the path within the repository where downloaded copy of CMake executable will be available.
function GetCMakeRepoToolPath
{
    $repoRoot = GetRepoRoot
    $packageName = GetCMakePackageName
    $toolPath = ""

    try 
    {
        $toolPath = [System.IO.Path]::GetFullPath($(Join-Path "$repoRoot" "Tools\downloads\CMake\$packageName\bin\cmake.exe"))
    }
    catch
    {
        Write-Error $_.Exception.Message
    }

    if([string]::IsNullOrWhiteSpace($toolPath))
    {
        Write-Error "Unable to determine the path to CMake executable in the downloads folder."
    }

    return $toolPath
}

# Compares the version of CMake executable at the specified path with the declared version.
# True if version matches. False, otherwise.
function IsCMakeDeclaredVersion
{
    [CmdletBinding()]
    param(
        [string]$ToolPath
    )

    if ([string]::IsNullOrWhiteSpace($ToolPath) -or -not (Test-Path -Path $ToolPath -PathType Leaf -ErrorAction SilentlyContinue))
    {
        return $false
    }

    $declaredVersion = GetDeclaredVersion -ToolName "CMake"

    try
    {
        $versionText = & $ToolPath "-version"

        if (-not [string]::IsNullOrWhiteSpace($versionText) -and $versionText -imatch "cmake version $declaredVersion")
        {
            return $true
        }
    }
    catch
    {
        Write-Error $_.Exception.Message
    }

    return $false
}

# Gets the name of MyCustomTool package corresponding to the declared version.
function GetMyCustomToolPackageName
{

}

# Gets the path within the repository where downloaded copy of MyCustomTool executable will be available.
function GetMyCustomToolRepoToolPath
{

}

# Compares the version of MyCustomTool executable at the specified path with the declared version.
# True if version matches. False, otherwise.
function IsMyCustomToolDeclaredVersion
{

}
