@echo off
REM ISO OOBE RunOnce catch-up — re-apply Synergy wallpaper after first logon
set "WP=%SystemRoot%\Web\Wallpaper"
set "PS1=%WP%\wallpaper.ps1"
set "IMG=%WP%\sos.png"
if not exist "%PS1%" exit /b 1
if not exist "%IMG%" exit /b 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Mode Desktop -ImagePath "%IMG%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Mode LockScreen -ImagePath "%IMG%"
exit /b 0
