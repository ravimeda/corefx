# Provides helper functions.

# Gets the path to default scripts folder, which is tools-local/windows under repository root.
function Get-DefaultScriptsFolder
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, Position=0)]
        [string]$RepositoryRoot
    )

    $repoRoot = Join-Path "$RepositoryRoot" "tools-local\windows"
    return "$repoRoot"
}

# Returns 64 if the operating system is 64 bit, otherwise 32.
function Get-OperatingSystemArchitecture
{
    if ([System.Environment]::Is64BitOperatingSystem)
    {
        return "64"
    }

    return "32"
}

# Gets the configuration corresponding to the specified tool from the .toolversions file.
function Read-ToolVersionsFile
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, Position=0)]
        [string]$RepositoryRoot,
        [parameter(Mandatory=$true, Position=1)]
        [string]$ToolName
    )

    $toolVersionsFilePath = Join-Path "$RepositoryRoot" ".toolversions"
    $toolVersions = Get-Content -Path $toolVersionsFilePath -Raw
    $regexPattern = "$ToolName=.*([`\n]|.*)+?`\"""
    $toolConfig = [regex]::Match($toolVersions, $regexPattern).Value
    return "$toolConfig"
}

# Gets the value(s) corresponding to the specified configuration name from the .toolversions file.
# Specifying IsMultiLine will return an array of values.
function Get-ToolConfigValue
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, Position=0)]
        [string]$RepositoryRoot,
        [parameter(Mandatory=$true, Position=1)]
        [string]$ToolName,
        [parameter(Mandatory=$true, Position=2)]
        [string]$ConfigName,
        [parameter(Position=3)]
        [switch]$IsMultiLine

    )

    $toolConfig = Read-ToolVersionsFile $RepositoryRoot $ToolName
    $regexPattern = "(?<=$ConfigName=')[^']*"
    $configValue = [regex]::Match($toolConfig, $regexPattern).Value

    if ([string]::IsNullOrWhiteSpace($configValue))
    {
        Write-Error "Unable to read the value corresponding to $ConfigName from the .toolversions file."
    }

    if (-not $IsMultiLine)
    {
        return "$configValue"
    }

    $configValue = $configValue.Split([Environment]::NewLine, [System.StringSplitOptions]::RemoveEmptyEntries)
    $multilineValues = @()
    $configValue | % { $multilineValues += $_.Trim() }
    return $multilineValues
}

# Gets the name of the download file corresponding to the specified tool name.
# Download file name is read from the .toolversions file.
function Get-DownloadFile
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, Position=0)]
        [string]$RepositoryRoot,
        [parameter(Mandatory=$true, Position=1)]
        [string]$ToolName
    )

    $configName = "DownloadFileWindows"
    $configName += Get-OperatingSystemArchitecture
    $downloadFile = Get-ToolConfigValue "$RepositoryRoot" "$ToolName" "$configName"
    return "$downloadFile"
}

# Gets the absolute path to the cache corresponding to the specified tool.
# Path is read from the .toolversions file. If the path is not specified in .toolversions file then, 
# returns the path to Tools/downloads folder under the repository root.
function Get-LocalToolFolder
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, Position=0)]
        [string]$RepositoryRoot,
        [parameter(Mandatory=$true, Position=1)]
        [string]$ToolName
    )

    $toolFolder = Get-ToolConfigValue "$RepositoryRoot" "$ToolName" "LocalToolFolderWindows" -ErrorAction SilentlyContinue

    if ([string]::IsNullOrWhiteSpace($toolFolder) -or -not (Test-Path "$toolFolder" -PathType Container))
    {
        $toolFolder = Join-Path "$RepositoryRoot" "Tools\downloads\$ToolName"
    }

    if (-not [System.IO.Path]::IsPathRooted($toolFolder))
    {
        $toolFolder = Join-Path "$RepositoryRoot" "$toolFolder"
    }

    return "$toolFolder"
}

# Normalizes the given search paths.
function Update-PathText
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true, Position=0)]
        [string[]]$SearchPaths
    )

    $fixedSearchPaths = @()

    foreach ($path in $searchPaths)
    {
        $path = $path.Replace("%programfiles(x86)%", "${env:ProgramFiles(x86)}")
        $path = $path.Replace("%programfiles%", "${env:ProgramFiles}")
        $path = $path.Replace("\\","\")
        $fixedSearchPaths += $path
    }

    return $fixedSearchPaths
}

# Gets the search path corresponding to the specified tool name.
# Search path is read from the .toolversions file.
function Get-LocalSearchPath
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, Position=0)]
        [string]$RepositoryRoot,
        [parameter(Mandatory=$true, Position=1)]
        [string]$ToolName
    )

    $configName = "LocalSearchPathWindows"
    $configName += Get-OperatingSystemArchitecture
    $searchPath = Get-ToolConfigValue "$RepositoryRoot" "$ToolName" "$configName"

    $toolFolder = Get-LocalToolFolder "$RepositoryRoot" "$ToolName"
    $searchPath = Join-Path "$toolFolder" "$searchPath"
    $searchPath = Update-PathText $searchPath
    return "$searchPath"
}

