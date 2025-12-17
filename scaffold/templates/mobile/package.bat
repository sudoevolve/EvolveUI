@echo off
setlocal

echo --- EvolveUI Packaging Script ---
echo.

REM Set your project name here
set PROJECT_NAME={{PROJECT_NAME}}

REM --- Configuration ---
set BUILD_DIR=build
set OUTPUT_DIR=output
set BUILD_CONFIG=Release
if not "%1"=="" set BUILD_CONFIG=%1
set EXE_NAME=%PROJECT_NAME%.exe
set EXE_PATH=%BUILD_DIR%\%BUILD_CONFIG%\%EXE_NAME%
if "%1"=="" if not exist "%EXE_PATH%" if exist "%BUILD_DIR%\%EXE_NAME%" set EXE_PATH=%BUILD_DIR%\%EXE_NAME%
if not exist "%EXE_PATH%" for /d %%D in ("%BUILD_DIR%\*-%BUILD_CONFIG%") do if exist "%%~fD\%EXE_NAME%" set EXE_PATH=%%~fD\%EXE_NAME% & set KIT_DIR=%%~fD
set QML_SOURCE_DIR=%CD%

echo [INFO] Project Name: %PROJECT_NAME%
echo [INFO] Executable Path: %EXE_PATH%
echo [INFO] QML Source Dir: %QML_SOURCE_DIR%
echo.

REM === Step 1: Check for windeployqt ===
echo [STEP 1/5] Checking for 'windeployqt'...
where windeployqt >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] 'windeployqt' not found in your system's PATH.
    echo Please add your Qt bin directory, e.g. C:\Qt\6.x.x\msvcxxxx_xx\bin, to PATH.
    goto :error
)
echo [SUCCESS] 'windeployqt' found.
echo.

REM === Step 2: Check for Executable ===
echo [STEP 2/5] Checking for project executable...
echo [INFO] Using build configuration: %BUILD_CONFIG%
if exist "%EXE_PATH%" goto EXE_FOUND
echo [ERROR] Executable not found at "%EXE_PATH%".
echo [HINT] Build %BUILD_CONFIG% first: cmake --build build --config %BUILD_CONFIG%
goto :error
:EXE_FOUND
echo [SUCCESS] Executable found.
echo.

REM === Step 3: Create Output Directory ===
echo [STEP 3/5] Creating output directory...
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
echo [SUCCESS] Output directory is ready.
echo.

REM === Step 4: Copy Executable ===
echo [STEP 4/5] Copying executable to output directory...
copy /Y "%EXE_PATH%" "%OUTPUT_DIR%\%EXE_NAME%" >nul
if %errorlevel% neq 0 (
    echo [ERROR] Failed to copy the executable.
    goto :error
)
echo [SUCCESS] Executable copied.
echo.

REM === Step 5: Run windeployqt ===
echo [STEP 5/5] Running windeployqt to deploy dependencies...
cd "%OUTPUT_DIR%"
set WDQ_MODE=--release
if /I "%BUILD_CONFIG%"=="Debug" set WDQ_MODE=--debug
windeployqt %WDQ_MODE% --qmldir "%QML_SOURCE_DIR%" "%EXE_NAME%"
if %errorlevel% neq 0 (
    echo [ERROR] 'windeployqt' command failed. Please check the output above for details.
    goto :error
)

echo.
echo ==================================================
echo  Packaging Complete!
echo  Your application is ready in the '%OUTPUT_DIR%' directory.
echo ==================================================
echo.
pause
exit /b 0

:error
echo.
echo ==================================================
echo  An error occurred during packaging.
echo  Please review the messages above.
echo ==================================================
echo.
pause
exit /b 1
