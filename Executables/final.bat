@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: clear pinned taskbar shortcuts
del /f /q "%AppData%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar*"

:: remove onedrive from file explorer sidebar
Reg add "HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 0 /f

:: remove oned and msedge shortcut from startup
Reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f
for /f "tokens=1" %%a in ('Reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" ^| findstr /i "MicrosoftEdgeAutoLaunch"') do (
  Reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "%%a" /f
)

:: write cache policy
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\SCSI" ^| findstr "HKEY"') do (
    for /f "tokens=*" %%a in ('reg query "%%i" ^| findstr "HKEY"') do (
        Reg add "%%a\Device Parameters\Disk" /v CacheIsPowerProtected /t REG_DWORD /d 1 /f
        Reg add "%%a\Device Parameters\Disk" /v UserWriteCacheSetting /t REG_DWORD /d 1 /f
    )
)

:: disable copilot on taskbar
Reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f

:: configure boot settings
bcdedit /timeout 5
bcdedit /set nx optin
bcdedit /set disabledynamictick yes
bcdedit /deletevalue useplatformclock
bcdedit /deletevalue useplatformtick
bcdedit /set bootmenupolicy Legacy

:: disable DMA remapping
for /f %%i in ('Reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services" /s /f DmaRemappingCompatible ^| find /i "Services\" ') do (
	Reg add "%%i" /v "DmaRemappingCompatible" /t REG_DWORD /d "0" /f
)

Reg add "HKCU\Control Panel\Desktop" /v AutoEndTasks /t REG_SZ /d 1 /f
Reg add "HKCU\Control Panel\Desktop" /v HungAppTimeout /t REG_SZ /d 1500 /f
Reg add "HKCU\Control Panel\Desktop" /v WaitToKillTimeout /t REG_SZ /d 2500 /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v WaitToKillServiceTimeout /t REG_SZ /d 2500 /f

:: disable game bar
Reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d "0" /f 
Reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d "0" /f
Reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "GamePanelStartupTipIndex" /t REG_DWORD /d "3" /f
Reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d "0" /f 
Reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "UseNexusForGameBarEnabled" /t REG_DWORD /d "0" /f 
Reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d "0" /f 
Reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d "0" /f 
Reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v "value" /t REG_DWORD /d "0" /f 

:: configure NTFS settings
fsutil behavior set disablelastaccess 1
fsutil behavior set disable8dot3 1
fsutil behavior set disablecompression 1
fsutil quota disable C:

:: configure powershell
powershell Set-ExecutionPolicy Unrestricted -Force
setx POWERSHELL_TELEMETRY_OPTOUT 1

:: Enable Optimizations for Windowed/Borderless Games
Reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "SwapEffectUpgradeEnable=1;" /f

:: Svchost Split
Reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d "4294967295" /f

:: disable search indexing
sc stop wsearch
sc config wsearch start=disabled

:: second pass
sc stop sysmain
sc config sysmain start=disabled

:: disable FTH
reg add "HKLM\Software\Microsoft\FTH" /v Enabled /t REG_DWORD /d "0" /f

:: Session Manager
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v "DisableWpbtExecution" /t REG_DWORD /d "1" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "IdleScanInterval" /t REG_DWORD /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "SerializeTimerExpiration" /t REG_DWORD /d "1" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "TimerCheckFlags" /t REG_DWORD /d "0" /f

:: WDF
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Wdf" /v "WdfGlobalLogsDisabled" /t REG_DWORD /d "1" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Wdf" /v "WdfGlobalSleepStudyDisabled" /t REG_DWORD /d "1" /f

:: Enable HAGS
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d "2" /f

:: Get the build number from the `ver` command
for /f "tokens=6 delims=[]. " %%a in ('ver') do set version=%%a

:: Check if the version is greater than or equal to 10.0.22000 (which is the version for Windows 11)
if %version% geq 22000 (
  bcdedit /set description "SynergyOS 11"
  Reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v "Model"  /t REG_SZ /d "SOS 11" /f >NUL 2>nul
  Reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "RegisteredOrganization" /t REG_SZ /d "SynergyOS 11" /f >NUL 2>nul
) else (
  bcdedit /set description "SynergyOS 10"
  Reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation" /v "Model"  /t REG_SZ /d "SOS 10" /f >NUL 2>nul
  Reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "RegisteredOrganization" /t REG_SZ /d "SynergyOS 10" /f >NUL 2>nul
)

:: add new batch file to context menu
Reg add "HKEY_LOCAL_MACHINE\Software\Classes\.bat\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "@C:\Windows\System32\acppage.dll,-6002" /f 
Reg add "HKEY_LOCAL_MACHINE\Software\Classes\.bat\ShellNew" /v "NullFile" /t REG_SZ /d "" /f 

:: add new reg file to context menu
Reg add "HKEY_LOCAL_MACHINE\Software\Classes\.reg\ShellNew" /v "ItemName" /t REG_EXPAND_SZ /d "@C:\Windows\regedit.exe,-309" /f 
Reg add "HKEY_LOCAL_MACHINE\Software\Classes\.reg\ShellNew" /v "NullFile" /t REG_SZ /d "" /f 

:: disable ctfmon
Reg add "HKLM\SOFTWARE\Microsoft\Input" /v "InputServiceEnabled" /t REG_DWORD /d "0" /f
Reg add "HKLM\SOFTWARE\Microsoft\Input" /v "InputServiceEnabledForCCI" /t REG_DWORD /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\TextInputManagementService\Parameters" /v "ServiceDll" /t REG_EXPAND_SZ /d "%SystemRoot%\System32\MSCTF.DLL" /f

:: register .pow as a file type
Reg add "HKCR\.pow" /v "" /t REG_SZ /d "Power Plan" /f
Reg add "HKCR\.pow" /v "FriendlyTypeName" /t REG_SZ /d "Power Plan" /f
Reg add "HKCR\.pow\DefaultIcon" /v "" /t REG_EXPAND_SZ /d "%SystemRoot%\System32\powercfg.cpl,-202" /f
Reg add "HKCR\.pow\shell\Import\command" /v "" /t REG_SZ /d "powercfg /import \"%1\"" /f
