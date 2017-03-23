#!/usr/bin/env bash

# Gets the error message to be displayed when clang is not available for the build.

if [ -z "$1" ]; then
    echo "Argument passed as shell scripts path is empty. Please provide a non-empty string."
    exit 1
fi

if [ -z "$2" ]; then
    echo "Argument passed as declared version is empty. Please provide a non-empty string."
    exit 1
fi

shellScriptsPath="$1"
declaredVersion="$2"

echo >&2 "clang is a tool to build this repository but it was not found on the path. Please try one of the following options to acquire clang version $declaredVersion:"
echo >&2 "      1. "
