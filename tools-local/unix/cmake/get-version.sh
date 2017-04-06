#!/usr/bin/env bash

usage()
{
    echo "usage: $0 cmake <override-scripts-folder-path> <strict-tool-version-match> <tool-path>"
    echo "  override-scripts-folder-path: This argument is ignored."
    echo "  strict-tool-version-match: This argument is ignored."
    echo "  tool-path: Path to CMake executable or the folder containing the executable."
    echo "If successful then, returns the version number of CMake executable."
    echo "Exit 1 if the executable is not available at the specified path or folder."
}

if [ $# -ne 4 ]; then
    usage
    exit 1
fi

if [ -z "$1" ]; then
    echo "Argument passed as tool-name is empty. Please provide a non-empty string."
    usage
    exit 1
fi

if [ "$1" != "cmake" ]; then
    echo "First argument should be cmake."
    usage
    exit 1
fi

if [ ! -z "$4" ] && [ ! -f "$4" ]; then
    "Argument specified as tool-path does not exist or is not accessible. Path: $4"
    usage
    exit 1
fi

toolPath="$4"
# Extract version number. For example, 3.6.0 in text below.
#cmake version 3.6.0
#
#CMake suite maintained and supported by Kitware (kitware.com/cmake).

# Assumed that one or more digits followed by a decimal point is the start of version number. Get all text till end of line.
echo "$("$toolPath" -version | grep -o '[0-9]\+\..*')"
