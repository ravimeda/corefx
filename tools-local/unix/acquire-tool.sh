#!/usr/bin/env bash

# Downloads the specified tool.
# Download URL is read from the .toolversions file.

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

toolName="$1"
toolName="$(echo $toolName | awk '{print tolower($0)}')"
strictToolVersionMatch=0

if [ ! -z "$2" ]; then
    strictToolVersionMatch="$2"
else

# Checks if there is an overridden acquire-tool script.
# If yes then, use that script to acquire the tool.
overriden-acquire-tool()
{
    overrideAcquireToolScriptPath="$toolName/acquire-tool.sh"

    if [[ ! -z "overrideAcquireToolScriptPath" && f "overrideAcquireToolScriptPath" ]]; then
        toolPath="$(overrideAcquireToolScriptPath)"

        if [ $? -ne 0 ]; then
            echo "$toolPath"
            exit 1
        else
            echo "$toolPath"
            exit 0
        fi
    fi
}

# Downloads the package corresponding to the tool.
download-extract()
{
    # Get the download URL
    downloadUrl=$(get-download-url "$toolName")

    if [ $? -ne 0 ]; then
        echo "$downloadUrl"
        exit 1
    fi

    # Get the package name corresponding to the tool.
    downloadPackageName=$(get-download-package-name "$toolName")

    # Create folder to save the downloaded package, and extract the package contents.
    repoTools=$(get-repository-tools-path "$toolName")
    toolFolder="$repoTools/$toolName"
    rm -rf "$toolFolder"
    mkdir -p "$toolFolder"

    # Download
    curl --retry 10 -ssl -v "$repoTools/$toolName/$downloadPackageName" "$downloadUrl" 2> "$repoTools/$toolName/download.log"

    # Extract
    tar -xvzf "$repoTools/$toolName/$downloadPackageName" -C "$repoTools/$toolName" 2> "$repoTools/$toolName/expand.log"

    toolPath="$(get-tool-search-path "$toolName")"
    echo "$toolPath"
}

# Validates if the tool is available at toolPath, and the version of the tool is the declared version.
validate-toolpath()
{
    $(is-declared-version "$toolName" "$toolPath") 2>/dev/null

    if [ $? -ne 0 ]; then
        echo "Unable to acquire $toolName"
        exit 1
    fi
}

# Call overridden acquire-tool script, if any.
overriden-acquire-tool

# Dot source toolversions file.
. "./tool-helper.sh"

# Check if there is a script that overrides download and extract process for the tool.
overriddenDownloadScriptPath="$toolName/download-extract.sh"
if [[ ! -z "overriddenDownloadScriptPath" && f "overriddenDownloadScriptPath" ]]; then
    toolPath="$(overriddenDownloadScriptPath)"
else
    toolPath="$(download-extract)"
fi

# Validate if the downloaded tool is available, and is the declared version. 
validate-toolpath

echo "$toolPath"
