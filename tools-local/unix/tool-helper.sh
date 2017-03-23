#!/usr/bin/env bash

# Provides helper functions.

# Gets the repository root path.
get-repo-root()
{
    scriptpath="$(cd "$(dirname "$0")"; pwd -P)"
    repoRoot="$(cd "$scriptpath/../.."; pwd -P)"
    echo "$repoRoot"
}

# Gets the path to Tools/downloads folder under repository root.
# Exit 1 if unable to determine the path.
get_repository_tools_path()
{
    repoRoot="$(get-repo-root)"
    toolsPath="$repoRoot/Tools/downloads"
    
    if [ -z "$toolsPath" ]; then
        echo "Unable to determine repository tools path."
        exit 1
    fi

    echo "$toolsPath"
}

# Eval .toolversions file.
eval_tools()
{
    repoRoot="$(get-repo-root)"

    # Dot source toolversions file.
    . "$repoRoot/.toolversions"

    eval "tools=\$$toolName"
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
    eval_tools

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
    eval_tools

    if [ -z "$DownloadUrl" ]; then
        echo "Unable to read download URL for $toolName"
        exit 1
    fi

    echo "$DownloadUrl"
}

# Gets the search path corresponding to the specified tool name and operating system.
# Operating system name is determined using uname command.
# Exit 1 if unable to read the path from .toolversions file.
get_tool_search_path()
{
    if [ -z "$1" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    toolName="$1"
    eval_tools
    osName="$(uname -s)"

    if $(echo "$osName" | grep -iqF "Darwin"); then
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
    eval_tools
    osName="$(uname -s)"

    if $(echo "$osName" | grep -iqF "Darwin"); then
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

# Compares the version of the tool at the specified path with the declared version of the tool.
# Each tool has to implement its own is_declared_version.sh script that performs version comparison.
# This function invokes is_declared_version.sh corresponding to the tool.
# Exit 1 if -
#   1. The tool does not exist at the given path
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

    if [ ! -f "$2" ]; then
        echo "Tool path does not exist or is not accessible. Path: $2"
        exit 1
    fi

    toolName="$1"
    lowercaseToolName="$(echo $toolName | awk '{print tolower($0)}')"
    toolPath="$2"
    declaredVersion=$(get_declared_version "$toolName")

    if [ $? -eq 1 ]; then
        echo "$declaredVersion"
        exit 1
    fi

    overridenIsDeclaredVersion="$lowercaseToolName/is_declared_version.sh"

    if [ ! -z "$overridenIsDeclaredVersion" && f "$overridenIsDeclaredVersion" ]; then
        $("$overridenIsDeclaredVersion" "$toolPath" "$declaredVersion")

        if [ $? -eq 1 ]; then
            exit 1
        fi
    else
        echo "Unable to locate is_declared_version.sh at the specified path. Path: $overridenIsDeclaredVersion"
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
    lowercaseToolName="$(echo $toolName | awk '{print tolower($0)}')"
    repoRoot=$(get_repo_root)
    declaredVersion=$(get_declared_version "CMake")
    
    if [ $? -eq 1 ]; then
        echo "$declaredVersion"
        exit 1
    fi

    overridenToolNotFoundMessage="$lowercaseToolName/tool_not_found_message.sh"

    if [ ! -z "$overridenToolNotFoundMessage" && f "$overridenToolNotFoundMessage" ]; then
        message=$("$overridenToolNotFoundMessage" "$repoRoot" "$declaredVersion")

        if [ $? -eq 1 ]; then
            echo "$message"
            exit 1
        fi
    else
        echo "Unable to locate tool_not_found_message.sh at the specified path. Path: $overridenToolNotFoundMessage"
        exit 1
    fi

    echo "$message"
}
