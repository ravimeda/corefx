#!/usr/bin/env bash

# Locates and invokes the given extension script, which does a search or acquire, with the specified arguments. 

usage()
{
    echo "Usage: $0 ScriptName ToolName StrictToolVersionMatch ToolsOverride"
    echo "  ScriptName: Name of the search or acquire script."
    echo "  ToolName: Name of the tool to search and/or download."
    echo "  StrictToolVersionMatch: A boolean indicating if the version of the tool to be searched should match the declared version."
    echo "                          0 if no version check."
    echo "                          1 if version should match the declared version."
    echo "  (Optional) ToolsOverride: If specified then, search and acquire scripts from the specified override folder will be invoked."
    echo ""
    echo "Checks if the specified tool has its own implementation of the search or acquire script. If so, invokes the corresponding script. Otherwise, invokes the base implementation."
    echo ""
    echo "Example #1"
    echo "invoke-extension.sh \"search-tool.sh\" \"cmake\" 1"
    echo "  Searches for the declared version of CMake using the default search scripts located within the repository."
    echo ""
    echo "Example #2"
    echo "invoke-extension.sh \"acquire-tool.sh\" \"cmake\" 1 \"/Users/dotnet/MyCustomScripts\""
    echo "  Acquires the declared version of CMake using the acquire script located in the specified override folder that is \"/Users/dotnet/MyCustomScripts\"."
    echo ""
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

# Locates the appropriate extension script in the folders specified.
#   1. In ToolsOverride folder check if the tool overrides base implementation. 
#       a. If yes then, invoke the override, and return.
#       b. If no then, invoke the base implementation, and return.
#   2. If ToolsOverride folder does not exist then, perform 1.a & 1.b in the default scripts folder.
get_extension_script()
{
    while :; do

        if [ $# -le 0 ]; then
            break
        fi

        extensionsFolder="$1"

        if [ ! -z "$extensionsFolder" ] && [ -d "$extensionsFolder" ]; then
            invokeScriptPath="$extensionsFolder/$toolName/$extensionScriptName"

            if [ ! -f "$invokeScriptPath" ]; then
                # Tool does not override the base implementation.
                invokeScriptPath="$extensionsFolder/$extensionScriptName"
            fi

            echo "$(date) Invoking $extensionScriptName from $extensionsFolder." >> "$probeLog"
            invoke_script
        fi

        shift
    done
}

# Invoke the appropriate extension that performs the search or acquire.
# Search ToolsOverride first and then default scripts folder, which is located within the repository.
get_extension_script $toolsOverrideFolder $scriptPath
