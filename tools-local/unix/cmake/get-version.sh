# Gets the version of CMake at the specified path.
# Exit 1 if the path is not valid.

if [ -z "$1" ]; then
    echo "Argument passed as tool path is empty. Please provide a non-empty string."
    exit 1
fi

if [ ! -f "$1" ]; then
    if [ ! -d "$1" ]; then
            echo "Argument passed as tool path is not accessible or does not exist. Please provide a valid path."
            exit 1
    fi
fi

toolPath="$1"
scriptPath="$(cd "$(dirname "$0")"; pwd -P)"

# Extract version number. For example, 3.6.0 in text below.
#cmake version 3.6.0
#
#CMake suite maintained and supported by Kitware (kitware.com/cmake).

echo "$("$toolPath" -version | grep -o '[0-9].[0-9].*$')"
