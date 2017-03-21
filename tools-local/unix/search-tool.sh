#!/usr/bin/env bash

# Locates the specified tool.
# Searches for the tool in the corresponding paths specified in toolversions file.

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

if [[ -z "$2" || "$2" == 0 ]]; then
    strictToolVersionMatch=0
else
    strictToolVersionMatch=1
fi

toolName="$1"
scriptpath=$(cd "$(dirname "$0")"; pwd -P)
repoRoot=$(cd "$scriptpath/../.."; pwd -P)

# Dot source toolversions file.
. "$repoRoot/tools-local/unix/tool-helper.sh"

# Search in environment path
hash $toolName 2>/dev/null

if [ $? -eq 0 ]; then
    toolPath="$(which $toolName)"

    if [ $strictToolVersionMatch == 0 ]; then
        # If found and no strictToolVersionMatch is required then return the path.
        echo "$toolPath"
        exit 0
    else
        # If strictToolVersionMatch is required then, ensure the version in environment path is same as declared version.
        # If version matches then, return the path.   
        $(is-declared-version "$toolName" "$toolPath") 2>/dev/null

        if [ $? -eq 0 ]; then
            # Version available in environment path is the declared version.
            echo "$toolPath"
            exit 0
        fi
    fi
fi

# Search in Tools/downloads folder.
toolPath="$(get-tool-search-path "$toolName")"
$(is-declared-version "$toolName" "$toolPath") 2>/dev/null

if [ $? -eq 0 ]; then
    # Tool is available in Tools/downloads.
    echo "$toolPath"
    exit 0
fi

echo "$toolName is not found."
exit 1
