#!/usr/bin/env bash

usage()
{
    echo ""
    echo "usage: $0 <repository-root> cmake <override-scripts-folder-path> <tool-path>"
    echo "repository-root                   Path to repository root."
    echo "override-scripts-folder-path      This argument is ignored."
    echo "tool-path                         Path to CMake executable or the folder containing the executable."
    echo ""
    echo "If successful then, returns the version number of CMake executable."
    echo "Exit 1 if the version of the executable is an empty string."
    echo ""
}

repoRoot="$1"
toolName="$2"
toolPath="$4"

scriptPath="$(cd "$(dirname "$0")/.."; pwd -P)"
. "$scriptPath/tool-helper.sh"

exit_if_invalid_path "repository-root" "$repoRoot" "$(usage)"
[ "$toolName" == "cmake" ] || fail "$repoRoot" "Second argument should be cmake." "$(usage)"
exit_if_invalid_path "tool-path" "$toolPath" "$(usage)"
[ $# -eq 4 ] || fail "$repoRoot" "Invalid number of arguments. Expected: 4 Actual: $#" "$(usage)"

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
