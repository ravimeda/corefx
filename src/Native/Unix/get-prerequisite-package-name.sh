#!/usr/bin/env bash

# Gets the name of tool package corresponding to the given declared version. 
# Reads the declared version of tool from .cmakeversion file. 
# Detects the architecture of the operating system, and determines the package name.

# Exit 1 if unable to determine the package name corresponding to the declared version of the tool.

# Arguments:
#   1. tool name
#   2. Declared version of the tool
#   3. (Optional) Name of the operating system. 
#           If "OSX" then, "Darwin-x86_64" else "Linux-x86_64" is suffixed to package name. 
#           If no value is provided to this argument then, operating system name is 
#           determined from $(uname) variable.

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

if [ -z "$2" ]; then
    echo "Argument passed as declared version is empty. Please provide a non-empty string."
    exit 1
fi

if [ -z "$3" ]; then
    operatingSystemName="$(uname -s)"

    if [ -z "$operatingSystemName" ]; then
        echo "Argument passed as operating system name is empty and no operating system name could be detected. Please provide a non-empty string."
        exit 1
    fi
else
    operatingSystemName="$3"
fi

toolName="$1"
declaredVersion="$2"

get-CMake-package-name()
{
    if [ "$operatingSystemName" == "OSX" ] || $(echo "$operatingSystemName" | grep -iqF "Darwin"); then
        CMakePlatform="Darwin-x86_64"
    else
        CMakePlatform="Linux-x86_64"
    fi

    echo "cmake-$declaredVersion-$CMakePlatform"
}

lowerI="$(echo $toolName | awk '{print tolower($0)}')"
case $lowerI in
    "cmake")
        get-CMake-package-name
        ;;
    *)
        echo "Unable to get the package name for tool named $toolName"
        exit 1
esac
