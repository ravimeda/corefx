#!/usr/bin/env bash

usage()
{
    echo ""
    echo "usage: $0 <repository-root> <tool-name> <override-scripts-folder-path> <strict-tool-version-match>"
    echo "repository-root                   Path to repository root."
    echo "tool-name                         Name of the tool to search and/or download."
    echo "override-scripts-folder-path      If a path is specified then, search and acquire scripts from the specified folder will be invoked."
    echo "                                  Otherwise, search will use the default search and acquire scripts located within the repository."
    echo "strict-tool-version-match         If equals to \"strict\" then, search will ensure that the version of the tool searched is the declared version."
    echo "                                  Otherwise, search will attempt to find a version of the tool, which may not be the declared version."
    echo ""
    echo "Invokes an extension that calls the appropriate search and/or acquire scripts."
    echo "tool-name, override-scripts-folder-path and strict-tool-version-match are passed on to the extension."
    echo ""
    echo "Example #1"
    echo "probe-tool.sh \"/Users/dotnet/corefx\" cmake "" """
    echo "Probes for CMake, not necessarily the declared version, using the default search and acquire scripts located within the repository."
    echo ""
    echo "Example #2"
    echo "probe-tool.sh \"/Users/dotnet/corefx\" cmake "" strict"
    echo "Probes for the declared version of CMake using the default search and acquire scripts located within the repository."
    echo ""
    echo "Example #3"
    echo "probe-tool.sh \"/Users/dotnet/corefx\" cmake \"/Users/dotnet/MyCustomScripts\" strict"
    echo "Probes for the declared version of CMake using the search and acquire scripts located in \"/Users/dotnet/MyCustomScripts\"."
    echo ""
}

repoRoot="$1"
toolName="$2"
overrideScriptsFolderPath="$3"
strictToolVersionMatch="$4"

scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
. "$scriptPath/tool-helper.sh"

exit_if_invalid_path "repository-root" "$repoRoot" "$(usage)"
exit_if_arg_empty "tool-name" "$toolName" "$(usage)"

# If an override path is specified then, ensure the folder exists.
if [ ! -z "$overrideScriptsFolderPath" ]; then
    [ -d "$overrideScriptsFolderPath" ] || 
    fail "$repoRoot" "Path specified as override-scripts-folder-path does not exist or is not accessible. Path: $overrideScriptsFolderPath" "$(usage)"
fi

[ $# -eq 4 ] || fail "$repoRoot" "Invalid number of arguments. Expected: 4 Actual: $# Arguments: $@" "$(usage)"
repoRoot="$(cd "$repoRoot"; pwd -P)"

# Search the tool.
toolPath="$(invoke_extension "search-tool.sh" "$repoRoot" "$toolName" "$overrideScriptsFolderPath" "$strictToolVersionMatch")"

# If search failed then, attempt to download the tool.
if [ $? -ne 0 ]; then
    toolPath="$(invoke_extension "acquire-tool.sh" "$repoRoot" "$toolName" "$overrideScriptsFolderPath")"

    if [ $? -ne 0 ]; then
        # Download failed too, and hence return an error message.
        # Note that invokeScript and invokeScriptArgs are used in ToolNotFoundErrorMessage.
        invokeScript="$scriptPath/acquire-tool.sh"
        invokeScriptArgs="\"$repoRoot\" \"$toolName\" \"$overrideScriptsFolderPath\""

        tool_not_found_message "$repoRoot" "$toolName"
        exit 1
    fi
fi

echo "$toolPath"
