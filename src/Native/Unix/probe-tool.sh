#!/usr/bin/env bash

# Searches for the specified tool. If tool is not found then, downloads the tool.
# Paths to search, and download Url is read from the .toolversions file.

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

toolName="$1"

if [ -z "$2" ]; then
    strictToolVersionMatch=0
else
    strictToolVersionMatch="$2"
fi

scriptpath=$(cd "$(dirname "$0")"; pwd -P)
repoRoot=$(cd "$scriptpath/../../.."; pwd -P)

toolPath=$($repoRoot/tools-local/unix/search-tool.sh "$toolName" "$strictToolVersionMatch")

# Validate the path returned from search. 
# If the path is not valid then, download the tool.
if [[ $? -ne 0 || -z "$toolPath" || -f "$toolPath" ]]; then
echo "Downloading..."
    #toolPath=$repoRoot/tools-local/unix/acquire-tool.sh "$toolName"
fi

# Validate the path returned from search or download.
if [[ -z "$toolPath" || ! -f "$toolPath" ]]; then
    # Invalid path. Get the error message.
echo "Error."
    # Dot source helper file.
    . "$repoRoot/tools-local/helper/unix/tool-helper.sh"
    echo $(tool-not-found-message "$toolName")
    
    exit 1
fi

echo $toolPath
