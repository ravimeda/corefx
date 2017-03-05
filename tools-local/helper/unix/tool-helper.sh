#!/usr/bin/env bash

# Provides helper functions.

# Gets the repository root path.
get-repo-root()
{
    # Determine repository root path.
    __scriptpath=$(cd "$(dirname "$0")"; pwd -P)
    repoRoot=$(cd "$__scriptpath/../../.."; pwd -P)
    echo $repoRoot
}

# Gets the declared version of CMake.
get-declared-version()
{
    if [[ -z "$1" || ! -d "$1" ]]; then
        repoRoot=$(get-repo-root)
    else
        repoRoot="$1"
    fi

    toolsFile="$repoRoot/.toolversions"
    declaredVersion="$(. "$toolsFile"; echo ${CMake})"

    if [ ! -z "$declaredVersion" ]; then
        echo "$declaredVersion"
    else
        echo "Unable to read the declared version of CMake from $toolsFile"
        exit 1
    fi
}

# Gets the CMake package name corresponding to the declared version and the operating system.
get-cmake-package-name()
{
    if [ -z "$1" ]; then
        declaredVersion=$(get-declared-version)
    else
        declaredVersion="$1"
    fi

    if [ -z "$2" ]; then
        operatingSystemName="$(uname -s)"

        if [ -z "$operatingSystemName" ]; then
            echo "Argument passed as operating system name is empty and no operating system name could be detected. Please provide a non-empty string."
            exit 1
        fi
    else
        operatingSystemName="$2"
    fi

    toolName="CMake"

    if [ "$operatingSystemName" == "OSX" ] || $(echo "$operatingSystemName" | grep -iqF "Darwin"); then
        packageSuffix="Darwin-x86_64"
    else
        packageSuffix="Linux-x86_64"
    fi

    echo "cmake-$declaredVersion-$packageSuffix"
}

# Gets the path to Tools-Local\Downloads folder under repository root.
get-repo-downloads-path()
{
    if [[ -z "$1" || ! -d "$1" ]]; then
        repoRoot=$(get-repo-root)
    else
        repoRoot="$( cd "$1" && pwd )"
    fi

    downloadsPath="$repoRoot/Tools/downloads/CMake"
    echo $downloadsPath
}

# Gets the path to CMake executable in Tools\downloads folder under repository root.
get-repo-cmake-path()
{
    if [[ -z "$1" || ! -d "$1" ]]; then
        repoRoot=$(get-repo-root)
    else
        repoRoot="$( cd "$1" && pwd )"
    fi

    toolName="CMake"
    declaredVersion="$2"
    packageName="$3"

    declaredVersion=$(get-declared-version "$repoRoot")

    if [ $? -eq 1 ]; then
        echo "$declaredVersion"
        exit 1
    fi

    packageName=$(get-cmake-package-name "$declaredVersion")

    if [ $? -eq 1 ]; then
        echo "$packageName"
        exit 1
    fi

    toolPath="$repoRoot/Tools/downloads/CMake/$packageName"

    if $(echo "$packageName" | grep -iqF "Darwin"); then
        toolPath="$toolPath/CMake.app/Contents"
    else
        toolPath="$toolPath"
    fi

    toolPath="$toolPath/bin/cmake"

    if [ ! -z "$toolPath" ]; then
        echo "$toolPath"
    else
        echo "Unable to determine the downloads folder path for CMake."
        exit 1
    fi
}

# Compares the version of CMake executable at the specified path with the declared version.
# Exit 1 if version does not match.
test-cmake-version()
{
    if [ -z "$1" ]; then
        echo "Argument passed as tool path is empty. Please provide a non-empty string."
        exit 1
    fi

    if [ ! -f "$1" ]; then
        echo "Tool path does not exist or is not accessible. Path: $1"
        exit 1
    fi

    if [[ -z "$2" || ! -d "$2" ]]; then
        repoRoot=$(get-repo-root)
    else
        repoRoot="$( cd "$2" && pwd )"
    fi

    toolName="CMake"
    toolPath="$1"

    declaredVersion=$(get-declared-version "$repoRoot")

    if [ $? -eq 1 ]; then
        echo "$declaredVersion"
        exit 1
    fi

    # Check if the version of CMake downloaded matches the declared version.
    if ! echo $("$toolPath" -version) | grep -iq "cmake version $declaredVersion"; then
        echo "Version of the executable located at $toolPath does not match the declared version that is $declaredVersion."
        exit 1
    fi
}

is_cmake_path_valid()
{
    if [ -z "$1" ]; then
        echo "Argument passed as tool path is empty. Please provide a non-empty string."
        exit 1
    fi

    if [ ! -f "$1" ]; then
        echo "Tool path does not exist or is not accessible. Path: $1"
        exit 1
    fi

    toolPath="$1"
    strictToolVersionMatch="$2"

    if [ $strictToolVersionMatch -eq 1 ]; then
        $(test-cmake-version "$toolPath") 2>/dev/null

        if [ $? -ne 0 ]; then
            echo "Version of CMake at $toolPath is not the declared version."
            exit 1
        fi
    fi
}