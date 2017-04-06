#!/usr/bin/env bash

usage()
{
    echo "usage: $0 <script-name> <tool-name> <override-scripts-folder-path> [strict-tool-version-match] [tool-path]"
    echo "  script-name: Name of the extension script."
    echo "  tool-name: Name of the tool."
    echo "  override-scripts-folder-path: If a path is specified then, search and acquire scripts from the specified folder will be invoked."
    echo "                                  Otherwise, search will use the default search and acquire scripts located within the repository."
    echo "  (Optional) strict-tool-version-match: If equals to \"strict\" then, search will ensure that the version of the tool searched is the declared version."
    echo "                                          Otherwise, search will attempt to find a version of the tool, which may not be the declared version."
    echo "  (Optional) tool-path: Path to the tool executable."
    echo ""
    echo "Checks if the specified tool has its own implementation of the search or acquire script. If so, invokes the corresponding script. Otherwise, invokes the base implementation."
    echo ""
    echo "Example #1"
    echo "invoke-extension.sh \"search-tool.sh\" \"cmake\" -strict"
    echo "  Searches for the declared version of CMake using the default search scripts located within the repository."
    echo ""
    echo "Example #2"
    echo "invoke-extension.sh \"acquire-tool.sh\" \"cmake\" strict \"/Users/dotnet/MyCustomScripts\""
    echo "  Acquires the declared version of CMake using the acquire script located in the specified folder that is \"/Users/dotnet/MyCustomScripts\"."
    echo ""
}

if [ $# -lt 3 ]; then
    usage
    exit 1
fi

if [ -z "$1" ]; then
    echo "Argument passed as script-name is empty. Please provide a non-empty string."
    usage
    exit 1
fi

if [ -z "$2" ]; then
    echo "Argument passed as tool-name is empty. Please provide a non-empty string."
    usage
    exit 1
fi

if [ ! -z "$3" ] && [ ! -d "$3" ]; then
    echo "Path specified as override-scripts-folder-path does not exist or is not accessible. Path: $3"
    usage
    exit 1
fi

if [ ! -z "$5" ] && [ ! -f "$5" ]; then
    echo "Path specified as tool-path does not exist or is not accessible. Path: $5"
    usage
    exit 1
fi

extensionScriptName="$1"
shift

toolName="$1"
overrideScriptsFolderPath="$2"
strictToolVersionMatch="$3"

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
        if [ -z "$extensionsFolder" ] || [ ! -d "$extensionsFolder" ]; then
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
            exit 1
        fi

        echo "$invokeScriptPath"
        return
    done
}

# Get the appropriate extension script, and invoke the script
invokeScriptPath=$(get_extension_script "$overrideScriptsFolderPath" "$scriptPath")
log_message "Invoking $extensionScriptName located in $(dirname $invokeScriptPath) with the following arguments $@"
"$invokeScriptPath" "$@"
exit $?
