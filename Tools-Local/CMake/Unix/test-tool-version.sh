#!/usr/bin/env bash

# Compares the version of the tool executable at the given path with the declared version.

# Exit 1 if executable is not available or if version does not match.

# Arguments:
#       1. tool name.
#       2. tool path.
#       3. Repository root path.

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

if [ -z "$2" ]; then
    echo "Argument passed as tool path is empty. Please provide a non-empty string."
    exit 1
fi

if [ ! -f "$2" ]; then
    echo "tool path does not exist or is not accessible. Path: $1"
    exit 1
fi

if [ -z "$3" ]; then
    echo "Argument passed as root of the repository is empty. Please provide a non-empty string."
    exit 1
fi

if [ ! -d "$3" ]; then
    echo "Repository root path does not exist or is not accessible. Path: $3"
    exit 1
fi

toolName="$1"
toolPath="$2"
repoRoot="$( cd "$3" && pwd )"

declaredVersion=$("$repoRoot/Tools-Local/CMake/Unix/get-declared-tool-version.sh" "$toolName" "$repoRoot")

if [ $? -eq 1 ]; then
    echo "$declaredVersion"
    exit 1
fi

# Check if the version of CMake downloaded matches the declared version.
validate_CMake_version()
{
    if ! echo $("$toolPath" -version) | grep -iq "cmake version $declaredVersion"; then
        echo "Version of the executable located at $toolPath does not match the declared version that is $declaredVersion."
        exit 1
    fi
}

lowerI="$(echo $toolName | awk '{print tolower($0)}')"
case $lowerI in
    "cmake")
        validate_CMake_version
        ;;
    *)
        echo "Unable to test the version of tool named $toolName"
        exit 1
esac
