@echo off
powershell.exe -ExecutionPolicy Bypass -File "%~dp0\New-EvolveUIProject.ps1"

echo.
echo --------------------------------------------------
echo Script execution has finished. If you see red error text above, please copy it.
echo Press any key to close this window...
pause >nul