# Gets the error message to be displayed when the specified tool is not available for the build.
# Error message is read from the .toolversions file.
function Get-ToolNotFoundMessage
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, Position=0)]
        [string]$RepositoryRoot,
        [parameter(Mandatory=$true, Position=1)]
        [string]$ToolName
    )

    $ToolNotFoundMessage = Get-ToolConfigValue "$RepositoryRoot" "$ToolName" "ToolNotFoundMessage"

    # Expand $DeclaredVersion and $DownloadUrl in $ToolNotFoundMessage.
    $DeclaredVersion = Get-ToolConfigValue "$RepositoryRoot" "$ToolName" "DeclaredVersion"
    $DownloadUrl = Get-ToolConfigValue "$RepositoryRoot" "$ToolName" "DownloadUrl"
    $ToolNotFoundMessage = $ToolNotFoundMessage.Replace("\`$", "`$")
    $ToolNotFoundMessage = $ExecutionContext.InvokeCommand.ExpandString($ToolNotFoundMessage)

    return "$ToolNotFoundMessage"
}

# Write the given message(s) to probe log file.
function Write-LogMessage
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, Position=0)]
        [string]$RepositoryRoot,
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, Position=1)]
        [string]$Message
    )

    $probeLog = Join-Path $RepositoryRoot "probe-tool.log"
    $Message | Out-File -FilePath "$probeLog" -Append -Force
}

<#
.SYNOPSIS
    Invokes the override extension script if available, else invokes the base implementation.
.PARAMETER ScriptName
    Name of the extension script.
.PARAMETER RepositoryRoot
    Path to repository root.
.PARAMETER ToolName
    Name of the tool to search .
.PARAMETER OverrideScriptsFolderPath
    If a path is specified then, scripts from the specified folder will be invoked. 
    Otherwise, the default scripts located within the repository will be invoked.
.PARAMETER ExtraArgs
    Additional parameters that will be passed on to the invoked extension script.
.PARAMETER ToolPath
    Path to CMake executable or the folder containing the executable.
.EXAMPLE
    Invoke-ExtensionScript search-tool.ps1 "C:\Users\dotnet\Source\Repos\corefx" cmake "" ""
    Searches for CMake, not necessarily the declared version, using the default scripts located within the repository.
.EXAMPLE
    Invoke-ExtensionScript acquire-tool.ps1 "C:\Users\dotnet\Source\Repos\corefx" cmake ""
    Acquires the declared version of CMake, using the default scripts located within the repository.
.EXAMPLE
    Invoke-ExtensionScript search-tool.ps1 "C:\Users\dotnet\Source\Repos\corefx" cmake "D:\dotnet\MyCustomScripts" "strict"
    Searches for the declared version of CMake using the search scripts located under "D:\dotnet\MyCustomScripts".
.EXAMPLE
    Invoke-ExtensionScript get-version.ps1 "C:\Users\dotnet\Source\Repos\corefx" cmake "" "C:\Program Files (x86)\CMake\bin\cmake.exe"
    Gets the version number of CMake executable located at "C:\Program Files (x86)\CMake\bin\cmake.exe".
#>
function Invoke-ExtensionScript
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, Position=0)]
        [string]$ScriptName,
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, Position=1)]
        [string]$RepositoryRoot,
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, Position=2)]
        [string]$ToolName,
        [parameter(Position=3)]
        [string]$OverrideScriptsFolderPath,
        [parameter(ValueFromRemainingArguments=$true)]
        [string]$ExtraArgs
    )

    if (-not [string]::IsNullOrWhiteSpace($OverrideScriptsFolderPath) -and -not (Test-Path $OverrideScriptsFolderPath -PathType Container))
    {
        Write-Host "Path specified as override-scripts-folder-path does not exist or is not accessible. Path: $OverrideScriptsFolderPath"
        return
    }

    $defaultScriptsFolderPath = Get-DefaultScriptsFolder $RepositoryRoot
    $extensionFolders = $OverrideScriptsFolderPath,$defaultScriptsFolderPath

    foreach ($extFolder in $extensionFolders)
    {
        if (-not [string]::IsNullOrWhiteSpace($extFolder) -and (Test-Path $extFolder -PathType Container -ErrorAction SilentlyContinue))
        {
            $invokeScriptPath = Join-Path "$extFolder\$ToolName" "$ScriptName"

            if (Test-Path $invokeScriptPath -PathType Leaf)
            {
                # Tool overrides base implementation.
                break
            }

            $invokeScriptPath = Join-Path "$extFolder" "$ScriptName"

            if (Test-Path $invokeScriptPath -PathType Leaf)
            {
                # Base implementation.
                break
            }
        }
    }

    # Note that the first argument is the name of the extension script. Hence remove ScriptName, and pass rest of the arguments to the invocation.
    $PSBoundParameters.Remove("ScriptName") | Out-Null
    $remainingArgs = @()
    $PSBoundParameters.Values | % { $remainingArgs += "`"$_`"" }

    Write-LogMessage "$RepositoryRoot" "Invoking $invokeScriptPath with the following arguments $remainingArgs."
    $output = Invoke-Expression "$invokeScriptPath $remainingArgs"
    return "$output"
}
