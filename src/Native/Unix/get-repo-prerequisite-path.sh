#!/usr/bin/env bash

# Gets the path to the declared version of the tool executable within the repository.

# Exit 1 if unable to determine the path to executable corresponding to the declared version of the tool.

# Arguments:
#   1. tool name.
#   2. Repository root path.
#   3. (Optional) Declared version of CMake.
#   4. (Optional) tool package name.

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

if [ -z "$2" ]; then
    echo "Argument passed as root of the repository is empty. Please provide a non-empty string."
    exit 1
fi

if [ ! -d "$2" ]; then
    echo "Repository root path does not exist or is not accessible. Path: $2"
    exit 1
fi

toolName="$1"
repoRoot="$( cd "$2" && pwd )"
declaredVersion="$3"
toolPackageName="$4"

get_CMake_path()
{
    if [ -z "$declaredVersion" ]; then
        declaredVersion=$("$repoRoot/src/Native/Unix/get-declared-tool-version.sh" "$toolName" "$repoRoot")

        if [ $? -eq 1 ]; then
            echo "$declaredVersion"
            exit 1
        fi
    fi

    if [ -z "$toolPackageName" ]; then
        toolPackageName=$("$repoRoot/src/Native/Unix/get-tool-package-name.sh" "$toolName" "$declaredVersion")

        if [ $? -eq 1 ]; then
            echo "$toolPackageName"
            exit 1
        fi
    fi

    downloadsPrereqPath="$repoRoot/Tools/Downloads/CMake/$toolPackageName"

    if $(echo "$toolPackageName" | grep -iqF "Darwin"); then
        downloadsPrereqPath="$downloadsPrereqPath/CMake.app/Contents"
    else
        downloadsPrereqPath="$downloadsPrereqPath"
    fi

    downloadsPrereqPath="$downloadsPrereqPath/bin/cmake"

    if [ ! -z "$downloadsPrereqPath" ]; then
        echo "$downloadsPrereqPath"
    else
        echo "Unable to determine the downloads folder path for CMake."
        exit 1
    fi
}

lowerI="$(echo $toolName | awk '{print tolower($0)}')"
case $lowerI in
    "cmake")
        get_CMake_path
        ;;
    *)
        echo "Unable to determine the path to the executable corresponding to tool named $toolName"
        exit 1
esac
