#!/usr/bin/env bash

# Compares the version of the prerequisite executable at the given path with the declared version.

# Exit 1 if executable is not available or if version does not match.

# Arguments:
#       1. Prerequisite name.
#       2. Prerequisite path.
#       3. Repository root path.

if [ -z "$1" ]; then
    echo "Argument passed as prerequisite name is empty. Please provide a non-empty string."
    exit 1
fi

if [ -z "$2" ]; then
    echo "Argument passed as prerequisite path is empty. Please provide a non-empty string."
    exit 1
fi

if [ ! -f "$2" ]; then
    echo "Prerequisite path does not exist or is not accessible. Path: $1"
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

prerequisiteName="$1"
prerequisitePath="$2"
repoRoot="$( cd "$3" && pwd )"

declaredVersion=$("$repoRoot/src/Native/Unix/get-declared-prerequisite-version.sh" "$prerequisiteName" "$repoRoot")

if [ $? -eq 1 ]; then
    echo "$declaredVersion"
    exit 1
fi

# Check if the version of CMake downloaded matches the declared version.
validate_CMake_version()
{
    if ! echo $("$prerequisitePath" -version) | grep -iq "cmake version $declaredVersion"; then
        echo "Version of the executable located at $prerequisitePath does not match the declared version that is $declaredVersion."
        exit 1
    fi
}

lowerI="$(echo $prerequisiteName | awk '{print tolower($0)}')"
case $lowerI in
    "cmake")
        validate_CMake_version
        ;;
    *)
        echo "Unable to test the version of prerequisite named $prerequisiteName"
        exit 1
esac
