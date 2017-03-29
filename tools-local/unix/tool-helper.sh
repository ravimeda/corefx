#!/usr/bin/env bash

# Provides helper functions.

# Gets the repository root path.
get_repo_root()
{
    scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
    repoRoot="$(cd "$scriptPath/../.."; pwd -P)"
    echo "$repoRoot"
}

# Gets name of the operating system.
# Exit 1 if unable to get operating system name.
get_os_name()
{
    osName="$(uname -s)"

    if [ $? -ne 0 ] || [ -z "$osName" ]; then
        echo "Unable to determine the name of the operating system."
        exit 1
    fi

    if $(echo "$osName" | grep -iqF "Darwin"); then
        osName="OSX"
    else
        osName="Linux"
    fi

    echo "$osName"
}

# Gets the path to Tools/downloads folder under repository root.
# Exit 1 if unable to determine the path.
get_repository_tools_downloads_folder()
{
    repoRoot="$(get_repo_root)"
    toolsPath="$repoRoot/Tools/downloads"
    
    if [ -z "$toolsPath" ]; then
        echo "Unable to determine repository tools path."
        exit 1
    fi

    echo "$toolsPath"
}

# Eval .toolversions file.
eval_tool()
{
    if [ -z "$1" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    toolName="$1"
    repoRoot="$(get_repo_root)"
    . "$repoRoot/.toolversions"

    # Evaluate toolName. This assigns the metadata of toolName to tools.
    eval "tools=\$$toolName"

    # Evaluate tools. Each argument here is tool specific data such as DeclaredVersion of toolName.
    eval "$tools"
}

# Gets the declared version of the specified tool name.
# Declared version is read from the .toolversions file.
# Exit 1 if unable to read declared version of the tool from .toolversions file.
get_declared_version()
{
    if [ -z "$1" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    toolName="$1"
    eval_tool "$toolName"

    if [ -z "$DeclaredVersion" ]; then
        echo "Unable to read the declared version for $toolName"
        exit 1
    fi

    echo "$DeclaredVersion"
}

# Get the download URL for the specified tool name.
# Download URL is read from the .toolversions file.
# Exit 1 if unable to read the download URL of the tool from .toolversions file.
get_download_url()
{
    if [ -z "$1" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    toolName="$1"
    eval_tool "$toolName"

    if [ -z "$DownloadUrl" ]; then
        echo "Unable to read download URL for $toolName"
        exit 1
    fi

    echo "$DownloadUrl"
}

# Gets the name of the download package corresponding to the specified tool name.
# Download package name is read from the .toolversions file.
# Exit 1 if unable to read the name of the download package from .toolversions file.
get_download_package_name()
{
    if [ -z "$1" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    toolName="$1"
    eval_tool "$toolName"
    osName="$(get_os_name)"

    if [ "$osName" == "OSX" ]; then
        packageName="$DownloadPackageNameOSX"
    else
        packageName="$DownloadPackageNameLinux"
    fi

    if [ -z "$packageName" ]; then
        echo "Unable to read package name for $toolName"
        exit 1
    fi

    echo "$packageName"
}

# Gets the search path corresponding to the specified tool name.
# Search path is read from the .toolversions file.
# Exit 1 if unable to read the path from .toolversions file.
get_repository_tool_search_path()
{
    if [ -z "$1" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    toolName="$1"
    eval_tool "$toolName"
    osName="$(get_os_name)"

    if [ "$osName" == "OSX" ]; then
        toolsSearchPath="$repoRoot/$SearchPathOSXTools"
    else
        toolsSearchPath="$repoRoot/$SearchPathLinuxTools"
    fi

    if [ -z "$toolsSearchPath" ]; then
        echo "Unable to read tool search path for $toolName"
        exit 1
    fi

    echo "$toolsSearchPath"
}

# Gets the error message to be displayed when the specified tool is not available for the build.
# Error message is read from the .toolversions file.
tool_not_found_message()
{
    if [ -z "$1" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    toolName="$1"
    scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
    eval_tool "$toolName"

    if [ -z "$ToolNotFoundError" ]; then
        echo "Unable to locate $toolName."
        exit 1
    fi

    eval echo "$ToolNotFoundError"
}
