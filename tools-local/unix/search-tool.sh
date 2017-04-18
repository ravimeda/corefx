#!/usr/bin/env bash

usage()
{
    echo ""
    echo "usage: $0 <repository-root> <tool-name> <override-scripts-folder-path> <strict-tool-version-match>"
    echo "repository-root                   Path to repository root."
    echo "tool-name                         Name of the tool to search."
    echo "override-scripts-folder-path      If a path is specified then, scripts from the specified folder will be invoked."
    echo "                                  Otherwise, the default scripts located within the repository will be invoked."
    echo "strict-tool-version-match         If equals to \"strict\" then, search will ensure that the version of the tool searched is the declared version."
    echo "                                  Otherwise, search will attempt to find a version of the tool, which may not be the declared version."
    echo ""
    echo "Searches for the tool in the environment path, and a path specified for the tool in the .toolversions file."
    echo "If search is successful then, returns the path to the tool."
    echo "Exit 1 if search fails to find the tool."
    echo ""
}

repoRoot="$1"
toolName="$2"
overrideScriptsPath="$3"
strictToolVersionMatch="$4"

scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
. "$scriptPath/tool-helper.sh"

exit_if_invalid_path "repository-root" "$repoRoot" "$(usage)"
exit_if_arg_empty "tool-name" "$toolName" "$(usage)"
[ $# -eq 4 ] || fail "$repoRoot" "Invalid number of arguments. Expected: 4 Actual: $# Arguments: $@" "$(usage)"

declaredVersion="$(get_tool_config_value "$repoRoot" "$toolName" "DeclaredVersion")"

# Displays the tool path.
display_tool_path()
{
    toolPath="$1"
    toolVersion="$2"
    echo "$toolPath"
    log_message "$repoRoot" "$toolName is available at $toolPath. Version is $toolVersion."
}

# Searches the tool in environment path.
search_environment()
{
    log_message "$repoRoot" "Searching for $toolName in environment path."
    hash "$toolName" 2>/dev/null

    if [ $? -ne 0 ]; then
        return
    fi

    toolPath="$(which $toolName)"
    toolVersion="$(invoke_extension "get-version.sh" "$repoRoot" "$toolName" "$overrideScriptsPath" "$toolPath")"

    if [ "$strictToolVersionMatch" != "strict" ]; then
        # No strictToolVersionMatch. Hence, return the path found without version check.
        display_tool_path "$toolPath" "$toolVersion"
        exit
    fi

    # If strictToolVersionMatch is required then, ensure the version in environment path is same as declared version.
    if [ "$toolVersion" == "$declaredVersion" ]; then
        display_tool_path "$toolPath" "$toolVersion"
        exit
    fi

    log_message "$repoRoot" "Version of $toolName at $toolPath is $toolVersion. This version does not match the declared version $declaredVersion."
}

# Searches the tool in the local tools cache.
search_cache()
{
    log_message "$repoRoot" "Searching for $toolName in local tools cache."
    toolPath="$(get_local_search_path "$repoRoot" "$toolName")"
    toolVersion="$(invoke_extension "get-version.sh" "$repoRoot" "$toolName" "$overrideScriptsPath" "$toolPath")"
    [ "$toolVersion" == "$declaredVersion" ] || fail "$repoRoot" "Unable to locate $toolName neither in environment path nor at $toolPath."
    
    # Declared version of the tool is available within the repository.
    display_tool_path "$toolPath" "$toolVersion"
}

# Begin search in the environment path
search_environment

# Since the tool or the required version was not found in environment, 
# search the tool in the local tools cache specified in the .toolversions file.
search_cache
