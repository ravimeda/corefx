#!/usr/bin/env bash

# Get the error message to be displayed when CMake is not available for the build.

if [ -z "$1" ]; then
    echo "Argument passed as repository root path is empty. Please provide a non-empty string."
    exit 1
fi

if [ -z "$2" ]; then
    echo "Argument passed as declared version is empty. Please provide a non-empty string."
    exit 1
fi

repoRoot="$1"
declaredVersion="$2"

echo >&2 "CMake is a tool to build this repository but it was not found on the path. Please try one of the following options to acquire CMake version $declaredVersion:"
echo >&2 "      1. Install CMake version $declaredVersion from https://cmake.org/files/, and make sure CMake is added to environment path"
echo >&2 "      2. Run the script $repoRoot/tools-local/unix/acquire-tool.sh "CMake""
