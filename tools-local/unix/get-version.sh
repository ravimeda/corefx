#!/usr/bin/env bash

# Gets the version of the executable at the given path.

usage()
{
    echo "Usage: $0 ToolName ToolPath"
    echo "  ToolName: Name of the tool."
    echo "  ToolPath: Path to the executable or the folder containing the tool."
    echo ""
    echo "Invokes a tool specific script that has the implementation for determining the version from the given executable."
    echo "Exit 1 if the executable is not available at the specified path or folder."
}

if [ $# -ne 2 ]; then
    usage
    exit 1
fi

if [ -z "$1" ]; then
    echo "Argument passed as ToolName is empty. Please provide a non-empty string."
    exit 1
fi

if [ -z "$2" ]; then
    echo "Argument passed as ToolPath is empty. Please provide a valid path."
    exit 1
fi

toolName="$1"
toolPath="$2"
scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
overriddenGetVersionScriptPath="$scriptPath/$toolName/get-version.sh"

if [ ! -f "$overriddenGetVersionScriptPath" ]; then
    echo "Unable to locate get-version.sh at the specified path. Path: $overriddenGetVersionScriptPath"
    exit 1
fi

"$overriddenGetVersionScriptPath" "$toolPath"

if [ $? -eq 1 ]; then
    exit 1
fi
