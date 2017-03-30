#!/usr/bin/env bash

# Searches for the specified tool. If tool is not found then, downloads the tool.

usage()
{
    echo "Usage: $0 -ToolName <name> -StrictToolVersionMatch <boolean> -ToolsOverride <path>"
    echo "  ToolName: Name of the tool to download."
    echo "  (Optional) StrictToolVersionMatch: A boolean indicating if the version of the tool to be searched should match the declared version."
    echo "                          0 if no version check."
    echo "                          1 if version should match the declared version."
    echo "  (Optional) ToolsOverride: If specified then, search and acquire scripts from the specified override folder will be invoked."
    echo ""
    echo "Invokes an extension that calls the appropriate search and/or acquire scripts. ToolName and StrictToolVersionMatch are passed on to the extension."
    echo ""
    echo "Example #1"
    echo " probe-tool.sh -ToolName \"cmake\" -StrictToolVersionMatch 0"
    echo " Probes for CMake, not necessarily the declared version, using the default search and acquire scripts located within the repository."    
    echo ""
    echo "Example #2"
    echo " probe-tool.sh -ToolsOverride \"/Users/dotnet/MyCustomScripts\" -ToolName \"cmake\" -StrictToolVersionMatch 1"
    echo " Probes for the declared version of CMake using the search and acquire scripts located in \"/Users/dotnet/MyCustomScripts\"."
    echo ""
}

toolsOverrideFolderPath=""
toolName=""
strictToolVersionMatch=0
scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
probeLog="$scriptPath/probe-tool.log"
echo "$(date) $@" >> "$probeLog"

while :; do
    if [ $# -le 0 ]; then
        break
    fi

    lowerI="$(echo $1 | awk '{print tolower($0)}')"
    case $lowerI in
        -\?|-h|--help)
            usage
            exit 1
            ;;
        -toolsoverride)
            shift
            if [ ! -z "$1" ]; then
                toolsOverrideFolderPath="$(cd "$1"; pwd -P)"
            fi
            ;;
        -toolname)
            shift
            toolName="$1"
            ;;
        -stricttoolversionmatch)
            shift
            if [ ! -z "$1" ]; then
                strictToolVersionMatch="$1"
            fi
            ;;
        *)
        usage
        exit 1
    esac
    shift
done

if [ -z "$toolName" ]; then
    echo "Argument passed as ToolName is empty. Please provide a non-empty string."
    exit 1
fi


# Search the tool.
echo "$(date) Begin search for $toolName." >> "$probeLog"
toolPath="$("$scriptPath/invoke-extension.sh" "search-tool.sh" "$toolName" "$strictToolVersionMatch" "$toolsOverrideFolderPath")"

# If search failed then, attempt to download the tool.
if [ $? -ne 0 ]; then
    echo "$(date) Begin acquire for $toolName." >> "$probeLog"
    toolPath="$("$scriptPath/invoke-extension.sh" "acquire-tool.sh" "$toolName" "$strictToolVersionMatch" "$toolsOverrideFolderPath")"

    if [ $? -ne 0 ]; then
        . "$scriptPath/tool-helper.sh"
        # If download failed too then, return error message corresponding to the tool.
        echo "$(tool_not_found_message "$toolName")"
        exit 1
    fi
fi

echo "$toolPath"
