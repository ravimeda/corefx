#!/usr/bin/env bash

# Locates the specified tool.
# Searches for the tool in the corresponding paths specified in toolversions file.

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

toolName="$1"
strictToolVersionMatch=0

if [ ! -z "$2" ]; then
    strictToolVersionMatch="$2"
fi

# Checks if there is an overridden search-tool script.
# If yes then, use that script to locate search the tool.
overriden_search_tool()
{
    lowercaseToolName="$(echo "$toolName" | awk '{print tolower($0)}')"
    overrideSearchToolScriptPath="$lowercaseToolName/search-tool.sh"

    if [[ ! -z "$overrideSearchToolScriptPath" && -f "$overrideSearchToolScriptPath" ]]; then
        toolPath="$("$overrideSearchToolScriptPath" "$strictToolVersionMatch")"

        if [ $? -ne 0 ]; then
            echo "$toolPath"
            exit 1
        else
            echo "$toolPath"
            exit 0
        fi
    fi
}

# Searches the tool in environment path.
search_environment()
{
    hash "$toolName" 2>/dev/null

    if [ $? -eq 0 ]; then
        toolPath="$(which $toolName)"

        if [ $strictToolVersionMatch == 0 ]; then
            # If found and no strictToolVersionMatch is required then return the path.
            echo "$toolPath"
            exit 0
        else
            # If strictToolVersionMatch is required then, ensure the version in environment path is same as declared version.
            # If version matches then, return the path.
            $(is_declared_version "$toolName" "$toolPath") 2>/dev/null

            if [ $? -eq 0 ]; then
                # Version available in environment path is the declared version.
                echo "$toolPath"
                exit 0
            fi
        fi
    fi
}

# Searches the tool in path specified in .toolversions file.
search_repository()
{
    toolPath="$(get_repository_tool_search_path "$toolName")"
    $(is_declared_version "$toolName" "$toolPath") 2>/dev/null

    if [ $? -eq 0 ]; then
        # Declared version of the tool is available in Tools/downloads.
        echo "$toolPath"
        exit 0
    fi

    echo "$toolName is not found."
    exit 1
}


scriptpath="$(cd "$(dirname "$0")"; pwd -P)"
repoRoot="$(cd "$scriptpath/../.."; pwd -P)"
shellScriptsRoot="$repoRoot/tools-local/unix"

# Dot source helper file.
. "$shellScriptsRoot/tool-helper.sh"

# Call overridden search-tool script, if any.
overriden_search_tool

# If no override was found then, search in the environment path
search_environment

# Search in the path specified in the .toolversions file.
search_repository
