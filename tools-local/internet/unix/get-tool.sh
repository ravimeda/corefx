#!/usr/bin/env bash

# Downloads the package corresponding to the declared version of the specified tool, 
# and expands the downloaded package to Tools/downloads folder in the repository root.

# Exit 1 if unable to acquire the declared version of the tool.

# Arguments:
#   1. Name of the tool.
#   2. Declared version of the tool.

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
else
    toolName="$1"
fi

if [ -z "$2" ]; then
    echo "Argument passed as declared version is empty. Please provide a non-empty string."
    exit 1
else
    declaredVersion="$2"
fi

# Determine repository root path.
scriptpath=$(cd "$(dirname "$0")"; pwd -P)
repoRoot=$(cd "$scriptpath/../../.."; pwd -P)

# Dot source the helper functions file.
. "$repoRoot/tools-local/helper/unix/tool-helper.sh"

# Determine the package name based on declared version and OS.
get_package_name()
{
    packageName=$(get-cmake-package-name "$declaredVersion")

    if [ $? -eq 1 ]; then
        echo "$packageName"
        exit 1
    fi

    packageNameWithExtension=$packageName".tar.gz"
}

# Prepare the URL from where the package can be downloaded.
get_tool_package_url()
{
    # Prepare the download URL. For example, https://cmake.org/files/v3.7/cmake-3.7.2-Darwin-x86_64.tar.gz
    # Determine the version fragment. For example v3.7 in https://cmake.org/files/v3.7/cmake-3.7.2-Darwin-x86_64.tar.gz
    urlVersionFragment="v"$(echo $declaredVersion | cut -d '.' -f 1,2)
    downloadUrl="https://cmake.org/files/"$urlVersionFragment"/"$packageNameWithExtension
}

# Setup folders and files to download, extract, and log.
setup_download_folders()
{
    toolPath=$(get-repo-cmake-path "$repoRoot")

    if [ $? -eq 1 ]; then
        echo "$toolPath"
        exit 1
    fi

    downloadsFolder=$(echo $toolPath | awk -F "/$packageName/" '{print $1}')

    if [ -z "$downloadsFolder" ]; then
        echo "Unable to determine the downloads folder path."
        exit 1
    fi
    
    # Prepare the local download folder.
    if [ -d "$downloadsFolder" ]; then
        rm -rf "$downloadsFolder"
    fi

    mkdir -p "$downloadsFolder"
    downloadLogFile="$downloadsFolder/download.log"
}

# Perform the download.
download_tool_package()
{
    # Attempt download.
    echo "Attempting to download CMake package from $downloadUrl to $downloadsFolder"
    curl --retry 10 -sSL -v --create-dirs -o "$downloadsFolder/$packageNameWithExtension" "$downloadUrl" 2> "$downloadLogFile"

    if [ $? -eq 1 ]; then
        echo "Download failed. See $downloadLogFile for more details on this failure."
        exit 1
    fi

    echo "Download successful."
}

# Extract the downloaded package.
extract_tool_package()
{
    # Attempt package extraction.
    echo "Attempting to extract $packageNameWithExtension to $downloadsFolder"
    tar -xvzf "$downloadsFolder/$packageNameWithExtension" -C "$downloadsFolder" 2> "$downloadsFolder/expand.log"

    if [ $? -eq 1 ]; then
        echo "Extraction failed. See $downloadsFolder/expand.log for more details on this failure."
        exit 1
    fi

    echo "Extraction successful."
}

# Ensure that the declared version of CMake executable is available in the downloads folder.
validate_acquistion()
{
    # Check if the version of CMake executable matches the declared version.
    actualVersion="$(test-cmake-version "$toolPath" "$repoRoot")"

    if [ $? -eq 1 ]; then
        echo "$actualVersion"
        exit 1
    fi

    echo "$toolName version $declaredVersion is at $toolPath."
}


lowerI="$(echo $toolName | awk '{print tolower($0)}')"
case $lowerI in
    "cmake")
        get_package_name
        get_tool_package_url
        setup_download_folders
        download_tool_package
        extract_tool_package
        validate_acquistion
        ;;
    *)
        echo "Tool is not supported. Tool name: $toolName"
        exit 1
esac
