@echo off
setlocal EnableDelayedExpansion

:: Elevate to admin
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting admin access...
    powershell -Command "Start-Process '%~f0' -Verb runAs"
    exit /b
)

echo ---------------------------------------
echo   Windows Full Repair Tool Started
echo ---------------------------------------
echo.

:: Stop Explorer & Shell processes
taskkill /IM explorer.exe /F >nul 2>&1
taskkill /IM ShellExperienceHost.exe /F >nul 2>&1
taskkill /IM StartMenuExperienceHost.exe /F >nul 2>&1
timeout /t 1 >nul

:: Clear Taskbar & Icon Cache
del /f /q "%localappdata%\IconCache.db" >nul 2>&1
del /f /q "%localappdata%\Microsoft\Windows\Explorer\iconcache*" >nul 2>&1
del /f /q "%localappdata%\Microsoft\Windows\Explorer\taskbar*" >nul 2>&1

:: Restart Explorer
start explorer.exe
timeout /t 2 >nul

:: Re-register Start Menu
powershell -ExecutionPolicy Bypass -Command ^
"Add-AppxPackage -DisableDevelopmentMode -Register 'C:\Windows\SystemApps\ShellExperienceHost_cw5n1h2txyewy\AppxManifest.xml'" 

powershell -ExecutionPolicy Bypass -Command ^
"Add-AppxPackage -DisableDevelopmentMode -Register 'C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\AppxManifest.xml'"

:: Repair system files
echo Running DISM...
DISM /Online /Cleanup-Image /RestoreHealth

echo Running SFC...
sfc /scannow

echo.
echo ---------------------------------------
echo   Repair Completed - Please Restart PC
echo ---------------------------------------
pause
exit
