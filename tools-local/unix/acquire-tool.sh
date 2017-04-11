#!/usr/bin/env bash

usage()
{
    echo "usage: $0 <repository-root> <tool-name> <override-scripts-folder-path>"
    echo "  repository-root: Path to repository root."
    echo "  tool-name: Name of the tool to download."
    echo "  override-scripts-folder-path: If a path is specified then, scripts from the specified folder will be invoked."
    echo "                                  Otherwise, the default scripts located within the repository will be invoked."
    echo ""
    echo "Downloads the declared version of the specified tool from the corresponding URL specified in the .toolversions file."
    echo "If download succeeds then, returns the path to the executable."
    echo "Exit 1 if download fails."
}

repoRoot="$1"
toolName="$2"
overrideScriptsPath="$3"

if [ -z "$repoRoot" ]; then
    echo "Argument passed as repository-root is empty. Please provide a non-empty string."
    usage
    exit 1
fi

if [ -z "$toolName" ]; then
    echo "Argument passed as tool-name is empty. Please provide a non-empty string."
    usage
    exit 1
fi

scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
. "$scriptPath/tool-helper.sh"
declaredVersion="$(get_tool_config_value "$repoRoot" "$toolName" "DeclaredVersion")"


# Downloads the package corresponding to the tool, and extracts the package.
download_extract()
{
    # Get the download URL
    downloadUrl="$(get_tool_config_value "$repoRoot" "$toolName" "DownloadUrl")"

    if [ $? -ne 0 ]; then
        echo "$downloadUrl"
        exit 1
    fi

    downloadPackageFilename=$(get_download_package_name "$repoRoot" "$toolName")

    if [ $? -ne 0 ]; then
        echo "$downloadPackageFilename"
        exit 1
    fi

    downloadUrl="$downloadUrl$downloadPackageFilename"

    # Create folder to save the downloaded package, and extract the package contents.
    toolFolder="$(get_tool_config_value "$repoRoot" "$toolName" "LocalToolFolder")"
    rm -rf "$toolFolder"
    mkdir -p "$toolFolder"
    downloadPackagePath="$toolFolder/$downloadPackageFilename"
    log_message "Attempting to download $toolName from $downloadUrl to $downloadPackagePath"

    # curl has HTTPS CA trust-issues less often than wget, so lets try that first.
    which curl > /dev/null 2> /dev/null

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
    toolPath="$(get_local_search_path "$repoRoot" "$toolName")"
    toolVersion="$("$scriptPath/invoke-extension.sh" "get-version.sh" "$repoRoot" "$toolName" "$overrideScriptsPath" "" "$toolPath")"

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
