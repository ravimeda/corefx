#!/usr/bin/env bash

# Searches for the specified tool. If tool is not found then, downloads the tool.

usage()
{
    echo ""
    echo "Usage: $0 --ToolName <name> -StrictToolVersionMatch --OverrideScriptsFolderPath <path>"
    echo "  ToolName: Name of the tool to search and/or download."
    echo "  (Optional) -StrictToolVersionMatch: If specified then, search will ensure that the version of the tool searched is the declared version."
    echo "                                      Otherwise, search will attempt to find a version of the tool, which may not be the declared version."
    echo "  (Optional) -OverrideScriptsFolderPath: If specified then, search and acquire scripts from the specified folder path will be invoked."
    echo ""
    echo "Invokes an extension that calls the appropriate search and/or acquire scripts. ToolName and StrictToolVersionMatch are passed on to the extension."
    echo ""
    echo "Example #1"
    echo " probe-tool.sh --ToolName \"cmake\" --StrictToolVersionMatch 0"
    echo " Probes for CMake, not necessarily the declared version, using the default search and acquire scripts located within the repository."
    echo ""
    echo "Example #2"
    echo " probe-tool.sh --ToolName \"cmake\" --StrictToolVersionMatch 1 --OverrideScriptsFolderPath \"/Users/dotnet/MyCustomScripts\""
    echo " Probes for the declared version of CMake using the search and acquire scripts located in \"/Users/dotnet/MyCustomScripts\"."
    echo ""
}

toolName=""
additionalArgs=""
scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
. "$scriptPath/tool-helper.sh"

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
        --toolname)
            shift

            if [ -z "$1" ]; then
                echo "ToolName argument was specified but no tool name was provided. Please specify the name of the tool."
                usage
                exit 1
            fi

            toolName="$1"
            ;;
        -stricttoolversionmatch)
            additionalArgs=$additionalArgs" -StrictToolVersionMatch"
            ;;
        --overridescriptsfolderpath)
            shift

            if [ -z "$1" ] || [ ! -d "$1" ]; then
                echo "OverrideScriptsFolderPath argument was specified but the path provided is invalid. Path: $1"
                usage
                exit 1
            fi

            additionalArgs=$additionalArgs" --OverrideScriptsFolderPath $(cd "$1"; pwd -P)"
            ;;
        *)
            usage
            exit 1
    esac
    shift
done

if [ -z "$toolName" ]; then
    usage
    exit 1
fi

# Search the tool.
log_message "Begin search for $toolName"
toolPath="$("$scriptPath/invoke-extension.sh" "search-tool.sh" "$toolName" $additionalArgs)"

# If search failed then, attempt to download the tool.
if [ $? -ne 0 ]; then
    log_message "Begin acquire for $toolName"
    toolPath="$("$scriptPath/invoke-extension.sh" "acquire-tool.sh" "$toolName" $additionalArgs)"

    if [ $? -ne 0 ]; then
        # Download failed too, and hence return an error message.
        
        echo "$(tool_not_found_message "$toolName")"
        exit 1
    fi
fi

echo "$toolPath"
