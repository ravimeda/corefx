#!/usr/bin/env bash

usage()
{
    echo "usage: $0 <tool-name> [...]"
    echo "  tool-name: Name of the tool to download."
    echo ""
    echo "Downloads the declared version of the specified tool from the corresponding URL specified in the .toolversions file."
    echo "If download succeeds then, returns the path to the executable."
    echo "Exit 1 if download fails."
}

if [ -z "$1" ]; then
    echo "Argument passed as tool-name is empty. Please provide a non-empty string."
    usage
    exit 1
fi

toolName="$1"
scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
. "$scriptPath/tool-helper.sh"
declaredVersion="$(get_tool_config_value "$toolName" "DeclaredVersion")"


# Downloads the package corresponding to the tool, and extracts the package.
download_extract()
{
    # Get the download URL
    downloadUrl="$(get_tool_config_value "$toolName" "DownloadUrl")"

    if [ $? -ne 0 ]; then
        echo "$downloadUrl"
        exit 1
    fi

    downloadPackageName=$(get_download_package_name "$toolName")

    if [ $? -ne 0 ]; then
        echo "$downloadPackageName"
        exit 1
    fi

    downloadUrl="$downloadUrl$downloadPackageName"

    # Create folder to save the downloaded package, and extract the package contents.
    toolFolder=$(get_repository_tools_downloads_folder "$toolName")
    rm -rf "$toolFolder"
    mkdir -p "$toolFolder"
    downloadPackagePath="$toolFolder/$downloadPackageName"
    log_message "Attempting to download $toolName from $downloadUrl to $downloadPackagePath"

    # curl has HTTPS CA trust-issues less often than wget, so lets try that first.
    which curl > /dev/null 2> /dev/null

    # TODO: Use log_message to write to log file.
    probeLog="$scriptPath/probe-tool.log"

    if [ $? -ne 0 ]; then
        log_message "$(wget --tries=10 -v -O "$downloadPackagePath" "$downloadUrl" 2>&1)"
    else
        log_message "$(curl --retry 10 -ssl -v -o "$downloadPackagePath" "$downloadUrl" 2>&1)"
    fi

    log_message "Attempting to extract $downloadPackagePath to $toolFolder"
    log_message "$(tar -xvzf "$downloadPackagePath" -C "$toolFolder" 2>&1)"
}

# Validates if the tool is available at toolPath, and the version of the tool is the declared version.
validate_toolpath()
{
    toolPath="$(get_repository_tool_search_path "$toolName")"
    toolVersion="$("$scriptPath/invoke-extension.sh" "get-version.sh" "$toolName" "" "" "$toolPath")"

    if [ $? -ne 0 ]; then
        echo "$toolVersion"
        exit 1
    fi

    if [ "$toolVersion" != "$declaredVersion" ]; then
        echo "Version of $toolPath is $toolVersion, which does not match the declared version $declaredVersion"
        exit 1
    fi

    echo "$toolPath"
    log_message "$toolName is available at $toolPath. Version is $toolVersion"
}


# Download and extract the tool.
download_extract

# Validate the download.
validate_toolpath
