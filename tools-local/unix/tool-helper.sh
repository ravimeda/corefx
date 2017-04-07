#!/usr/bin/env bash

# Provides helper functions.

# Gets name of the operating system.
# Exit 1 if unable to get operating system name.
get_os_name()
{
    osName="$(uname -s)"

    if [ $? -ne 0 ] || [ -z "$osName" ]; then
        echo "Unable to determine the name of the operating system."
        exit 1
    fi

    if echo "$osName" | grep -iqF "Darwin"; then
        osName="OSX"
    else
        osName="Linux"
    fi

    echo "$osName"
}

# Gets the path to the folder corresponding to the specified tool name in Tools/downloads folder under repository root.
# Exit 1 if unable to determine the path.
get_repository_tools_downloads_folder()
{
    if [ -z "$1" ]; then
        echo "Argument passed as repository-root is empty. Please provide a non-empty string."
        usage
        exit 1
    fi

    if [ -z "$2" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    repoRoot="$1"
    toolName="$2"
    toolsPath="$repoRoot/Tools/downloads"
    
    if [ -z "$toolsPath" ]; then
        echo "Unable to determine repository tools path."
        exit 1
    fi

    echo "$toolsPath/$toolName"
}

# Eval .toolversions file.
eval_tool()
{
    if [ -z "$1" ]; then
        echo "Argument passed as repository-root is empty. Please provide a non-empty string."
        usage
        exit 1
    fi

    if [ -z "$2" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    repoRoot="$1"
    toolName="$2"

    # TODO: Consider accepting the path to .toolversions file.
    . "$repoRoot/.toolversions"

    # Evaluate toolName. This assigns the metadata of toolName to tools.
    eval "tools=\$$toolName"

    # Evaluate tools. Each argument here is tool specific data such as DeclaredVersion of toolName.
    eval "$tools"
}

# Gets the value corresponding to the specified configuration from the .toolversions file.
# Exit 1 if the value is not found or empty.
get_tool_config_value()
{
    if [ -z "$1" ]; then
        echo "Argument passed as repository-root is empty. Please provide a non-empty string."
        usage
        exit 1
    fi

    if [ -z "$2" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    if [ -z "$3" ]; then
        echo "Argument passed as configuration name is empty. Please provide a non-empty string."
        exit 1
    fi

    repoRoot="$1"
    toolName="$2"
    configName="$3"
    configValue="$(eval_tool "$repoRoot" "$toolName"; eval echo "\$$configName")"

    if [ -z "$configValue" ]; then
        echo "Unable to read the value corresponding to $configName from the .toolversions file."
        exit 1
    fi

    echo "$configValue"
}

# Gets the name of the download package corresponding to the specified tool name.
# Download package name is read from the .toolversions file.
# Exit 1 if unable to read the name of the download package from the .toolversions file.
get_download_package_name()
{
    if [ -z "$1" ]; then
        echo "Argument passed as repository-root is empty. Please provide a non-empty string."
        usage
        exit 1
    fi

    if [ -z "$2" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    repoRoot="$1"
    toolName="$2"
    osName="$(get_os_name)"
    get_tool_config_value "$repoRoot" "$toolName" "DownloadFile$osName"
}

# Gets the search path corresponding to the specified tool name.
# Search path is read from the .toolversions file.
# Exit 1 if unable to read the path from the .toolversions file.
get_repository_tool_search_path()
{
    if [ -z "$1" ]; then
        echo "Argument passed as repository-root is empty. Please provide a non-empty string."
        usage
        exit 1
    fi

    if [ -z "$2" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    repoRoot="$1"
    toolName="$2"
    osName="$(get_os_name)"
    searchPath="$(get_tool_config_value "$repoRoot" "$toolName" "SearchPath${osName}Tools")"

    echo "$repoRoot/$searchPath"
}

# Gets the error message to be displayed when the specified tool is not available for the build.
# Error message is read from the .toolversions file.
# Exit 1 if unable to read the error message from the .toolversions file.
tool_not_found_message()
{
    if [ -z "$1" ]; then
        echo "Argument passed as repository-root is empty. Please provide a non-empty string."
        usage
        exit 1
    fi

    if [ -z "$2" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    repoRoot="$1"
    toolName="$2"
    scriptPath="$(cd "$(dirname "$0")"; pwd -P)"

    # Eval in a subshell to avoid conflict with existing variables.
    (
        eval_tool "$repoRoot" "$toolName"

        if [ -z "$ToolNotFoundMessage" ]; then
            echo "Unable to locate $toolName."
            exit 1
        fi

        eval echo "$ToolNotFoundMessage"
    )
}

# Write the given message(s) to probe log file.
log_message()
{
    scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
    probeLog="$scriptPath/probe-tool.log"
    echo "$*" >> "$probeLog"
}
