#!/usr/bin/env bash

# Searches the for the specified tool. If tool is not found then, downloads the tool.
# Paths to search, and download URL is read from the .toolversions file.

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 ToolName StrictToolVersionMatch"
    echo "ToolName: Name of the tool to download."
    echo "StrictToolVersionMatch: A boolean indicating if the version of the tool to be searched should match the declared version."
    echo "                          0 if no version check."
    echo "                          1 if version should match the declared version."
    echo "Invokes scripts that perform search and/or acquire for the specified tool."
    echo "ToolName, StrictToolVersionMatch, and any other arguments specified are passed on to the script."
    exit 1
fi

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

toolName="$1"
strictToolVersionMatch=0

if [ ! -z "$2" ]; then
    strictToolVersionMatch="$2"
fi

scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
. "$scriptPath/tool-helper.sh"
probeLog="$scriptPath/probe-tool.log"

# Search for the tool.
toolPath=$("$scriptPath/invoke-extension.sh" "search-tool.sh" "$@")

# If search failed then, attempt to download the tool.
if [ $? -ne 0 ]; then
    toolPath=$("$scriptPath/invoke-extension.sh" "acquire-tool.sh" "$@")

    if [ $? -ne 0 ]; then
        # If download failed too then, return error message corresponding to the tool.
        echo $(tool_not_found_message "$toolName")
        exit 1
    fi
fi

echo "$toolPath"
