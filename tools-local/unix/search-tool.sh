#!/usr/bin/env bash

usage()
{
    echo "usage: $0 <repository-root> <tool-name> <override-scripts-folder-path> <strict-tool-version-match>"
    echo "repository-root                   Path to repository root."
    echo "tool-name                         Name of the tool to search."
    echo "override-scripts-folder-path      If a path is specified then, scripts from the specified folder will be invoked. Otherwise, the default scripts located within the repository will be invoked."
    echo "strict-tool-version-match         If equals to \"strict\" then, search will ensure that the version of the tool searched is the declared version. Otherwise, search will attempt to find a version of the tool, which may not be the declared version."
    echo ""
    echo "Searches for the tool in the environment path, and a path specified for the tool in the .toolversions file."
    echo "If search is successful then, returns the path to the tool."
    echo "Exit 1 if search fails to find the tool."
}

if [ $# -ne 4 ]; then
    usage
    exit 1
fi

repoRoot="$1"
toolName="$2"
overrideScriptsPath="$3"
strictToolVersionMatch="$4"

if [ -z "$repoRoot" ]; then
    echo "Argument passed as repository-root is empty. Please provide a non-empty string."
    usage
    exit 1
fi

if [ -z "$toolName" ]; then
    echo "Argument passed as toolname is empty. Please provide a non-empty string."
    usage
    exit 1
fi

scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
. "$scriptPath/tool-helper.sh"
declaredVersion="$(get_tool_config_value "$repoRoot" "$toolName" "DeclaredVersion")"


# Displays the tool path.
display_tool_path()
{
    echo "$toolPath"
    log_message "$repoRoot" "$toolName is available at $toolPath. Version is $toolVersion."
}

# Searches the tool in environment path.
search_environment()
{
    log_message "$repoRoot" "Searching for $toolName in environment path."
    hash "$toolName" 2>/dev/null

    if [ $? -eq 0 ]; then
        toolPath="$(which $toolName)"

        if [ "$strictToolVersionMatch" != "strict" ]; then
            # No strictToolVersionMatch. Hence, return the path found without version check.
            display_tool_path
            exit
        else
            # If strictToolVersionMatch is required then, ensure the version in environment path is same as declared version.
            # If version matches then, return the path.
            toolVersion="$("$scriptPath/invoke-extension.sh" "get-version.sh" "$repoRoot" "$toolName" "$overrideScriptsPath" "" "$toolPath")"

            if [ "$toolVersion" == "$declaredVersion" ]; then
                # Version available in environment path is the declared version.
                display_tool_path
                exit
            fi
        fi

        log_message "$repoRoot" "Version of $toolName at $toolPath is $toolVersion. This version does not match the declared version $declaredVersion."
    fi
}

# Searches the tool in the local tools cache.
search_cache()
{
    log_message "$repoRoot" "Searching for $toolName within the repository."
    toolPath="$(get_local_search_path "$repoRoot" "$toolName")"
    toolVersion="$("$scriptPath/invoke-extension.sh" "get-version.sh" "$repoRoot" "$toolName" "$overrideScriptsPath" "" "$toolPath")"

    if [ "$toolVersion" == "$declaredVersion" ]; then
        # Declared version of the tool is available within the repository.
        display_tool_path
        exit
    fi

    echo "Unable to locate $toolName neither in environment path nor at $toolPath."
    exit 1
}


# Begin search in the environment path
search_environment

# Since the tool or the required version was not found in environment, 
# search the tool in the local tools cache specified in the .toolversions file.
search_cache
