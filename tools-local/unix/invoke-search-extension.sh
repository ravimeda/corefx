#!/usr/bin/env bash

# invoke-search-extension.sh
# Calls the script that searches for the given tool name in the corresponding paths specified in toolversions file.
# Checks if there is an overridden search script for the given tool. If so calls the overridden script. Otherwise, calls the default search script.
# Arguments:
#   1. Name of the tool
#   2. (optional) Boolean indicating if the version of the tool to be searched should match the declared version. If none specified, then this is set to false (0).
# All arguments will be passed on to the search script.

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

toolName="$1"
scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
searchScript="$scriptPath/search-tool.sh"
overrideSearchToolScriptPath="$scriptPath/$toolName/search-tool.sh"

# Check if the tool overrides base implementation.
if [ -f "$overrideSearchToolScriptPath" ]; then
    searchScript="$overrideSearchToolScriptPath"
fi

"$searchScript" "$@"
echo "$toolPath"
exit $?
