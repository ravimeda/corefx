#!/usr/bin/env bash

# Provides helper functions.

# Checks if the specified argument is an empty string.
# If yes then, displays a message stating that the argument is empty, and exits with status 1.
exit_if_arg_empty()
{
    argName="$1"
    argValue="$2"

    if [ -z "$argValue" ]; then
        echo "Argument passed as $argName is empty. Please provide a non-empty string."
        exit 1
    fi
}

# Gets the path to default scripts folder, which is tools-local/unix under repository root.
get_default_scripts_folder()
{
    repoRoot="$1"
    exit_if_arg_empty "repository-root" "$repoRoot"
    echo "$repoRoot/tools-local/unix"
}

# Gets name of the operating system.
# Exit 1 if unable to get operating system name.
get_os_name()
{
    osName="$(uname -s)"

    if [ $? -ne 0 ] || [ -z "$osName" ]; then
        echo "Unable to determine the name of the operating system."
        exit 1
    fi

    if echo "$osName" | grep -iqF "Darwin"; then
        osName="OSX"
    else
        osName="Linux"
    fi

    echo "$osName"
}

# Eval .toolversions file.
# TODO: 
#   1. Consider accepting the path to an override .toolversions file.
#   2. If the override .toolversions is available then, use the config values from that file.
#   3. If override is not available then use the default .toolversions file.
eval_tool()
{
    repoRoot="$1"
    toolName="$2"
    exit_if_arg_empty "repository-root" "$repoRoot"
    exit_if_arg_empty "tool-name" "$toolName"
    . "$repoRoot/.toolversions"

    # Evaluate toolName. This assigns the metadata of toolName to tools.
    eval "tools=\$$toolName"

    # Evaluate tools. Each argument here is tool specific data such as DeclaredVersion of toolName.
    eval "$tools"
}

# Gets the value corresponding to the specified configuration from the .toolversions file.
# Exit 1 if the value is not found or empty.
get_tool_config_value()
{
    repoRoot="$1"
    toolName="$2"
    configName="$3"

    exit_if_arg_empty "repository-root" "$repoRoot"
    exit_if_arg_empty "tool-name" "$toolName"
    exit_if_arg_empty "configuration-name" "$configName"

    configValue="$(eval_tool "$repoRoot" "$toolName"; eval echo "\$$configName")"

    if [ -z "$configValue" ]; then
        echo "Unable to read the value corresponding to $configName from the .toolversions file."
        exit 1
    fi

    echo "$configValue"
}

# Gets the name of the download package corresponding to the specified tool name.
# Download package name is read from the .toolversions file.
# Exit 1 if unable to read the name of the download package from the .toolversions file.
get_download_file()
{
    repoRoot="$1"
    toolName="$2"

    exit_if_arg_empty "repository-root" "$repoRoot"
    exit_if_arg_empty "tool-name" "$toolName"

    osName="$(get_os_name)"
    get_tool_config_value "$repoRoot" "$toolName" "DownloadFile$osName"
}

