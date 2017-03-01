#!/usr/bin/env bash

# Gets the path to CMake executable. Searches for CMake on the local machine. 
# If CMake is not found then, attempts to acquire CMake.

# Exit 1 if unable to acquire the declared version of CMake.

# Arguments:
#   1. (Optional) StrictToolVersionMatch. If specified then, ensures the version of the specified tool available for the build matches the declared version.
#   2. (Optional) Declared version of the tool. If not specified, declared version will be determined by invoking ./get-declared-tool-version.sh.


if [ ! -z "$1" ]; then
    __StrictToolVersionMatch=0
else
    __StrictToolVersionMatch=1
fi

# Determine repository root path.
scriptpath=$(cd "$(dirname "$0")"; pwd -P)
repoRoot=$(cd "$scriptpath/../../.."; pwd -P)

# Dot source the helper functions file.
. "$repoRoot/Tools-Local/CMake/Unix/cmake-helper.sh"

if [ ! -z "$2" ]; then
    declaredVersion="$2"
else
    declaredVersion=$(get-declared-version "$repoRoot")
fi

locate_CMake_executable()
{
    # Get the path to CMake executable in environment, and in downloads folder.
    environmentCMakePath=$(which cmake)
    downloadsCMakePath=$(get-repo-cmake-path "$repoRoot")

    if [ $__StrictToolVersionMatch -eq 0 ]; then
        # Ensuring that the version of available CMake matches the declared version is not required.
        if [ -f "$environmentCMakePath" ]; then
            # CMake executable is found in the environment path.
            CMakePath="$environmentCMakePath"
        else
            # If CMake executable is not found in the environment path, then consume the one in downloads folder.
            # If not available in downloads folder then, download it at a later step.
            CMakePath="$downloadsCMakePath"
        fi
    else
        # StrictToolVersionMatch is specified.
        # This means the version of CMake available for the build should match the declared version.
        # Check the version of CMake available in environment path.
        $(test-cmake-version "$environmentCMakePath" "$repoRoot") 2>/dev/null

        if [ $? -eq 0 ]; then
            # Version of CMake in the environment path matches the declared version.
            CMakePath="$environmentCMakePath"
        else
            # Version of CMake in environment path does not match the declared version.
            # Check the version of CMake in downloads folder.
            $(test-cmake-version "$downloadsCMakePath" "$repoRoot") 2>/dev/null

            if [ $? -eq 0 ]; then
                # Version of CMake in downloads folder matches the declared version.
                CMakePath="$downloadsCMakePath"
            fi
        fi
    fi

    if [ ! -f "$CMakePath" ]; then
        # 1. CMake is available neither in the environment nor in the downloads folder. 
        # 2. StrictToolVersionMatch is specified, and CMake is available in the environment 
        #       but is not the declared version.
        #   In either of the above two cases, acquire CMake.
        $("$repoRoot/Tools-Local/CMake/Unix/get-tool.sh" "$repoRoot" "$declaredVersion") 2>/dev/null
        CMakePath=$downloadsCMakePath
    fi
}


locate_CMake_executable
echo "$CMakePath"
