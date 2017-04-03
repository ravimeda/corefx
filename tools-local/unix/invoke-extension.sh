#!/usr/bin/env bash

# Locates and invokes the given extension script, which does a search or acquire, with the specified arguments. 

usage()
{
    echo "Usage: $0 ScriptName ToolName -StrictToolVersionMatch --OverrideScriptsFolderPath <path>"
    echo "  ScriptName: Name of the search or acquire script."
    echo "  ToolName: Name of the tool to search and/or download."
    echo "  (Optional) -StrictToolVersionMatch: If specified then, search will ensure that the version of the tool searched is the declared version."
    echo "                                      Otherwise, search will attempt to find a version of the tool, which may not be the declared version."
    echo "  (Optional) -OverrideScriptsFolderPath: If specified then, search and acquire scripts from the specified folder path will be invoked."
    echo ""
    echo "Checks if the specified tool has its own implementation of the search or acquire script. If so, invokes the corresponding script. Otherwise, invokes the base implementation."
    echo ""
    echo "Example #1"
    echo "invoke-extension.sh \"search-tool.sh\" \"cmake\" -StrictToolVersionMatch"
    echo "  Searches for the declared version of CMake using the default search scripts located within the repository."
    echo ""
    echo "Example #2"
    echo "invoke-extension.sh \"acquire-tool.sh\" \"cmake\" -StrictToolVersionMatch --OverrideScriptsFolderPath=\"/Users/dotnet/MyCustomScripts\""
    echo "  Acquires the declared version of CMake using the acquire script located in the specified folder that is \"/Users/dotnet/MyCustomScripts\"."
    echo ""
}

if [ $# -lt 2 ]; then
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


extensionScriptName="$1"
shift
toolName="$1"
shift
strictToolVersionMatch=0
overrideScriptsFolderPath=""
additionalArgs=""

while :; do
    if [ $# -le 0 ]; then
        break
    fi

    lowerI="$(echo $1 | awk '{print tolower($0)}')"
    case $lowerI in
        -stricttoolversionmatch)
            strictToolVersionMatch=1
            ;;
        --overridescriptsfolderpath)
            shift

            if [ -z "$1" ] || [ ! -d "$1" ]; then
                echo "OverrideScriptsFolderPath argument was specified but the path provided is invalid. Path: $1"
                usage
                exit 1
            fi

            overrideScriptsFolderPath="$(cd "$1"; pwd -P)"
            ;;
        --toolpath)
            shift

            if [ -z "$1" ]; then
                echo "ToolPath argument was specified but the path provided is empty."
                usage
                exit 1
            fi

            additionalArgs=$additionalArgs" --ToolPath $1"
            ;;
        *)
            usage
            exit 1
    esac
    shift
done

scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
. "$scriptPath/tool-helper.sh"


# Locates the appropriate extension script in the folders specified.
#   1. In OverrideScriptsFolderPath check if the tool overrides base implementation. 
#       a. If yes then, invoke the override, and return.
#       b. If no then, invoke the base implementation, and return.
#   2. If OverrideScriptsFolderPath does not exist then, perform 1.a & 1.b in the default scripts folder.
invoke_extension_script()
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

        args="$toolName $additionalArgs"

        if [ $strictToolVersionMatch -eq 1 ] ; then
            args="$toolName -StrictToolVersionMatch $additionalArgs"
        fi

        log_message "Invoking $extensionScriptName located in $(dirname $invokeScriptPath) with the following arguments $args"
        "$invokeScriptPath" $args
        exit $?
    done
}

# Invoke the appropriate extension that performs the search or acquire.
# Search in OverrideScriptsFolderPath first and then default scripts folder, which is located within the repository.
invoke_extension_script $overrideScriptsFolderPath $scriptPath
