@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "SRC=%~dp0"

mkdir "%SYSTEMDRIVE%\Users\Default\AppData\Local\Microsoft\Windows\Shell" 2>nul
:: copy /y "%SRC%LayoutUser.xml" "%SYSTEMDRIVE%\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml" >nul
:: copy /y "%SRC%LayoutModification.json" "%SYSTEMDRIVE%\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.json" >nul

REM Dark theme into Default user hive (new profiles copy this NTUSER.DAT)
reg load "HKU\SynergyDefault" "%SYSTEMDRIVE%\Users\Default\NTUSER.DAT" >nul 2>&1
if not errorlevel 1 (
	reg add "HKU\SynergyDefault\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f >nul
	reg add "HKU\SynergyDefault\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f >nul
	reg add "HKU\SynergyDefault\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul
	reg unload "HKU\SynergyDefault" >nul 2>&1
)

REM Real users + AME OOBE hives
for /f "usebackq tokens=2 delims=\" %%A in (`reg query "HKEY_USERS" ^| findstr /r /x /c:"HKEY_USERS\\S-.*" /c:"HKEY_USERS\\AME_UserHive_[^_]*"`) do (
	reg query "HKEY_USERS\%%A" | findstr /c:"Volatile Environment" /c:"AME_UserHive_" >nul 2>&1
	if not errorlevel 1 (
		REM Dark theme on live/AME hives (ISO OOBE often misses HKCU)
		reg add "HKU\%%A\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f >nul 2>&1
		reg add "HKU\%%A\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d 0 /f >nul 2>&1
		reg add "HKU\%%A\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1

		REM Wipe pin cache (Sapphire Favorites clear + full Taskband reset)
		reg delete "HKU\%%A\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /v "Favorites" /f >nul 2>&1
		reg delete "HKU\%%A\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /v "FavoritesResolve" /f >nul 2>&1
		reg delete "HKU\%%A\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" /f >nul 2>&1
		reg delete "HKU\%%A\Software\Microsoft\Windows\CurrentVersion\Start" /v "Config" /f >nul 2>&1

::		for /f "usebackq tokens=3* delims= " %%B in (`reg query "HKU\%%A\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "AppData" 2^>nul ^| findstr /R /X /C:".*AppData[ ]*REG_SZ[ ].*"`) do (
::			del /f /q "%%C\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*" >nul 2>&1
::		)

::		for /f "usebackq tokens=3* delims= " %%B in (`reg query "HKU\%%A\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v "Local AppData" 2^>nul ^| findstr /R /X /C:".*Local AppData[ ]*REG_SZ[ ].*"`) do (
::			mkdir "%%C\Microsoft\Windows\Shell" 2>nul
::			copy /y "%SRC%LayoutUser.xml" "%%C\Microsoft\Windows\Shell\LayoutModification.xml" >nul
::			copy /y "%SRC%LayoutModification.json" "%%C\Microsoft\Windows\Shell\LayoutModification.json" >nul

::			for /f "usebackq delims=" %%D in (`dir /b "%%C\Packages" /a:d 2^>nul ^| findstr /c:"Microsoft.Windows.StartMenuExperienceHost"`) do (
::				for /f "usebackq delims=" %%E in (`dir /b "%%C\Packages\%%D\LocalState" /a:-d 2^>nul ^| findstr /R /c:"start.\.bin" /c:"start\.bin"`) do (
::					del /q /f "%%C\Packages\%%D\LocalState\%%E" >nul 2>&1
::				)
::			)
::		)

::		for /f "usebackq delims=" %%C in (`reg query "HKU\%%A\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount" 2^>nul ^| findstr /c:"start.tilegrid"`) do (
::			reg delete "%%C" /f >nul 2>&1
::		)
	)
)

endlocal
exit /b 0
