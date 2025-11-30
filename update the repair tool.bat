@echo off
REM Windows Full Repair Tool - batch script
REM Author: ChatGPT helper (provide at-your-own-risk tool)
REM Purpose: Restart shell components, repair Start Menu, clear caches, run SFC/DISM, restart audio services, and collect logs.

n:: --------------------------
:: Self-elevate to Administrator
:: --------------------------
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
  echo Requesting administrative privileges...
  powershell -Command "Start-Process -FilePath '%~f0' -Verb runAs"
  exit /b
)

:: Create timestamp-safe logfile
for /f "tokens=1-5 delims=/: " %%a in ("%date% %time%") do set TS=%%a-%%b-%%c_%%d-%%e
set LOGFILE=%TEMP%\win_repair_%TS%.log

necho Windows Full Repair Tool started at %date% %time% > "%LOGFILE%"

necho -------------------------------------------------- >> "%LOGFILE%"

:: Advise user and close common apps
echo Please save your work and close all open applications. This script will restart Explorer and some services. >> "%LOGFILE%"

:: Stop Explorer and related shell processes (safe restart)
echo Stopping Explorer and shell processes... >> "%LOGFILE%"
taskkill /IM ShellExperienceHost.exe /F >> "%LOGFILE%" 2>&1
taskkill /IM StartMenuExperienceHost.exe /F >> "%LOGFILE%" 2>&1
taskkill /IM explorer.exe /F >> "%LOGFILE%" 2>&1
timeout /t 2 /nobreak >nul

:: Clear icon & taskbar caches
necho Clearing icon and taskbar caches... >> "%LOGFILE%"
if exist "%localappdata%\IconCache.db" del /f /q "%localappdata%\IconCache.db" >> "%LOGFILE%" 2>&1
del /f /q "%localappdata%\Microsoft\Windows\Explorer\iconcache*" >> "%LOGFILE%" 2>&1
del /f /q "%localappdata%\Microsoft\Windows\Explorer\taskbar*" >> "%LOGFILE%" 2>&1

:: Restart Explorer
necho Restarting Explorer... >> "%LOGFILE%"
start explorer.exe >> "%LOGFILE%" 2>&1
timeout /t 3 /nobreak >nul

:: Re-register Start Menu & Shell apps (PowerShell)
echo Re-registering Start Menu and ShellExperienceHost (this may take a moment)... >> "%LOGFILE%"
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Try {Add-AppxPackage -DisableDevelopmentMode -Register \"C:\\Windows\\SystemApps\\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\\AppxManifest.xml\" -Verbose  } Catch {Write-Output 'StartMenu re-register failed: ' $_} " >> "%LOGFILE%" 2>&1
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Try {Add-AppxPackage -DisableDevelopmentMode -Register \"C:\\Windows\\SystemApps\\ShellExperienceHost_cw5n1h2txyewy\\AppxManifest.xml\" -Verbose } Catch {Write-Output 'ShellExperienceHost re-register failed: ' $_} " >> "%LOGFILE%" 2>&1

:: Restart Windows Audio services
necho Restarting audio services... >> "%LOGFILE%"
sc query Audiosrv >> "%LOGFILE%" 2>&1
net stop Audiosrv >> "%LOGFILE%" 2>&1
net stop AudioEndpointBuilder >> "%LOGFILE%" 2>&1
timeout /t 2 /nobreak >nul
net start AudioEndpointBuilder >> "%LOGFILE%" 2>&1
net start Audiosrv >> "%LOGFILE%" 2>&1

:: Run DISM restorehealth and SFC

necho Running DISM /RestoreHealth (this can take 5-30 minutes). Output will be appended to log... >> "%LOGFILE%"
DISM /Online /Cleanup-Image /RestoreHealth >> "%LOGFILE%" 2>&1

necho Running SFC /scannow... >> "%LOGFILE%"
sfc /scannow >> "%LOGFILE%" 2>&1

:: Optional: Reset Windows Update components (safe default)
echo Resetting Windows Update components (optional step)... >> "%LOGFILE%"
net stop wuauserv >> "%LOGFILE%" 2>&1
net stop bits >> "%LOGFILE%" 2>&1
net stop cryptsvc >> "%LOGFILE%" 2>&1
rd /s /q "%windir%\SoftwareDistribution" >> "%LOGFILE%" 2>&1
rd /s /q "%windir%\System32\catroot2" >> "%LOGFILE%" 2>&1
net start cryptsvc >> "%LOGFILE%" 2>&1
net start bits >> "%LOGFILE%" 2>&1
net start wuauserv >> "%LOGFILE%" 2>&1

:: Optional: Check Event Viewer recent errors (last 24 hours) - export a small subset
necho Exporting recent Application errors to %TEMP%\RecentAppErrors.evtx >> "%LOGFILE%"
wevtutil qe Application /q:"*[System[(Level=2) and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]" /f:text > "%TEMP%\RecentAppErrors.txt" 2>&1

:: Final cleanup: restart Explorer one more time
necho Final restart of Explorer... >> "%LOGFILE%"
taskkill /IM explorer.exe /F >> "%LOGFILE%" 2>&1
start explorer.exe >> "%LOGFILE%" 2>&1

necho -------------------------------------------------- >> "%LOGFILE%"
echo Windows Full Repair Tool finished at %date% %time% >> "%LOGFILE%"

necho All done. Log file saved to: %LOGFILE%
echo A copy of recent application errors was saved to: %TEMP%\RecentAppErrors.txt

necho --------------------------------------------------
echo Please reboot your PC if you still see issues.
echo If the Start Menu/taksbar still freeze after several hours, check Task Manager (Ctrl+Shift+Esc) -> Processes -> sort by Memory to find potential memory leaks.

npause
exit /b 0


:: --- Improved AppX Repair (Safe Mode Compatible) ---
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -AllUsers Microsoft.Windows.StartMenuExperienceHost | Stop-Process -Force -ErrorAction SilentlyContinue" >> "%LOGFILE%" 2>&1
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -AllUsers Microsoft.Windows.StartMenuExperienceHost | Reset-AppxPackage -ErrorAction Continue" >> "%LOGFILE%" 2>&1
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -AllUsers Microsoft.Windows.ShellExperienceHost | Stop-Process -Force -ErrorAction SilentlyContinue" >> "%LOGFILE%" 2>&1
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "Get-AppxPackage -AllUsers Microsoft.Windows.ShellExperienceHost | Reset-AppxPackage -ErrorAction Continue" >> "%LOGFILE%" 2>&1
