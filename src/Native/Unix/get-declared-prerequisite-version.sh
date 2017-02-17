#!/usr/bin/env bash

# Gets the declared version of the prerequisite by parsing the .prerequisiteversions located in the repository root.

# Exit 1 if unable to determine the declared version of the prerequisite.

# Arguments:
#   1. Prerequisite name.
#   2. Repository root path.

if [ -z "$1" ]; then
    echo "Argument provided as prerequisite name is empty. Please provide a non-empty string."
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
prerequisitesFile="$repoRoot/.prerequisiteversions"
declaredVersion="$(. "$prerequisitesFile"; echo ${!1})"

if [ ! -z "$declaredVersion" ]; then
    echo "$declaredVersion"
else
    echo "Unable to read the declared version of $prerequisiteName from $prerequisitesFile"
    exit 1
fi
