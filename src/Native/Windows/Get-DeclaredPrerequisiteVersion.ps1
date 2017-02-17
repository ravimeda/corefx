<#
.SYNOPSIS
    Gets the declared version of a prerequisite by parsing the .prerequisiteversions located in the repository root.
    Returns an empty string if unable to determine the declared version.
.PARAMETER PrerequisiteName
    Name of the prerequisite for which declared version needs to be obtained.
.PARAMETER RepoRoot
    Repository root path.
.EXAMPLE
    .\Get-DeclaredPrerequisiteVersion.ps1 -PrerequisiteName "CMake" -RepoRoot "C:\Users\dotnet\Source\Repos\corefx"
    Gets the declared version, which is 3.7.2, of CMake for the repository whose root is "C:\Users\dotnet\Source\Repos\corefx".
#>

[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()] 
    [parameter(Mandatory=$true, Position=0)]
    [string]$PrerequisiteName,
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
    $prerequisiteVersionsFilePath = Join-Path "$RepoRoot" ".prerequisiteversions"
    $prerequisiteVersionsContent = Get-Content -Path $prerequisiteVersionsFilePath

    foreach ($line in $prerequisiteVersionsContent)
    {
        $name, $version = $line.Split('=', [StringSplitOptions]::RemoveEmptyEntries)

        if ($name -ieq "$PrerequisiteName")
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
