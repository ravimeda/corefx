#!/usr/bin/env bash

usage()
{
    echo "usage: $0 <repository-root> <tool-name> <override-scripts-folder-path>"
    echo "repository-root                   Path to repository root."
    echo "tool-name                         Name of the tool to download."
    echo "override-scripts-folder-path      If a path is specified then, scripts from the specified folder will be invoked."
    echo "                                  Otherwise, the default scripts located within the repository will be invoked."
    echo ""
    echo "Downloads the declared version of the specified tool from the corresponding URL specified in the .toolversions file."
    echo "If download succeeds then, returns the path to the executable."
    echo "Exit 1 if download fails."
}

if [ $# -ne 3 ]; then
    usage
    exit 1
fi

repoRoot="$1"
toolName="$2"
overrideScriptsPath="$3"

scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
. "$scriptPath/tool-helper.sh"

exit_if_arg_empty "repository-root" "$repoRoot"
exit_if_arg_empty "tool-name" "$toolName"

declaredVersion="$(get_tool_config_value "$repoRoot" "$toolName" "DeclaredVersion")"

# Downloads the package corresponding to the tool, and extracts the package.
download_extract()
{
    # Get the download URL
    downloadUrl="$(get_tool_config_value "$repoRoot" "$toolName" "DownloadUrl")" || fail "$repoRoot" "$downloadUrl"
    downloadPackageFilename=$(get_download_file "$repoRoot" "$toolName") || fail "$repoRoot" "$downloadPackageFilename"
    downloadUrl="$downloadUrl$downloadPackageFilename"

    # Create folder to save the downloaded package, and extract the package contents.
    toolFolder="$(get_local_tool_folder "$repoRoot" "$toolName")"
    rm -rf "$toolFolder"
    mkdir -p "$toolFolder"
    downloadPackagePath="$toolFolder/$downloadPackageFilename"
    log_message "$repoRoot" "Attempting to download $toolName from $downloadUrl to $downloadPackagePath."

    # curl has HTTPS CA trust-issues less often than wget, so lets try that first.
    which curl > /dev/null 2> /dev/null

    if [ $? -ne 0 ]; then
        log_message "$repoRoot" "$(wget --tries=10 -v -O "$downloadPackagePath" "$downloadUrl" 2>&1)"
    else
        log_message "$repoRoot" "$(curl --retry 10 -ssl -v -o "$downloadPackagePath" "$downloadUrl" 2>&1)"
    fi

    log_message "$repoRoot" "Attempting to extract $downloadPackagePath to $toolFolder."
    log_message "$repoRoot" "$(tar -xvzf "$downloadPackagePath" -C "$toolFolder" 2>&1)"
}

# Validates if the tool is available at toolPath, and the version of the tool is the declared version.
validate_toolpath()
{
    toolPath="$(get_local_search_path "$repoRoot" "$toolName")"
    toolVersion="$(invoke_extension "get-version.sh" "$repoRoot" "$toolName" "$overrideScriptsPath" "$toolPath")" || fail "$repoRoot" "$toolVersion"

    if [ "$toolVersion" != "$declaredVersion" ]; then
        echo "Version of $toolPath is $toolVersion, which does not match the declared version $declaredVersion."
        exit 1
    fi

    echo "$toolPath"
    log_message "$repoRoot" "$toolName is available at $toolPath. Version is $toolVersion."
}

# Download and extract the tool.
download_extract

# Validate the download.
validate_toolpath
