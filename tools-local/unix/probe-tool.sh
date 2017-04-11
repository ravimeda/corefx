#!/usr/bin/env bash

usage()
{
    echo "usage: $0 <repository-root> <tool-name> <override-scripts-folder-path> <strict-tool-version-match>"
    echo "  repository-root: Path to repository root."
    echo "  tool-name: Name of the tool to search and/or download."
    echo "  override-scripts-folder-path: If a path is specified then, search and acquire scripts from the specified folder will be invoked."
    echo "                                  Otherwise, search will use the default search and acquire scripts located within the repository."
    echo "  strict-tool-version-match: If equals to \"strict\" then, search will ensure that the version of the tool searched is the declared version."
    echo "                              Otherwise, search will attempt to find a version of the tool, which may not be the declared version."
    echo ""
    echo "Invokes an extension that calls the appropriate search and/or acquire scripts. ToolName and StrictToolVersionMatch are passed on to the extension."
    echo ""
    echo "Example #1"
    echo "probe-tool.sh \"/Users/dotnet/corefx\" cmake "" """
    echo " Probes for CMake, not necessarily the declared version, using the default search and acquire scripts located within the repository."
    echo ""
    echo "Example #2"
    echo "probe-tool.sh \"/Users/dotnet/corefx\" cmake "" strict"
    echo " Probes for the declared version of CMake using the default search and acquire scripts located within the repository."
    echo ""
    echo "Example #3"
    echo "probe-tool.sh \"/Users/dotnet/corefx\" cmake \"/Users/dotnet/MyCustomScripts\" strict"
    echo " Probes for the declared version of CMake using the search and acquire scripts located in \"/Users/dotnet/MyCustomScripts\"."
    echo ""
}

if [ $# -ne 4 ]; then
    usage
    exit 1
fi

repoRoot="$(cd "$1"; pwd -P)"
toolName="$2"
overrideScriptsFolderPath="$3"
strictToolVersionMatch="$4"

if [ -z "$repoRoot" ]; then
    echo "Argument passed as repository-root is empty. Please provide a non-empty string."
    usage
    exit 1
fi

if [ -z "$toolName" ]; then
    echo "Argument passed as tool-name is empty. Please provide a non-empty string."
    usage
    exit 1
fi

if [ ! -d "$overrideScriptsFolderPath" ]; then
    echo "Path specified as override-scripts-folder-path does not exist or is not accessible. Path: $3"
    usage
    exit 1
fi

scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
. "$scriptPath/tool-helper.sh"

# Search the tool.
log_message "$repoRoot" "Begin search for $toolName"
toolPath="$("$scriptPath/invoke-extension.sh" "search-tool.sh" "$repoRoot" "$toolName" "$overrideScriptsFolderPath" "$strictToolVersionMatch")"

# If search failed then, attempt to download the tool.
if [ $? -ne 0 ]; then
    log_message "$repoRoot" "Begin acquire for $toolName"
    toolPath="$("$scriptPath/invoke-extension.sh" "acquire-tool.sh" "$repoRoot" "$toolName" "$overrideScriptsFolderPath")"

    if [ $? -ne 0 ]; then
        # Download failed too, and hence return an error message.
        tool_not_found_message "$repoRoot" "$toolName"
        exit 1
    fi
fi

echo "$toolPath"
