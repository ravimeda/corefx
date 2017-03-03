#!/usr/bin/env bash

# Gets the path to the specified tool. 
# Searches for the tool in the local environment path.

# Exit 1 if unable to locate the tool.

# Arguments:
#   1. Name of the tool.
#   2. Declared version of the tool.

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
else
    toolName="$1"
fi

if [ -z "$2" ]; then
    echo "Argument passed as declared version is empty. Please provide a non-empty string."
    exit 1
else
    declaredVersion="$2"
fi

# Determine repository root path.
scriptpath=$(cd "$(dirname "$0")"; pwd -P)
repoRoot=$(cd "$scriptpath/../../.."; pwd -P)

# Dot source the helper functions file.
. "$repoRoot/tools-local/helper/unix/cmake-helper.sh"

locate_CMake_executable()
{
    # Get the path to CMake executable in environment.
    CMakePath=$(which cmake)

    if [ ! -f "$CMakePath" ]; then
        # 1. CMake is available neither in the environment nor in the downloads folder. 
        # 2. StrictToolVersionMatch is specified, and CMake is available in the environment 
        #       but is not the declared version.
        #   In either of the above two cases, acquire CMake.
        $("$repoRoot/Tools-Local/CMake/Unix/get-tool.sh" "$repoRoot" "$declaredVersion") 2>/dev/null
        CMakePath=$downloadsCMakePath
    fi
}


lowerI="$(echo $toolName | awk '{print tolower($0)}')"
case $lowerI in
    "cmake")
        locate_CMake_executable
        echo "$CMakePath"
        ;;
    *)
        echo "Tool is not supported. Tool name: $toolName"
        exit 1
esac
