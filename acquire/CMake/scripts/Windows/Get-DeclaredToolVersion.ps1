<#
.SYNOPSIS
    Gets the declared version of a tool by parsing the .toolversions located in the repository root.
    Returns an empty string if unable to determine the declared version.
.PARAMETER toolName
    Name of the tool for which declared version needs to be obtained.
.PARAMETER RepoRoot
    Repository root path.
.EXAMPLE
    .\Get-DeclaredtoolVersion.ps1 -toolName "CMake" -RepoRoot "C:\Users\dotnet\Source\Repos\corefx"
    Gets the declared version, which is 3.7.2, of CMake for the repository whose root is "C:\Users\dotnet\Source\Repos\corefx".
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$toolName,
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=1)]
    [string]$RepoRoot
)

if (-not (Test-Path -Path $RepoRoot -PathType Container))
{
    Write-Error "Unable to access repository root. RepoRoot: $RepoRoot"
    return ""
}

$declaredVersion = ""

try
{
    $toolVersionsFilePath = Join-Path "$RepoRoot" ".toolversions"
    $toolVersionsContent = Get-Content -Path $toolVersionsFilePath

    foreach ($line in $toolVersionsContent)
    {
        $name, $version = $line.Split('=', [StringSplitOptions]::RemoveEmptyEntries)

        if ($name -ieq "$toolName")
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

return $declaredVersion
