#!/usr/bin/env bash

# Gets the version of CMake at the specified path.

usage()
{
    echo "Usage: $0 cmake ToolName --ToolPath <path>"
    echo "  ToolPath: Path to CMake executable or the folder containing the executable."
    echo "If successful then, returns the version number of CMake executable."
    echo "Exit 1 if the executable is not available at the specified path or folder."
}

if [ $# -lt 2 ]; then
    usage
    exit 1
fi

toolName="$1"
shift

if [ -z "$toolName" ] || [ "$toolName" != "cmake" ]; then
    echo "First argument should be cmake."
    exit 1
fi

while :; do
    if [ $# -le 0 ]; then
        break
    fi

    lowerI="$(echo $1 | awk '{print tolower($0)}')"
    case $lowerI in
        --toolpath)
            shift

            if [ ! -f "$1" ]; then
                        echo "Argument passed as ToolPath is not accessible or does not exist. Please provide a valid path."
                        exit 1
            fi

            toolPath="$1"
            ;;
    esac
    shift
done


# Extract version number. For example, 3.6.0 in text below.
#cmake version 3.6.0
#
#CMake suite maintained and supported by Kitware (kitware.com/cmake).

# Assumed that one or more digits followed by a decimal point is the start of version number. Get all text till end of line.
echo "$("$toolPath" -version | grep -o '[0-9]\+\..*')"
