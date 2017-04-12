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

# Eval .toolversions file.
# TODO: 
#   1. Consider accepting the path to an override .toolversions file.
#   2. If the override .toolversions is available then, use the config values from that file.
#   3. If override is not available then use the default .toolversions file.
eval_tool()
{
    if [ -z "$1" ]; then
        echo "Argument passed as repository-root is empty. Please provide a non-empty string."
        exit 1
    fi

    if [ -z "$2" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    repoRoot="$1"
    toolName="$2"
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
get_download_file()
{
    if [ -z "$1" ]; then
        echo "Argument passed as repository-root is empty. Please provide a non-empty string."
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

# Gets the absolute path to the cache corresponding to the specified tool.
# Path is read from the .toolversions file. If the path is not specified in .toolversions file then,
# returns the path to Tools/downloads folder under the repository root.
get_local_tool_folder()
{
    if [ -z "$1" ]; then
        echo "Argument passed as repository-root is empty. Please provide a non-empty string."
        exit 1
    fi

    if [ -z "$2" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    repoRoot="$1"
    toolName="$2"
    toolFolder="$(get_tool_config_value "$repoRoot" "$toolName" "LocalToolFolder")"

    if [ -z "$toolFolder" ]; then
        toolFolder="Tools/downloads/$toolName"
    fi

    case "$toolFolder" in
        /*)
            echo "$toolFolder"
            ;;
        *)
            # Assumed that the path specified in .toolversion is relative to the repository root.
            echo "$repoRoot/$toolFolder"
            ;;
    esac
}

# Gets the search path corresponding to the specified tool name.
# Search path is read from the .toolversions file.
# Exit 1 if unable to read the path from the .toolversions file.
get_local_search_path()
{
    if [ -z "$1" ]; then
        echo "Argument passed as repository-root is empty. Please provide a non-empty string."
        exit 1
    fi

    if [ -z "$2" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    repoRoot="$1"
    toolName="$2"
    toolFolder="$(get_local_tool_folder "$repoRoot" "$toolName")"

    osName="$(get_os_name)"
    searchPath="$(get_tool_config_value "$repoRoot" "$toolName" "LocalSearchPath${osName}")"

    echo "$toolFolder/$searchPath"
}

# Gets the error message to be displayed when the specified tool is not available for the build.
# Error message is read from the .toolversions file.
# Exit 1 if unable to read the error message from the .toolversions file.
tool_not_found_message()
{
    if [ -z "$1" ]; then
        echo "Argument passed as repository-root is empty. Please provide a non-empty string."
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
    if [ -z "$1" ]; then
        echo "Argument passed as repository-root is empty. Please provide a non-empty string."
        exit 1
    fi

    repoRoot="$1"
    probeLog="$repoRoot/probe-tool.log"
    shift

    echo "$*" >> "$probeLog"
}
