#!/usr/bin/env bash

# invoke-search-extension.sh
# Calls the script that searches for the given tool name in the corresponding paths specified in toolversions file.
# Checks if the tool overrides the default search script. If so calls the override script. Otherwise, calls the default search script.
# Arguments:
#   1. Name of the tool.
#   2. A boolean indicating if the version of the tool to be searched should match the declared version.
#       0 if no version check.
#       1 if version should match the declared version.
#   3. Any other arguments required for the override script.
# All arguments will be passed on to the search script.

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
searchScript="$scriptPath/search-tool.sh"
overrideSearchToolScriptPath="$scriptPath/$toolName/search-tool.sh"

# Check if the tool overrides base implementation.
if [ -f "$overrideSearchToolScriptPath" ]; then
    searchScript="$overrideSearchToolScriptPath"
fi

"$searchScript" "$@"
exit $?
