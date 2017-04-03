#!/usr/bin/env bash

# Searches for the specified tool in the environment path, and the path within the repository as specified in the .toolversions file.

usage()
{
    echo "Usage: $0 ToolName [-StrictToolVersionMatch]"
    echo "  ToolName: Name of the tool to download."
    echo "  (Optional) -StrictToolVersionMatch: If specified then, search will ensure that the version of the tool searched is the declared version."
    echo "                                      Otherwise, search will attempt to find a version of the tool, which may not be the declared version."
    echo ""
    echo "Searches for the tool in the environment path, and the path within the repository as specified in the .toolversions file."
    echo "If search is successful then, returns the path to the tool."
    echo "Exit 1 if search fails to find the tool."
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

if [ -z "$1" ]; then
    echo "Argument passed as ToolName is empty. Please provide a non-empty string."
    exit 1
fi

toolName="$1"
shift
strictToolVersionMatch=0

while :; do
    if [ $# -le 0 ]; then
        break
    fi

    lowerI="$(echo $1 | awk '{print tolower($0)}')"
    case $lowerI in
        -stricttoolversionmatch)
            strictToolVersionMatch=1
            ;;
        *)
            usage
            exit 1
    esac
    shift
done

scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
. "$scriptPath/tool-helper.sh"
declaredVersion="$(get_tool_config_value "$toolName" "DeclaredVersion")"


# Displays the tool path, and exits the script.
display_tool_path()
{
    echo "$toolPath"
    log_message "$toolName is available at $toolPath. Version is $toolVersion."
}

# Searches the tool in environment path.
search_environment()
{
    log_message "Searching for $toolName in environment path."
    hash "$toolName" 2>/dev/null

    if [ $? -eq 0 ]; then
        toolPath="$(which $toolName)"
        toolVersion="$("$scriptPath/invoke-extension.sh" "get-version.sh" "$toolName" --ToolPath "$toolPath")"

        if [ $strictToolVersionMatch -eq 0 ]; then
            # No strictToolVersionMatch. Hence, return the path found without further checks.
            display_tool_path
            exit
        else
            # If strictToolVersionMatch is required then, ensure the version in environment path is same as declared version.
            # If version matches then, return the path.
            if [ "$toolVersion" == "$declaredVersion" ]; then
                # Version available in environment path is the declared version.
                display_tool_path
                exit
            fi
        fi

        log_message "Version of $toolName at $toolPath is $toolVersion. This version does not match the declared version $declaredVersion."
    fi
}

# Searches the tool within the repository.
search_repository()
{
    log_message "Searching for $toolName within the repository."
    toolPath="$(get_repository_tool_search_path "$toolName")"
    toolVersion="$("$scriptPath/invoke-extension.sh" "get-version.sh" "$toolName" --ToolPath "$toolPath")"

    if [ "$toolVersion" == "$declaredVersion" ]; then
        # Declared version of the tool is available within the repository.
        display_tool_path
        exit
    fi

    echo "Unable to locate $toolName"
    exit 1
}


# Search in the environment path
search_environment

# Search within the repository in the path specified in the .toolversions file.
search_repository
