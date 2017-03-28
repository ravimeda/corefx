#!/usr/bin/env bash

# invoke-extension.sh
# Calls the given script, which does a search or acquire, with the specified arguments. 
# Checks if the given script is overridden, and if so calls the overridden script.
# Arguments:
#   1. Name of the script
#   2. Name of the tool
#   3. A boolean indicating if the version of the tool to be searched should match the declared version
#       0 if no version check.
#       1 if version should match the declared version.
# All arguments will be passed on to the script being called.

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 ScriptName ToolName StrictToolVersionMatch"
    echo "ScriptName: Name of the search or acquire script."
    echo "ToolName: Name of the tool to download."
    echo "StrictToolVersionMatch: A boolean indicating if the version of the tool to be searched should match the declared version."
    echo "                          0 if no version check."
    echo "                          1 if version should match the declared version."
    echo "Invokes the specified script corresponding to the tool."
    echo "ToolName, StrictToolVersionMatch, and any other arguments specified are passed on to the invoked script."
    exit 1
fi

if [ -z "$1" ]; then
    echo "Argument passed as search or acquire script name is empty. Please provide a non-empty string."
    exit 1
fi

if [ -z "$2" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

invokeScriptName="$1"
toolName="$2"
scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
invokeScriptPath="$scriptPath/$invokeScriptName"
overrideScriptPath="$scriptPath/$toolName/$invokeScriptName"

# Check if the tool overrides base implementation.
if [ -f "$overrideScriptPath" ]; then
    invokeScriptPath="$overrideScriptPath"
fi

# Since the first argument is the name of the script being invoked, skip this argument, and pass the rest.
shift
"$invokeScriptPath" "$@"
exit $?
