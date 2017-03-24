#!/usr/bin/env bash

# invoke-acquire-extension.sh
# Calls the script that acquires the declared version of the given tool name from the corresponding URL specified in toolversions file.
# Checks if there is an overridden acquire script for the given tool name. If so calls the overridden script. Otherwise, calls the default acquire script.
# Arguments:
#   1. Name of the tool
# All arguments will be passed on to the acquire script.

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

toolName="$1"
scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
acquireScript="$scriptPath/acquire-tool.sh"
overrideAcquireToolScriptPath="$scriptPath/$toolName/acquire-tool.sh"

# Check if the tool overrides base implementation.
if [ -f "$overrideAcquireToolScriptPath" ]; then
    acquireScript="$overrideAcquireToolScriptPath"
fi

"$acquireScript" "$@"
echo "$toolPath"
exit $?
