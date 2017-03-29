#!/usr/bin/env bash

# Gets the version of CMake at the specified path.

usage()
{
    echo "Usage: $0 ToolPath"
    echo "  ToolPath: Path to CMake executable or the folder containing the executable."
    echo "Returns the version number of CMake executable."
    echo "Exit 1 if the executable is not available at the specified path or folder."
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

if [ -z "$1" ]; then
    echo "Argument passed as ToolPath is empty. Please provide a non-empty string."
    exit 1
fi

if [ ! -f "$1" ]; then
    if [ ! -d "$1" ]; then
            echo "Argument passed as ToolPath is not accessible or does not exist. Please provide a valid path."
            exit 1
    fi
fi

toolPath="$1"

# Gets used in CMake error message.
scriptPath="$(cd "$(dirname "$0")"; pwd -P)"

# Extract version number. For example, 3.6.0 in text below.
#cmake version 3.6.0
#
#CMake suite maintained and supported by Kitware (kitware.com/cmake).

echo "$("$toolPath" -version | grep -o '[0-9].[0-9].*$')"
