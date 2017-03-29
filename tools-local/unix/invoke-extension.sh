#!/usr/bin/env bash

# Calls the given script, which does a search or acquire, with the specified arguments. 

usage()
{
    echo "Usage: $0 ScriptName ToolName StrictToolVersionMatch ..."
    echo "  ScriptName: Name of the search or acquire script."
    echo "  ToolName: Name of the tool to download."
    echo "  StrictToolVersionMatch: A boolean indicating if the version of the tool to be searched should match the declared version."
    echo "                          0 if no version check."
    echo "                          1 if version should match the declared version."
    echo "Checks if a the specified tool has it own implementation of the search or acquire script. If so, invokes the corresponding script. Otherwise, invokes the default implementation."
    echo "ToolName, StrictToolVersionMatch, and any other arguments specified are passed on to the invoked script."
}

if [ $# -lt 3 ]; then
    usage
    exit 1
fi

if [ -z "$1" ]; then
    echo "Argument passed as ScriptName is empty. Please provide a non-empty string."
    exit 1
fi

if [ -z "$2" ]; then
    echo "Argument passed as ToolName is empty. Please provide a non-empty string."
    exit 1
fi

if [ -z "$3" ]; then
    echo "Argument passed as StrictToolVersionMatch is empty. Please provide a non-empty string."
    exit 1
fi

invokeScriptName="$1"
toolName="$2"
scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
probeLog="$scriptPath/probe-tool.log"
invokeScriptPath="$scriptPath/$invokeScriptName"
overrideScriptPath="$scriptPath/$toolName/$invokeScriptName"

# Check if the tool overrides base implementation.
if [ -f "$overrideScriptPath" ]; then
    echo "$(date) Invoking override script." >> "$probeLog"
    invokeScriptPath="$overrideScriptPath"
fi

# Since the first argument is the name of the script being invoked, skip this argument, and pass the rest.
shift

"$invokeScriptPath" "$@"
exit $?
