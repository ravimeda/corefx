@if "%_echo%" neq "on" echo off
rem
rem This file invokes cmake and generates the build system for windows.

set argC=0
for %%x in (%*) do Set /A argC+=1

if NOT %argC%==4 GOTO :USAGE
if %1=="/?" GOTO :USAGE

setlocal
set __sourceDir=%~dp0
:: VS 2015 is the minimum supported toolset
set __VSString=14 2015

set __StrictToolVersionMatch=

:: Set the target architecture to a format cmake understands. ANYCPU defaults to x64
if /i "%3" == "x86"     (set __VSString=%__VSString%)
if /i "%3" == "x64"     (set __VSString=%__VSString% Win64)
if /i "%3" == "arm"     (set __VSString=%__VSString% ARM)
if /i "%3" == "arm64"   (set __VSString=%__VSString% Win64)
if /i "%4" == "StrictToolVersionMatch"  (set __StrictToolVersionMatch="-StrictToolVersionMatch")

if defined CMakePath goto DoGen

:: Eval the output from probe-tool.ps1
pushd "%__sourceDir%"
setlocal EnableDelayedExpansion
for /f "Tokens=* Delims=" %%x in ('powershell -NoProfile -ExecutionPolicy ByPass "& .\probe-tool.ps1 -ToolName CMake %__StrictToolVersionMatch%"') do set ProbeValue=!ProbeValue!%%x

if exist "%ProbeValue%" (
    set "CMakePath=%ProbeValue%"
    echo CMakePath=!CMakePath!
) else (
:: TODO: ProbeValue prints in single line. Format output to include newline and indent.
    echo "%ProbeValue%"
    EXIT /B 1
)
popd

:DoGen
"%CMakePath%" %__SDKVersion% "-DCMAKE_BUILD_TYPE=%CMAKE_BUILD_TYPE%" "-DCMAKE_INSTALL_PREFIX=%__CMakeBinDir%" -G "Visual Studio %__VSString%" -B. -H%1
endlocal
GOTO :DONE

:USAGE
  echo "Usage..."
  echo "gen-buildsys-win.bat <path to top level CMakeLists.txt> <VSVersion> <Target Architecture"
  echo "Specify the path to the top level CMake file - <ProjectK>/src/NDP"
  echo "Specify the VSVersion to be used - VS2013 or VS2015"
  echo "Specify the Target Architecture - x86, AnyCPU, ARM, or x64."
  EXIT /B 1

:DONE
  EXIT /B 0
