@echo off
setlocal enabledelayedexpansion enableextensions
set BUILD_DIR=%~dp0
set BUILD_NOINT=0
set BUILD_NOUZ=0
set BUILD_SILENT=0

:LoopParams
    if /I "%1" EQU "NoInt"  ( set BUILD_NOINT=1 )
    if /I "%1" EQU "NoUz"   ( set BUILD_NOUZ=1 )
    if /I "%1" EQU "Silent" ( set BUILD_SILENT=1 )
    shift /1
    if [%1] NEQ [] goto LoopParams

echo BUILD_NOINT=%BUILD_NOINT% BUILD_NOUZ=%BUILD_NOUZ% BUILD_SILENT=%BUILD_SILENT%

pushd %BUILD_DIR%

for /f "delims=" %%X IN ('dir /B /A /S *') DO (
	for %%D in ("%%~dpX\.") do (
		set PACKAGE_NAME=%%~nxD
		goto FoundPkgName
	)
)

:FoundPkgName

set MAKEINI="%BUILD_DIR%Build\Temp\make.ini"
set DEPENDENCIES=Core Engine Editor UWindow Fire IpDrv UWeb UBrowser UnrealShare UnrealI UMenu Botpack UTMenu UTBrowser
call :GenerateMakeIni %MAKEINI% %DEPENDENCIES% %PACKAGE_NAME%

pushd ..\System

:: make sure to always rebuild the package
:: New package GUID, No doubts about staleness
del %PACKAGE_NAME%.u

if %BUILD_SILENT% == 1 (
    ucc make -ini=%MAKEINI% -Silent
) else (
    ucc make -ini=%MAKEINI%
)

:: dont do the post-process steps if compilation failed
if ERRORLEVEL 1 goto compile_failed

:: copy to release location
if not exist %BUILD_DIR%System (mkdir %BUILD_DIR%System)
copy %PACKAGE_NAME%.u %BUILD_DIR%System >NUL

if %BUILD_NOUZ% == 0 (
    :: generate compressed file for redirects
    ucc compress %PACKAGE_NAME%.u
    copy %PACKAGE_NAME%.u.uz %BUILD_DIR%System >NUL
)

if %BUILD_NOINT% == 0 (
    :: dump localization strings
    ucc dumpint %PACKAGE_NAME%.u
    copy %PACKAGE_NAME%.int %BUILD_DIR%System >NUL
)

popd

if exist "PostBuildHook.bat" call "PostBuildHook.bat"

echo [Finished at %Date% %Time%]

popd
endlocal
exit /B 0

:compile_failed
popd
popd
endlocal
exit /B 1

:: GenerateMakeIni
::  Generates an INI file for use with 'ucc make'
:: 
:: Usage:
::  call :GenerateMakeIni IniPath Packages...
::   IniPath is where to generate the ini to
::   Packages... is a variadic list of Packages (up to 254)
::    Usually the last Package is the one that you are trying to compile
::    If Package A depends on Package B, then B must appear before A in this list.
:GenerateMakeIni
    if not exist %1 mkdir %~dp1
    call :GenerateMakeIniPreamble %1

    :GenerateMakeIniNextDependency
        call :GenerateMakeIniDependency %1 %2
        shift /2
        if [%2] NEQ [] goto GenerateMakeIniNextDependency

    call :GenerateMakeIniPostscript %1
exit /B %ERRORLEVEL%

:: It is important to not have spaces before the >>.
:: Spaces will be part of the names UT parses from the INI.

:GenerateMakeIniPreamble
    echo ; Generated>%1
    echo.>>%1
    echo [Engine.Engine]>>%1
    echo EditorEngine=Editor.EditorEngine>>%1
    echo.>>%1
    echo [Editor.EditorEngine]>>%1
    echo CacheSizeMegs=32>>%1
exit /B %ERRORLEVEL%

:GenerateMakeIniPostscript
    echo.>>%1
    echo [Core.System]>>%1
    echo Paths=*.u>>%1
    echo Paths=../Maps/*.unr>>%1
    echo Paths=../Textures/*.utx>>%1
    echo Paths=../Sounds/*.uax>>%1
    echo Paths=../Music/*.umx>>%1
exit /B %ERRORLEVEL%

:GenerateMakeIniDependency
    echo EditPackages=%2>>%1
exit /B %ERRORLEVEL%
