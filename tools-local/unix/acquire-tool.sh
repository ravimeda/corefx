#!/usr/bin/env bash

# Downloads the declared version of the specified tool.
# Download URL and package name corresponding to the tool is read from the .toolversions file.
# Arguments:
#   1. Name of the tool

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 ToolName"
    echo "ToolName: Name of the tool to download."
    echo "Downloads the specified tool from the corresponding URL specified in .toolversions file."
    exit 1
fi

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

toolName="$1"
scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
. "$scriptPath/tool-helper.sh"
probeLog="$scriptPath/probe-tool.log"
declaredVersion="$(get_declared_version "$toolName")"


# Downloads the package corresponding to the tool, and extracts the package.
download_extract()
{
    # Get the download URL
    downloadUrl="$(get_download_url "$toolName")"

    if [ $? -ne 0 ]; then
        echo "$downloadUrl"
        exit 1
    fi

    # Get the package name corresponding to the tool, and append the name URL.
    downloadPackageName=$(get_download_package_name "$toolName")
    downloadUrl="$downloadUrl$downloadPackageName"

    # Create folder to save the downloaded package, and extract the package contents.
    repoTools=$(get_repository_tools_downloads_folder "$toolName")
    toolFolder="$repoTools/$toolName"
    rm -rf "$toolFolder"
    mkdir -p "$toolFolder"
    downloadPackagePath="$repoTools/$toolName/$downloadPackageName"

    # Download
    curl --retry 10 -ssl -v -o "$downloadPackagePath" "$downloadUrl" 2> "$toolFolder/download.log"

    # Extract
    tar -xvzf "$downloadPackagePath" -C "$toolFolder" 2> "$toolFolder/expand.log"
}

# Validates if the tool is available at toolPath, and the version of the tool is the declared version.
validate_toolpath()
{
    toolPath="$(get_repository_tool_search_path "$toolName")"
    toolVersion="$("$scriptPath/get-version.sh" "$toolName" "$toolPath")"

    if [ "$toolVersion" != "$declaredVersion" ]; then
        echo "Unable to acquire $toolName"
        exit 1
    fi

    echo "$toolPath"
    echo "$toolVersion"
}


# Download and extract the tool.
download_extract

# Validate the download.
validate_toolpath
