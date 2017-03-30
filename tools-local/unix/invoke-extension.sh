#!/usr/bin/env bash

# Locates and invokes the given extension script, which does a search or acquire, with the specified arguments. 

usage()
{
    echo "Usage: $0 ScriptName ToolName StrictToolVersionMatch ToolsOverride"
    echo "  ScriptName: Name of the search or acquire script."
    echo "  ToolName: Name of the tool to download."
    echo "  StrictToolVersionMatch: A boolean indicating if the version of the tool to be searched should match the declared version."
    echo "                          0 if no version check."
    echo "                          1 if version should match the declared version."
    echo "  ToolsOverride: If specified then, search and acquire scripts from the specified override folder will be invoked."
    echo ""
    echo "Checks if the specified tool has its own implementation of the search or acquire script. If so, invokes the corresponding script. Otherwise, invokes the default implementation."
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

extensionScriptName="$1"
toolName="$2"
strictToolVersionMatch="$3"
toolsOverrideFolder="$4"
scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
probeLog="$scriptPath/probe-tool.log"


invoke_script()
{
    "$invokeScriptPath" "$toolName" "$strictToolVersionMatch"
    exit $?
}

# Locates the appropriate extension script, which is a search or acquire script in the specified folder.
# If a tool overrides the base implementation of the extension script then, the corresponding override script is invoked.
# Otherwise, invokes the script with base implementation.
get_extension_script()
{
    extensionsFolder="$1"

    # Check if the tool overrides base implementation.
    invokeScriptPath="$extensionsFolder/$toolName/$extensionScriptName"

    if [ ! -f "$invokeScriptPath" ]; then
        invokeScriptPath="$extensionsFolder/$extensionScriptName"
    fi

    echo "$(date) Invoking $extensionScriptName from $extensionsFolder." >> "$probeLog"
    invoke_script
}

# Check if build provided a tools override folder.
if [ ! -z "$toolsOverrideFolder" ] && [ -d "$toolsOverrideFolder" ]; then
    get_extension_script $toolsOverrideFolder
fi

# Use the scripts from the default tools folder.
get_extension_script $scriptPath
