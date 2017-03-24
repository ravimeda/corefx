#!/usr/bin/env bash

# Provides helper functions.

# Gets the repository root path.
get_repo_root()
{
    scriptpath="$(cd "$(dirname "$0")"; pwd -P)"
    repoRoot="$(cd "$scriptpath/../.."; pwd -P)"
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
# Operating system name is determined using uname command.
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

# Gets the search path corresponding to the specified tool name and operating system.
# Operating system name is determined using uname command.
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

# Compares the version of the tool at the specified path with the declared version of the tool.
# Each tool has to implement its own is_declared_version.sh script that performs version comparison.
# This function invokes is_declared_version.sh corresponding to the tool.
# Exit 1 if -
#   2. is_declared_version.sh script corresponding to the tool is not found
#   3. The version of the tool at the given path does match the declared version.
is_declared_version()
{
    if [ -z "$1" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    if [ -z "$2" ]; then
        echo "Argument passed as tool path is empty. Please provide a non-empty string."
        exit 1
    fi

    toolName="$1"
    toolPath="$2"
    scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
    declaredVersion=$(get_declared_version "$toolName")

    if [ $? -eq 1 ]; then
        echo "$declaredVersion"
        exit 1
    fi

    overriddenIsDeclaredVersionScriptPath="$scriptPath/$toolName/is_declared_version.sh"

    if [ -f "$overriddenIsDeclaredVersionScriptPath" ]; then
        "$overriddenIsDeclaredVersionScriptPath" "$toolPath" "$declaredVersion"

        if [ $? -eq 1 ]; then
            exit 1
        fi
    else
        echo "Unable to locate is_declared_version.sh at the specified path. Path: $overriddenIsDeclaredVersionScriptPath"
        exit 1
    fi
}

# Gets the error message to be displayed when the specified tool is not available for the build.
# Each tool has to implement its own tool_not_found_message.sh script that returns the error message specific to the tool.
# This function invokes tool_not_found_message.sh corresponding to the tool.
# Exit 1 if the tool_not_found_message.sh is not found.
tool_not_found_message()
{
    if [ -z "$1" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    toolName="$1"
    scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
    declaredVersion=$(get_declared_version "$toolName")
    
    if [ $? -eq 1 ]; then
        echo "$declaredVersion"
        exit 1
    fi

    overriddenToolNotFoundMessage="$scriptPath/$toolName/tool_not_found_message.sh"

    if [ -f "$overriddenToolNotFoundMessage" ]; then
        message=$("$overriddenToolNotFoundMessage" "$shellScriptsPath" "$declaredVersion")

        if [ $? -eq 1 ]; then
            echo "$message"
            exit 1
        fi
    else
        echo "Unable to locate tool_not_found_message.sh at the specified path. Path: $overriddenToolNotFoundMessage"
        exit 1
    fi

    echo "$message"
}
