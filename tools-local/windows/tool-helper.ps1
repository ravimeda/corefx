# Provides helper functions.

# Gets the path to default scripts folder, which is tools-local/windows under repository root.
function get_default_scripts_folder
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
function get_os_architecture
{
    if ([System.Environment]::Is64BitOperatingSystem)
    {
        return "64"
    }

    return "32"
}

# Gets the configuration corresponding to the specified tool from the .toolversions file.
function eval_tool
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

# Gets the value corresponding to the specified configuration from the .toolversions file.
function get_tool_config_value
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, Position=0)]
        [string]$RepositoryRoot,
        [parameter(Mandatory=$true, Position=1)]
        [string]$ToolName,
        [parameter(Mandatory=$true, Position=2)]
        [string]$ConfigName
    )

    $toolConfig = eval_tool $RepositoryRoot $ToolName
    $regexPattern = "(?<=$ConfigName=')[^']*"
    $configValue = [regex]::Match($toolConfig, $regexPattern).Value

    if ([string]::IsNullOrWhiteSpace($configValue))
    {
        Write-Error "Unable to read the value corresponding to $ConfigName from the .toolversions file."
    }

    return "$configValue"
}

# Gets configuration values corresponding to the specified configuration from the .toolversions file.
# Returns an array containing values corresponding to the configuration.
function get_tool_config_multiline_values
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, Position=0)]
        [string]$RepositoryRoot,
        [parameter(Mandatory=$true, Position=1)]
        [string]$ToolName,
        [parameter(Mandatory=$true, Position=2)]
        [string]$ConfigName
    )

    $configValue = get_tool_config_value "$RepositoryRoot" "$ToolName" "$ConfigName"
    $configValue = $configValue.Split([Environment]::NewLine, [System.StringSplitOptions]::RemoveEmptyEntries)
    $multilineValues = @()
    $configValue | % { $multilineValues += $_.Trim() }
    return $multilineValues
}

# Gets the name of the download file corresponding to the specified tool name.
# Download file name is read from the .toolversions file.
function get_download_file
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
    $configName += get_os_architecture
    $downloadFile = get_tool_config_value "$RepositoryRoot" "$ToolName" "$configName"
    return "$downloadFile"
}

# Gets the absolute path to the cache corresponding to the specified tool.
# Path is read from the .toolversions file. If the path is not specified in .toolversions file then, 
# returns the path to Tools/downloads folder under the repository root.
function get_local_tool_folder
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, Position=0)]
        [string]$RepositoryRoot,
        [parameter(Mandatory=$true, Position=1)]
        [string]$ToolName
    )

    $toolFolder = get_tool_config_value "$RepositoryRoot" "$ToolName" "LocalToolFolderWindows" -ErrorAction SilentlyContinue

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
function normalize_paths
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
function get_local_search_path
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
    $configName += get_os_architecture
    $searchPath = get_tool_config_value "$RepositoryRoot" "$ToolName" "$configName"

    $toolFolder = get_local_tool_folder "$RepositoryRoot" "$ToolName"
    $searchPath = Join-Path "$toolFolder" "$searchPath"
    $searchPath = normalize_paths $searchPath
    return "$searchPath"
}

# Gets the error message to be displayed when the specified tool is not available for the build.
# Error message is read from the .toolversions file.
function tool_not_found_message
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, Position=0)]
        [string]$RepositoryRoot,
        [parameter(Mandatory=$true, Position=1)]
        [string]$ToolName
    )

    $ToolNotFoundMessage = get_tool_config_value "$RepositoryRoot" "$ToolName" "ToolNotFoundMessage"

    # Expand $DeclaredVersion and $DownloadUrl in $ToolNotFoundMessage.
    $DeclaredVersion = get_tool_config_value "$RepositoryRoot" "$ToolName" "DeclaredVersion"
    $DownloadUrl = get_tool_config_value "$RepositoryRoot" "$ToolName" "DownloadUrl"
    $ToolNotFoundMessage = $ToolNotFoundMessage.Replace("\`$", "`$")
    $ToolNotFoundMessage = $ExecutionContext.InvokeCommand.ExpandString($ToolNotFoundMessage)

    return "$ToolNotFoundMessage"
}

# Write the given message(s) to probe log file.
function log_message
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
    If a path is specified then, scripts from the specified folder will be invoked. Otherwise, the default scripts located within the repository will be invoked.
.PARAMETER StrictToolVersionMatch
    If equals to "strict" then, search will ensure that the version of the tool searched is the declared version. Otherwise, search will attempt to find a version of the tool, which may not be the declared version.
.PARAMETER ToolPath
    Path to CMake executable or the folder containing the executable.
.EXAMPLE
    invoke_extension search-tool.ps1 "C:\Users\dotnet\Source\Repos\corefx" cmake "" ""
    Searches for CMake, not necessarily the declared version, using the default scripts located within the repository.
.EXAMPLE
    invoke_extension acquire-tool.ps1 "C:\Users\dotnet\Source\Repos\corefx" cmake ""
    Acquires the declared version of CMake, using the default scripts located within the repository.
.EXAMPLE
    invoke_extension search-tool.ps1 "C:\Users\dotnet\Source\Repos\corefx" cmake "D:\dotnet\MyCustomScripts" "strict"
    Searches for the declared version of CMake using the search scripts located under "D:\dotnet\MyCustomScripts".
.EXAMPLE
    invoke_extension get-version.ps1 "C:\Users\dotnet\Source\Repos\corefx" cmake "" "C:\Program Files (x86)\CMake\bin\cmake.exe"
    Gets the version number of CMake executable located at "C:\Program Files (x86)\CMake\bin\cmake.exe".
#>
function invoke_extension
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

    $defaultScriptsFolderPath = get_default_scripts_folder $RepositoryRoot
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
    if ($PSBoundParameters.Remove("ScriptName"))
    {
        $remainingArgs = @()
        $PSBoundParameters.Values | % { $remainingArgs += "`"$_`"" }

        log_message "$RepositoryRoot" "Invoking $invokeScriptPath with the following arguments $remainingArgs."
        $output = Invoke-Expression "$invokeScriptPath $remainingArgs"
        return "$output"
    }

    # TODO: Display error?
}

#$RepositoryRoot = "D:\BackupRepos\ravimeda"
#$ToolName = "cmake"
#$OverrideScriptsFolderPath = ""
#$StrictToolVersionMatch = "strict"
#invoke_extension "search-tool.ps1" "$RepositoryRoot" "$ToolName" "$OverrideScriptsFolderPath" "$StrictToolVersionMatch"
#get_local_search_path "D:\BackupRepos\ravimeda" "cmake"
#get_tool_config_value "D:\BackupRepos\ravimeda" "cmake" "DeclaredVersion"
#get_tool_config_value "D:\BackupRepos\ravimeda" "cmake" "SearchPathsWindows"
#tool_not_found_message "D:\BackupRepos\ravimeda" "cmake"
