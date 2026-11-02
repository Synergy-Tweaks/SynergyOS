@echo off
REM ISO OOBE RunOnce catch-up — dark theme + wallpaper after first real-user logon
set "WP=%SystemRoot%\Web\Wallpaper"
set "PS1=%WP%\wallpaper.ps1"
set "IMG=%WP%\sos.png"

REM Dark theme (AME OOBE often leaves HKCU light; Sapphire ISOInjection does the same catch-up)
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f >nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f >nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul

if not exist "%PS1%" exit /b 1
if not exist "%IMG%" exit /b 1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Mode Desktop -ImagePath "%IMG%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Mode LockScreen -ImagePath "%IMG%"
exit /b 0
