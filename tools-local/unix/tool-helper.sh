#!/usr/bin/env bash

# Provides helper functions.

# Gets the repository root path.
get-repo-root()
{
    scriptpath=$(cd "$(dirname "$0")"; pwd -P)
    repoRoot=$(cd "$scriptpath/../../.."; pwd -P)
    echo $repoRoot
}

# Gets the declared version of the specified tool.
# Exit 1 if unable to read declared version of the tool from .toolversions file.
get-declared-version()
{
    if [ -z "$1" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    toolName="$1"
    repoRoot=$(get-repo-root)

    # Dot source toolversions file.
    . $repoRoot/.toolversions

    eval "tools=\$$toolName"
    eval "$tools"

    if [ -z "$DeclaredVersion" ]; then
        echo "Unable to read the declared version for $toolName."
        exit 1
    fi

    echo $DeclaredVersion
}

# Compares the version of the tool at the specified path with the declared version of the tool.
# Exit 1 if the tool does not exist at the given path or the version does match.
is-declared-version()
{
    if [ -z "$1" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    toolName="$1"
    lowerI="$(echo $toolName | awk '{print tolower($0)}')"

    case $lowerI in
        "cmake")
            is-cmake-declared-version "$2"
            ;;
        *)
            echo "Tool is not supported. Tool name: $toolName"
            exit 1
    esac
}

# Compares the version of CMake executable at the specified path with the declared version.
# Exit 1 if the executable does not exist or the version does not match.
is-cmake-declared-version()
{
    if [ -z "$1" ]; then
        echo "Argument passed as CMake path is empty. Please provide a non-empty string."
        exit 1
    fi

    if [ ! -f "$1" ]; then
        echo "CMake path does not exist or is not accessible. Path: $1"
        exit 1
    fi

    toolPath="$1"
    declaredVersion=$(get-declared-version "CMake")

    if [ $? -eq 1 ]; then
        echo "$declaredVersion"
        exit 1
    fi

    # Check if the version of CMake matches the declared version.
    if ! echo $("$toolPath" -version) | grep -iq "cmake version $declaredVersion"; then
        echo "Version of the executable located at $toolPath does not match the declared version that is $declaredVersion."
        exit 1
    fi
}

# Gets the error message to be displayed when the specified tool is not available for the build.
tool-not-found-message()
{
    if [ -z "$1" ]; then
        echo "Argument passed as tool name is empty. Please provide a non-empty string."
        exit 1
    fi

    toolName="$1"
    lowerI="$(echo $toolName | awk '{print tolower($0)}')"
    
    case $lowerI in
        "cmake")
            cmake-not-found-message
            ;;
        *)
            echo "Tool is not supported. Tool name: $toolName"
            exit 1
    esac
}

cmake-not-found-message()
{
    repoRoot=$(get-repo-root)
    declaredVersion=$(get-declared-version "CMake")
    
    if [ $? -eq 1 ]; then
        echo "$declaredVersion"
        exit 1
    fi

    echo >&2 "CMake is a tool to build this repository but it was not found on the path. Please try one of the following options to acquire CMake version $declaredVersion:"
    echo >&2 "      1. Install CMake version $declaredVersion from https://cmake.org/files/"
    echo >&2 "      2. Run the script $repoRoot/tools-local/unix/acquire-tool.sh "CMake""    
}
