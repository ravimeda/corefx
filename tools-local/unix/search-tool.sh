#!/usr/bin/env bash

# Searches for the tool in the environment path, and the path within the repository as specified in toolversions file.
# Arguments:
#   1. Name of the tool
#   2. A boolean indicating if the version of the tool to be searched should match the declared version.
#       0 if no version check.
#       1 if version should match the declared version.

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

if [ -z "$2" ]; then
    echo "Please specify a boolean to indicate if the version of the tool should match the declared version."
    exit 1
fi

toolName="$1"
strictToolVersionMatch="$2"
scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
. "$scriptPath/tool-helper.sh"
probeLog="$scriptPath/probe-tool.log"
declaredVersion="$(get_declared_version "$toolName")"

# Displays the values of path and version, and exits script.
display_path_version()
{
    echo "$toolPath"
    echo "$toolVersion"
    echo "$(date) $toolName is available at $toolPath. Version is $toolVersion." >> $probeLog
    exit 0
}

# Searches the tool in environment path.
search_environment()
{
    echo "$(date) Searching for $toolName in environment path" >> $probeLog
    hash "$toolName" 2>/dev/null

    if [ $? -eq 0 ]; then
        toolPath="$(which $toolName)"
        toolVersion="$("$scriptPath/get-version.sh" "$toolName" "$toolPath")"

        if [ "$strictToolVersionMatch" -eq "0" ]; then
            # No strictToolVersionMatch. Hence, return the path found without further checks.
            display_path_version
        else
            # If strictToolVersionMatch is required then, ensure the version in environment path is same as declared version.
            # If version matches then, return the path.
            if [ "$toolVersion" == "$declaredVersion" ]; then
                # Version available in environment path is the declared version.
                display_path_version
            fi
        fi
        echo "$(date) Version of $toolName at $toolPath is $toolVersion. This version does not match the declared version $declaredVersion." >> $probeLog
    fi
}

# Searches the tool within the repository.
search_repository()
{
    echo "$(date) Searching for $toolName within the repository." >> $probeLog
    toolPath="$(get_repository_tool_search_path "$toolName")"
    toolVersion="$("$scriptPath/get-version.sh" "$toolName" "$toolPath")"

    if [ "$toolVersion" == "$declaredVersion" ]; then
        # Declared version of the tool was acquired.
        display_path_version
    fi

    echo "$(date) Version of the tool at $toolPath is $toolVersion. This version does not match the declared version $declaredVersion." >> $probeLog
    exit 1
}


# Search in the environment path
search_environment

# Search in the repository path specified in the .toolversions file.
search_repository
