#!/usr/bin/env bash

# Gets the path to the specified tool. Searches for the tool on the local machine. 
# If the tool is not found then, attempts to acquire the tool.

# Exit 1 if unable to acquire the declared version of the tool.

# Arguments:
#   1. Tool name.
#   2. (Optional) StrictToolVersionMatch. If specified then, ensures the version of the specified tool available for the build matches the declared version.
#   3. (Optional) Declared version of the tool. If not specified, declared version will be determined by invoking ./get-declared-tool-version.sh.

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
else
    toolName="$1"
fi

if [ ! -z "$2" ]; then
    __StrictToolVersionMatch=0
else
    __StrictToolVersionMatch=1
fi

if [ ! -z "$3" ]; then
    declaredVersion="$3"
fi

# Get declared version.
get_declared_version()
{
    if [ -z "$declaredVersion" ]; then
        declaredVersion=$("$repoRoot/Tools-Local/CMake/Unix/get-declared-tool-version.sh" "$toolName" "$repoRoot")

        if [ $? -eq 1 ]; then
            echo "$declaredVersion"
            exit 1
        fi
    fi
}

locate_CMake_executable()
{
    # Get the path to CMake executable in environment, and in downloads folder.
    environmentCMakePath=$(which cmake)
    downloadsCMakePath=$("$repoRoot/Tools-Local/CMake/Unix/get-repo-tool-path.sh" "$toolName" "$repoRoot" "$declaredVersion")

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
        $("$repoRoot/Tools-Local/CMake/Unix/test-tool-version.sh" "$toolName" "$environmentCMakePath" "$repoRoot") 2>/dev/null

        if [ $? -eq 0 ]; then
            # Version of CMake in the environment path matches the declared version.
            CMakePath="$environmentCMakePath"
        else
            # Version of CMake in environment path does not match the declared version.
            # Check the version of CMake in downloads folder.
            $("$repoRoot/Tools-Local/CMake/Unix/test-tool-version.sh" "$toolName" "$downloadsCMakePath" "$repoRoot") 2>/dev/null

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
        $("$repoRoot/Tools-Local/CMake/Unix/get-tool.sh" "CMake" "$repoRoot" "$declaredVersion") 2>/dev/null
        CMakePath=$downloadsCMakePath
    fi
}

# Determine repository root path.
__scriptpath=$(cd "$(dirname "$0")"; pwd -P)
repoRoot=$(cd "$__scriptpath/../../.."; pwd -P)

lowerI="$(echo $toolName | awk '{print tolower($0)}')"
case $lowerI in
    "cmake")
        get_declared_version
        locate_CMake_executable
        echo "$CMakePath"
        ;;
    *)
        echo "Unable to test the version of tool named $toolName"
        exit 1
esac
