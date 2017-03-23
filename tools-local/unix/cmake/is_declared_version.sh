#!/usr/bin/env bash

# Compares the version of CMake executable at the specified path with the declared version.
# Exit 1 if the executable does not exist or the version does not match.

if [ -z "$1" ]; then
    echo "Argument passed as tool path is empty. Please provide a non-empty string."
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Tool path does not exist or is not accessible. Path: $1"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Argument passed as declared version is empty. Please provide a non-empty string."
    exit 1
fi

toolPath="$1"
declaredVersion="$2"

# Check if the version of CMake matches the declared version.
if ! echo $("$toolPath" -version) | grep -iq "cmake version $declaredVersion"; then
    echo "Version of the executable located at $toolPath does not match the declared version that is $declaredVersion."
    exit 1
fi
