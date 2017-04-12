#!/usr/bin/env bash

usage()
{
    echo "usage: $0 <script-name> <repository-root> <tool-name> <override-scripts-folder-path> <strict-tool-version-match> <tool-path>"
    echo "script-name                       Name of the extension script."
    echo "repository-root                   Path to repository root."
    echo "tool-name                         Name of the tool."
    echo "override-scripts-folder-path      If a path is specified then, search and acquire scripts from the specified folder will be invoked. Otherwise, search will use the default search and acquire scripts located within the repository."
    echo "strict-tool-version-match         If equals to \"strict\" then, search will ensure that the version of the tool searched is the declared version. Otherwise, search will attempt to find a version of the tool, which may not be the declared version."
    echo "tool-path                         Path to the tool executable."
    echo ""
    echo "Checks if the specified tool has its own implementation of the search or acquire script. If so, invokes the corresponding script. Otherwise, invokes the base implementation."
    echo ""
    echo "Example #1"
    echo "invoke-extension.sh search-tool.sh \"/Users/dotnet/corefx\" cmake """
    echo "Searches for CMake, not necessarily the declared version, using the default search scripts located within the repository."
    echo ""
    echo "Example #2"
    echo "invoke-extension.sh acquire-tool.sh \"/Users/dotnet/corefx\" cmake """
    echo "Acquires the declared version of CMake, using the default search scripts located within the repository."
    echo ""
    echo "Example #3"
    echo "invoke-extension.sh search-tool.sh \"/Users/dotnet/corefx\" cmake \"/Users/dotnet/MyCustomScripts\" strict"
    echo "Searches for the declared version of CMake using the search scripts located in \"/Users/dotnet/MyCustomScripts\"."
    echo ""
    echo "Example #4"
    echo "invoke-extension.sh get-version.sh \"/Users/dotnet/corefx\" cmake "" "" \"/Users/dotnet/corefx/Tools/download/cmake/bin/cmake\" "
    echo "Get the version number of CMake executable located at /Users/dotnet/corefx/Tools/download/cmake/bin/cmake\"."
    echo ""
}

if [ $# -lt 4 ]; then
    usage
    exit 1
fi

extensionScriptName="$1"
repoRoot="$2"
toolName="$3"
overrideScriptsFolderPath="$4"
strictToolVersionMatch="$5"
toolPath="$6"

if [ -z "$extensionScriptName" ]; then
    echo "Argument passed as script-name is empty. Please provide a non-empty string."
    usage
    exit 1
fi

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

if [ ! -z "$overrideScriptsFolderPath" ] &&  [ ! -d "$overrideScriptsFolderPath" ]; then
    echo "Path specified as override-scripts-folder-path does not exist or is not accessible. Path: $overrideScriptsFolderPath"
    usage
    exit 1
fi

if [ ! -z "$toolPath" ] && [ ! -f "$toolPath" ]; then
    echo "Path specified as tool-path does not exist or is not accessible. Path: $toolPath"
    usage
    exit 1
fi

scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
. "$scriptPath/tool-helper.sh"

# Get the appropriate extension script in the folders specified.
#   1. In OverrideScriptsFolderPath check if the tool overrides base implementation
#       a. If yes then, return the path of the override
#       b. If no then, return the path of base implementation
#   2. If OverrideScriptsFolderPath does not exist then, perform 1.a & 1.b in the default scripts folder.
get_extension_script()
{
    for extensionsFolder; do
        if [ ! -d "$extensionsFolder" ]; then
            # Override folder was not specified or does not exist.
            continue
        fi

        invokeScriptPath="$extensionsFolder/$toolName/$extensionScriptName"

        if [ ! -f "$invokeScriptPath" ]; then
            # Tool does not override the base implementation.
            invokeScriptPath="$extensionsFolder/$extensionScriptName"
        fi

        if [ ! -f "$invokeScriptPath" ]; then
            # Unlikely case where the base implementation is also not available.
            echo "Unable to locate $invokeScriptPath"
        fi

        echo "$invokeScriptPath"
        return
    done
}

# Get the appropriate extension script, and invoke the script
invokeScriptPath=$(get_extension_script "$overrideScriptsFolderPath" "$scriptPath")
log_message "$repoRoot" "Invoking $extensionScriptName located in $(dirname $invokeScriptPath) with the following arguments $@"

# Note that the first argument is the name of the extension script. Hence shift and pass rest of the arguments to the script.
shift
"$invokeScriptPath" "$@"
