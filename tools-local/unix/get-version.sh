# Gets the version of the specified tool at the given path. Invokes a tool specific 
# script that has the implementation for determining the version from the executable.
# Exit 1 if unable to locate the

if [ -z "$1" ]; then
    echo "Argument passed as tool name is empty. Please provide a non-empty string."
    exit 1
fi

if [ -z "$2" ]; then
    echo "Argument passed as tool path is empty. Please provide a non-empty string."
    exit 1
fi

toolName="$1"
toolPath="$2"
scriptPath="$(cd "$(dirname "$0")"; pwd -P)"
overriddenGetVersionScriptPath="$scriptPath/$toolName/get-version.sh"

if [ ! -f "$overriddenGetVersionScriptPath" ]; then
    echo "Unable to locate get-version.sh at the specified path. Path: $overriddenGetVersionScriptPath"
    exit 1
fi

"$overriddenGetVersionScriptPath" "$toolPath"

if [ $? -eq 1 ]; then
    exit 1
fi