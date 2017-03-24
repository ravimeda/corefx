#!/usr/bin/env bash

# Downloads the declared version of the specified tool.
# Download URL and package name corresponding to the tool is read from the .toolversions file.
# Arguments:
#   1. Name of the tool

if [ "?#" -ne 1 ]; then
    echo "Usage: $0 ToolName"
    echo "          ToolName: Name of the tool"
fi

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

toolName="$1"

# Downloads the package corresponding to the tool, and extracts the package.
download_extract()
{
    # Get the download URL
    downloadUrl="$(get_download_url "$toolName")"

    if [ $? -ne 0 ]; then
        echo "$downloadUrl"
        exit 1
    fi

    # Get the package name corresponding to the tool.
    downloadPackageName=$(get_download_package_name "$toolName")

    # Create folder to save the downloaded package, and extract the package contents.
    repoTools=$(get_repository_tools_downloads_folder "$toolName")
    toolFolder="$repoTools/$toolName"
    rm -rf "$toolFolder"
    mkdir -p "$toolFolder"

    # Download
    curl --retry 10 -ssl -v --output "$repoTools/$toolName/$downloadPackageName" "$downloadUrl$downloadPackageName" 2> "$repoTools/$toolName/download.log"

    # Extract
    tar -xvzf "$repoTools/$toolName/$downloadPackageName" -C "$repoTools/$toolName" 2> "$repoTools/$toolName/expand.log"

    toolPath="$(get_repository_tool_search_path "$toolName")"
    echo "$toolPath"
}

# Validates if the tool is available at toolPath, and the version of the tool is the declared version.
validate_toolpath()
{
    if ! is_declared_version "$toolName" "$toolPath"; then
        echo "Unable to acquire $toolName"
        exit 1
    fi
}


scriptpath="$(cd "$(dirname "$0")"; pwd -P)"
repoRoot="$(cd "$scriptpath/../.."; pwd -P)"
. "$scriptpath/tool-helper.sh"
toolPath=""

# Download and extract the tool.
download_extract

# Validate the download.
validate_toolpath

echo "$toolPath"
