#!/usr/bin/env bash

# Searches the for the specified tool. If tool is not found then, downloads the tool.
# Paths to search, and download URL is read from the .toolversions file.

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

if [ -z "$2" ]; then
    strictToolVersionMatch=0
else
    strictToolVersionMatch="$2"
fi

toolName="$1"
scriptpath=$(cd "$(dirname "$0")"; pwd -P)
repoRoot=$(cd "$scriptpath/../../.."; pwd -P)

# Dot source helper file.
. "$repoRoot/tools-local/unix/tool-helper.sh"

# Search for the tool.
toolPath=$("$repoRoot/tools-local/unix/search-tool.sh" "$toolName" "$strictToolVersionMatch")

# Check if search: 
#   1. Returned an error
#   2. Returned tool path is an empty string
#   3. File does not exist at the returned tool path.
# If either of the above conditions is true then, attempt to download the tool.
if [[ $? -ne 0 || -z "$toolPath" || ! -f "$toolPath" ]]; then
    toolPath=$("$repoRoot/tools-local/unix/acquire-tool.sh" "$toolName")
fi

# Validate the path returned from search or download.
if [[ -z "$toolPath" || ! -f "$toolPath" ]]; then
    # Invalid path. Display error message, and exit.
    echo $(tool-not-found-message "$toolName")
    exit 1
fi

echo "$toolPath"
