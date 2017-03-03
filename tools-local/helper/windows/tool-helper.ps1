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

# Gets the declared version of CMake.
function GetDeclaredVersion
{
    param(
        [string]$RepoRoot,
        [string]$ToolName="CMake"
    )

    if ([string]::IsNullOrWhiteSpace($RepoRoot) -or -not (Test-Path -Path $RepoRoot -PathType Container))
    {
        $RepoRoot = GetRepoRoot
    }

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

# Gets the CMake package name corresponding to the declared version and the operating system.
function GetPackageName
{
    param(
        [string]$DeclaredVersion
    )

    if ([string]::IsNullOrWhiteSpace($DeclaredVersion))
    {
        $DeclaredVersion = GetDeclaredVersion
    }

    $packageName = ""

    try
    {
        $packageName = "cmake-$($DeclaredVersion)-"

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
        Write-Error "Unable to determine the package name corresponding to CMake version $DeclaredVersion"
    }

    return $packageName
}

# Gets the path to Tools\downloads folder under repository root.
function GetRepoDownloadsFolderPath
{
    param(
        [string]$RepoRoot
    )

    if ([string]::IsNullOrWhiteSpace($RepoRoot) -or -not (Test-Path -Path $RepoRoot -PathType Container))
    {
        $RepoRoot = GetRepoRoot
    }

    $dowloadsPath = ""

    try 
    {
        $dowloadsPath = [System.IO.Path]::GetFullPath($(Join-Path "$RepoRoot" "Tools\downloads\CMake"))
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

# Gets the path to CMake executable in Tools\downloads folder under repository root.
function GetRepoToolPath
{
    param(
        [string]$RepoRoot,
        [string]$DeclaredVersion,
        [string]$PackageName
    )

    if ([string]::IsNullOrWhiteSpace($RepoRoot) -or -not (Test-Path -Path $RepoRoot -PathType Container))
    {
        $RepoRoot = GetRepoRoot
    }

    if ([string]::IsNullOrWhiteSpace($DeclaredVersion))
    {
        $DeclaredVersion = GetDeclaredVersion
    }

    if ([string]::IsNullOrWhiteSpace($PackageName))
    {
        $PackageName = GetPackageName -DeclaredVersion $DeclaredVersion
    }

    $toolPath = ""

    try 
    {
        $toolPath = [System.IO.Path]::GetFullPath($(Join-Path "$RepoRoot" "Tools\downloads\CMake\$PackageName\bin\cmake.exe"))
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
function TestVersion
{
    param(
        [ValidateNotNullOrEmpty()] 
        [parameter(Mandatory=$true)]
        [string]$ToolPath,
        [string]$RepoRoot,
        [string]$DeclaredVersion
    )

    if (-not (Test-Path -Path $ToolPath -PathType Leaf))
    {
        Write-Error "Unable to access the executable at the given path. Path: $ToolPath"
    }

    if ([string]::IsNullOrWhiteSpace($RepoRoot) -or -not (Test-Path -Path $RepoRoot -PathType Container))
    {
        $RepoRoot = GetRepoRoot
    }

    if ([string]::IsNullOrWhiteSpace($DeclaredVersion))
    {
        $DeclaredVersion = GetDeclaredVersion
    }

    try
    {
        $versionText = & $ToolPath "-version"

        if (-not [string]::IsNullOrWhiteSpace($versionText) -and $versionText -imatch "cmake version $DeclaredVersion")
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
