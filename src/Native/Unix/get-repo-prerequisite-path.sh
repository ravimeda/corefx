#!/usr/bin/env bash

# Gets the path to the declared version of the prerequisite executable within the repository.

# Exit 1 if unable to determine the path to executable corresponding to the declared version of the prerequisite.

# Arguments:
#   1. Prerequisite name.
#   2. Repository root path.
#   3. (Optional) Declared version of CMake.
#   4. (Optional) Prerequisite package name.

if [ -z "$1" ]; then
    echo "Argument passed as prerequisite name is empty. Please provide a non-empty string."
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

prerequisiteName="$1"
repoRoot="$( cd "$2" && pwd )"
declaredVersion="$3"
prerequisitePackageName="$4"

get_CMake_path()
{
    if [ -z "$declaredVersion" ]; then
        declaredVersion=$("$repoRoot/src/Native/Unix/get-declared-prerequisite-version.sh" "$prerequisiteName" "$repoRoot")

        if [ $? -eq 1 ]; then
            echo "$declaredVersion"
            exit 1
        fi
    fi

    if [ -z "$prerequisitePackageName" ]; then
        prerequisitePackageName=$("$repoRoot/src/Native/Unix/get-prerequisite-package-name.sh" "$prerequisiteName" "$declaredVersion")

        if [ $? -eq 1 ]; then
            echo "$prerequisitePackageName"
            exit 1
        fi
    fi

    downloadsPrereqPath="$repoRoot/Tools/Downloads/CMake/$prerequisitePackageName"

    if $(echo "$prerequisitePackageName" | grep -iqF "Darwin"); then
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

lowerI="$(echo $prerequisiteName | awk '{print tolower($0)}')"
case $lowerI in
    "cmake")
        get_CMake_path
        ;;
    *)
        echo "Unable to determine the path to the executable corresponding to prerequisite named $prerequisiteName"
        exit 1
esac
