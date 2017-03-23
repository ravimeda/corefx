#!/usr/bin/env bash

# Searches the for the specified tool. If tool is not found then, downloads the tool.
# Paths to search, and download URL is read from the .toolversions file.

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

toolName="$1"
strictToolVersionMatch=0

if [ ! -z "$2" ]; then
    strictToolVersionMatch="$2"
fi

scriptpath="$(cd "$(dirname "$0")"; pwd -P)"
repoRoot="$(cd "$scriptpath/../.."; pwd -P)"
shellScriptsRoot="$repoRoot/tools-local/unix"

# Search for the tool.
toolPath=$("$shellScriptsRoot/search-tool.sh" "$toolName" "$strictToolVersionMatch")

# Check if search returned: 
#   1. An error message
#   2. An empty string
#   3. File does not exist at the returned tool path.
# If either of the above conditions is true then, attempt to download the tool.
if [[ $? -ne 0 || -z "$toolPath" || ! -f "$toolPath" ]]; then
    toolPath=$("$shellScriptsRoot/acquire-tool.sh" "$toolName")
fi

# Validate the path returned from search or download.
if [[ -z "$toolPath" || ! -f "$toolPath" ]]; then
    # Invalid path. Display error message, and exit.

    # Dot source helper file.
    . "$shellScriptsRoot/tool-helper.sh"

    echo $(tool_not_found_message "$toolName")
    exit 1
fi

echo "$toolPath"
