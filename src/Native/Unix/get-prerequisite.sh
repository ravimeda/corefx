#!/usr/bin/env bash

# Downloads the package corresponding to the declared version of the given prerequisite name, 
# and expands the downloaded package to Tools/Downloads/ folder in the repository root.

# Exit 1 if unable to acquire the declared version of the prerequisite.

# Arguments:
#   1. Prerequisite name.
#   2. (Optional) Repository root path. If not specified then, will be determined as 3 levels up the current working folder.
#   3. (Optional) Declared version of the prerequisite. If not specified, declared version will be determined by invoking ./get-declared-prerequisite-version.sh.
#   4. (Optional) URL of the prerequisite package from where the package will be downloaded.

if [ -z "$1" ]; then
    echo "Argument passed as prerequisite name is empty. Please provide a non-empty string."
    exit 1
else
    prerequisiteName="$1"
fi

if [[ ! -z "$2" && -d "$2" ]]; then
    repoRoot="$( cd "$2" && pwd )"
fi

if [ ! -z "$3" ]; then
    declaredVersion="$3"
fi

if [ ! -z "$4" ]; then
    downloadUrl="$4"
fi

# Get declared version.
get_declared_version()
{
    if [ -z "$declaredVersion" ]; then
        declaredVersion=$("$repoRoot/src/Native/Unix/get-declared-prerequisite-version.sh" "$prerequisiteName" "$repoRoot")

        if [ $? -eq 1 ]; then
            echo "$declaredVersion"
            exit 1
        fi
    fi

    echo "Declared version of $prerequisiteName is $declaredVersion"
}

# Determine the package name based on declared version and OS.
get_package_name()
{
    packageName=$("$repoRoot/src/Native/Unix/get-prerequisite-package-name.sh" "$prerequisiteName" "$declaredVersion")

    if [ $? -eq 1 ]; then
        echo "$packageName"
        exit 1
    fi

    packageNameWithExtension=$packageName".tar.gz"
}

# Prepare the URL from where the package can be downloaded.
get_prerequisite_package_url()
{
    # TODO: 
    #   Do not download directly from internet. 
    #   Follow the practice described at https://www.1eswiki.com/wiki/Introducing_OSS_Component_Governance
    #   Likely we will host the prerequisite at https://ossmsft.visualstudio.com/, and the below logic will change.

    if [ -z "$downloadUrl" ]; then
        # Prepare the download URL. For example, https://cmake.org/files/v3.7/cmake-3.7.2-Darwin-x86_64.tar.gz
        # Determine the version fragment. For example v3.7 in https://cmake.org/files/v3.7/cmake-3.7.2-Darwin-x86_64.tar.gz
        urlVersionFragment="v"$(echo $declaredVersion | cut -d '.' -f 1,2)
        downloadUrl="https://cmake.org/files/"$urlVersionFragment"/"$packageNameWithExtension
    fi
}

# Setup folders and files to download, extract, and log.
setup_download_folders()
{
    prerequisitePath=$("$repoRoot/src/Native/Unix/get-repo-prerequisite-path.sh" "$prerequisiteName" "$repoRoot")

    if [ $? -eq 1 ]; then
        echo "$prerequisitePath"
        exit 1
    fi

    downloadsFolder=$(echo $prerequisitePath | awk -F "/$packageName/" '{print $1}')

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
download_prerequisite_package()
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
extract_prerequisite_package()
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
    actualVersion="$("$repoRoot/src/Native/Unix/test-prerequisite-version.sh" "$prerequisiteName" "$prerequisitePath" "$repoRoot")"

    if [ $? -eq 1 ]; then
        echo "$actualVersion"
        exit 1
    fi

    echo "$prerequisiteName version $declaredVersion is at $prerequisitePath."
}

if [ -z "$repoRoot" ]; then
    # Determine repository root path.
    __scriptpath=$(cd "$(dirname "$0")"; pwd -P)
    repoRoot=$(cd "$__scriptpath/../../.."; pwd -P)
fi

lowerI="$(echo $prerequisiteName | awk '{print tolower($0)}')"
case $lowerI in
    "cmake")
        get_declared_version
        get_package_name
        get_prerequisite_package_url
        setup_download_folders
        download_prerequisite_package
        extract_prerequisite_package
        validate_acquistion
        ;;
    *)
        echo "Unable to test the version of prerequisite named $prerequisiteName"
        exit 1
esac
