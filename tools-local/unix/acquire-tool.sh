#!/usr/bin/env bash

# Downloads the specified tool.
# Download URL is read from the .toolversions file.

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

toolName="$1"
scriptpath=$(cd "$(dirname "$0")"; pwd -P)
repoRoot=$(cd "$scriptpath/../.."; pwd -P)

# Dot source toolversions file.
. $repoRoot/.toolversions

eval "tools=\$$toolName"
eval "$tools"

# Dot source helper file.
. $repoRoot/tools-local/unix/tool-helper.sh

# Get download URL
# Can there be multiple download locations?
downloadUrl=$(get-download-url "$toolName")

# Get the path to save the downloaded package.
downloadPackageName=$(get-download-package-name "$toolName")

# Download
repoTools=$(get-repository-tools-path "$toolName")
mkdir -p "$repoTools/$toolName"

curl --retry 10 -ssl -v --create-dirs -o "$repoTools/$toolName/$downloadPackageName" "$downloadUrl" 2> "$repoTools/$toolName/download.log"

# Extract
tar -xvzf "$repoTools/$toolName/$downloadPackageName" -C "$repoTools/$toolName" 2> "$repoTools/$toolName/expand.log"

# Validate
toolPath="$(get-tool-search-path "$toolName")"
$(is-declared-version "$toolName" "$toolPath")

if [ $? -ne 0 ]; then
    echo "Unable to acquire $toolName"
    exit 1
fi

echo "$toolPath"