# Gets the absolute path to the cache corresponding to the specified tool.
# Path is read from the .toolversions file. If the path is not specified in .toolversions file then,
# returns the path to Tools/downloads folder under the repository root.
get_local_tool_folder()
{
    repoRoot="$1"
    toolName="$2"

    exit_if_arg_empty "repository-root" "$repoRoot"
    exit_if_arg_empty "tool-name" "$toolName"

    toolFolder="$(get_tool_config_value "$repoRoot" "$toolName" "LocalToolFolder")"

    if [ $? -ne 0 ]; then
        toolFolder="Tools/downloads/$toolName"
    fi

    case "$toolFolder" in
        /*)
            echo "$toolFolder"
            ;;
        *)
            # Assumed that the path specified in .toolversion is relative to the repository root.
            echo "$repoRoot/$toolFolder"
            ;;
    esac
}

# Gets the search path corresponding to the specified tool name.
# Search path is read from the .toolversions file.
# Exit 1 if unable to read the path from the .toolversions file.
get_local_search_path()
{
    repoRoot="$1"
    toolName="$2"

    exit_if_arg_empty "repository-root" "$repoRoot"
    exit_if_arg_empty "tool-name" "$toolName"

    toolFolder="$(get_local_tool_folder "$repoRoot" "$toolName")"
    osName="$(get_os_name)"
    searchPath="$(get_tool_config_value "$repoRoot" "$toolName" "LocalSearchPath${osName}")"
    echo "$toolFolder/$searchPath"
}

# Gets the error message to be displayed when the specified tool is not available for the build.
# Error message is read from the .toolversions file.
# Exit 1 if unable to read the error message from the .toolversions file.
tool_not_found_message()
{
    repoRoot="$1"
    toolName="$2"

    exit_if_arg_empty "repository-root" "$repoRoot"
    exit_if_arg_empty "tool-name" "$toolName"

    # Eval in a subshell to avoid conflict with existing variables.
    (
        eval_tool "$repoRoot" "$toolName"

        if [ -z "$ToolNotFoundMessage" ]; then
            echo "Unable to locate $toolName."
            exit 1
        fi

        eval echo "$ToolNotFoundMessage"
    )
}

# Write the given message(s) to probe log file.
log_message()
{
    repoRoot="$1"
    exit_if_arg_empty "repository-root" "$repoRoot"
    probeLog="$repoRoot/probe-tool.log"
    shift
    echo "$*" >> "$probeLog"
}

# Displays and logs the specified message, and exits with status 1.
fail()
{
    repoRoot="$1"
    exit_if_arg_empty "repository-root" "$repoRoot"
    log_message "$@"
    shift
    echo "$@"
    exit 1
}

# Invokes the override extension script if available, else invokes the base implementation.
invoke_extension()
{
    # Displays the usage for invoke_extension function.
    invoke_extension_usage()
    {
        echo "usage: invoke_extension <script-name> <repository-root> <tool-name> <override-scripts-folder-path> [args ...]"
        echo "script-name                       Name of the extension script."
        echo "repository-root                   Path to repository root."
        echo "tool-name                         Name of the tool."
        echo "override-scripts-folder-path      If a path is specified then, search and acquire scripts from the specified folder will be invoked. Otherwise, search will use the default search and acquire scripts located within the repository."
        echo "args                              Any additional arguments that will be passed to the extension script."
        echo ""
        echo "Checks if the specified tool has its own implementation of the search or acquire script. If so, invokes the corresponding script. Otherwise, invokes the base implementation."
        echo ""
        echo "Example #1"
        echo "invoke_extension search-tool.sh \"/Users/dotnet/corefx\" cmake \"\" \"\""
        echo "Searches for CMake, not necessarily the declared version, using the default scripts located within the repository."
        echo ""
        echo "Example #2"
        echo "invoke_extension acquire-tool.sh \"/Users/dotnet/corefx\" cmake \"\""
        echo "Acquires the declared version of CMake, using the default scripts located within the repository."
        echo ""
        echo "Example #3"
        echo "invoke_extension search-tool.sh \"/Users/dotnet/corefx\" cmake \"/Users/dotnet/MyCustomScripts\" strict"
        echo "Searches for the declared version of CMake using the search scripts located under \"/Users/dotnet/MyCustomScripts\"."
        echo ""
        echo "Example #4"
        echo "invoke_extension get-version.sh \"/Users/dotnet/corefx\" cmake \"\"  \"/Users/dotnet/corefx/Tools/download/cmake/bin/cmake\""
        echo "Gets the version number of CMake executable located at /Users/dotnet/corefx/Tools/download/cmake/bin/cmake\" using the default scripts located within the repository."
        echo ""
    }

    if [ $# -lt 4 ]; then
        invoke_extension_usage
        exit 1
    fi

    extensionScriptName="$1"
    repoRoot="$2"
    toolName="$3"
    overrideScriptsFolderPath="$4"
    defaultScriptsFolderPath="$(get_default_scripts_folder $repoRoot)"

    exit_if_arg_empty "script-name" "$extensionScriptName"
    exit_if_arg_empty "repository-root" "$repoRoot"
    exit_if_arg_empty "tool-name" "$toolName"

    if [ ! -z "$overrideScriptsFolderPath" ] && [ ! -d "$overrideScriptsFolderPath" ]; then
        echo "Path specified as override-scripts-folder-path does not exist or is not accessible. Path: $overrideScriptsFolderPath"
        invoke_extension_usage
        exit 1
    fi

    # Gets the appropriate extension script to invoke.
    # Searches for an override of the extension script. If an override does not exist then, gets the path to base implementation of the script.
    for extensionsFolder in "$overrideScriptsFolderPath" "$defaultScriptsFolderPath"; do
        if [ -d "$extensionsFolder" ]; then
            invokeScriptPath="$extensionsFolder/$toolName/$extensionScriptName"

            if [ -f "$invokeScriptPath" ]; then
                # Tool overrides base implementation.
                break
            fi

            invokeScriptPath="$extensionsFolder/$extensionScriptName"

            if [ -f "$invokeScriptPath" ]; then
                # Base implementation.
                break
            fi
        fi
    done

    log_message "$repoRoot" "Invoking $extensionScriptName located in $(dirname $invokeScriptPath) with the following arguments $@."

    # Note that the first argument is the name of the extension script. Hence shift, and pass rest of the arguments to the invocation.
    shift
    "$invokeScriptPath" "$@"
}
