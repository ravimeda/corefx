#!/usr/bin/env bash

usage()
{
    echo "usage: $0 <repository-root> cmake <override-scripts-folder-path> <strict-tool-version-match> <tool-path>"
    echo "  repository-root: This argument is ignored."
    echo "  override-scripts-folder-path: This argument is ignored."
    echo "  strict-tool-version-match: This argument is ignored."
    echo "  tool-path: Path to CMake executable or the folder containing the executable."
    echo "If successful then, returns the version number of CMake executable."
    echo "Exit 1 if the executable is not available at the specified path or folder."
}

if [ $# -ne 5 ]; then
    usage
    exit 1
fi

if [ "$2" != "cmake" ]; then
    echo "Second argument should be cmake."
    usage
    exit 1
fi

if [ ! -z "$5" ] && [ ! -f "$5" ]; then
    "Argument specified as tool-path does not exist or is not accessible. Path: $5"
    usage
    exit 1
fi

toolPath="$5"
# Extract version number. For example, 3.6.0 in text below.
#cmake version 3.6.0
#
#CMake suite maintained and supported by Kitware (kitware.com/cmake).

# Assumed that one or more digits followed by a decimal point is the start of version number. Get all text till end of line.
echo "$("$toolPath" -version | grep -o '[0-9]\+\..*')"
