#!/usr/bin/env bash

usage()
{
    echo "usage: $0 <repository-root> cmake <override-scripts-folder-path> <strict-tool-version-match> <tool-path>"
    echo "repository-root                   This argument is ignored."
    echo "override-scripts-folder-path      This argument is ignored."
    echo "strict-tool-version-match         This argument is ignored."
    echo "tool-path                         Path to CMake executable or the folder containing the executable."
    echo ""
    echo "If successful then, returns the version number of CMake executable."
    echo "Exit 1 if the version of the executable is an empty string."
}

if [ $# -ne 5 ]; then
    usage
    exit 1
fi

toolName="$2"
toolPath="$5"

if [ "$toolName" != "cmake" ]; then
    echo "Second argument should be cmake."
    usage
    exit 1
fi

if [ ! -f "$toolPath" ]; then
    echo "Argument specified as tool-path does not exist or is not accessible. Path: $toolPath"
    usage
    exit 1
fi


# Extract version number. For example, 3.6.0 in text below.
#cmake version 3.6.0
#
#CMake suite maintained and supported by Kitware (kitware.com/cmake).

# Assumed that one or more digits followed by a decimal point is the start of version number. Get all text till end of line.
toolVersion="$("$toolPath" -version | grep -o '[0-9]\+\..*')"

if [ -z "$toolVersion" ]; then
    echo "Unable to determine the version of CMake at $toolPath."
    exit 1
fi

echo "$toolVersion"
