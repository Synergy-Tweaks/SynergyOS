@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "NICCLASS=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}"
set "VIRTUAL=microsoft miniport virtual kernel debug bluetooth teredo tunnel loopback tap- openvpn wireguard vmware virtualbox hyper-v npcap ras async pppoe wintun zerotier hamachi tailscale nordlynx"

:: Discovery / topology bindings off
powershell.exe -NoProfile -Command "Disable-NetAdapterBinding -Name '*' -ComponentID ms_lldp,ms_lltdio,ms_implat,ms_rspndr -ErrorAction SilentlyContinue" >nul 2>&1
powershell.exe -NoProfile -Command "Set-NetOffloadGlobalSetting -PacketCoalescingFilter Disabled -ErrorAction SilentlyContinue" >nul 2>&1
powershell.exe -NoProfile -Command "Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Disabled -ErrorAction SilentlyContinue" >nul 2>&1

:: Default PnP: do not allow Windows to turn the device off
reg add "HKLM\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" /v "DefaultPnPCapabilities" /t REG_DWORD /d 24 /f >nul 2>&1

for /f "delims=" %%n in ('reg query "%NICCLASS%" 2^>nul ^| findstr /r /c:"\\[0-9][0-9][0-9][0-9]$"') do (
	call :Adapter "%%n"
)

endlocal
exit /b 0


:Adapter
set "AKEY=%~1"
set "ADESC="
for /f "tokens=2,*" %%a in ('reg query "%AKEY%" /v DriverDesc 2^>nul ^| findstr /i "DriverDesc"') do set "ADESC=%%b"
if not defined ADESC goto :eof

for %%v in (%VIRTUAL%) do (
	if /i not "!ADESC:%%v=!"=="!ADESC!" goto :eof
)

:: Prefer adapters currently present; if Get-NetAdapter is unavailable, still tweak by class key
set "APRESENT="
for /f "usebackq delims=" %%s in (`powershell.exe -NoProfile -Command "$a=Get-NetAdapter -InterfaceDescription $env:ADESC -EA SilentlyContinue | Select-Object -First 1; if($a){'1'}"`) do set "APRESENT=%%s"
if not defined APRESENT goto :eof

reg add "%AKEY%" /v "PnPCapabilities" /t REG_DWORD /d 24 /f >nul 2>&1

:: Standard Settings
call :SetParam "*EEE"                         EXACT 0
call :SetParam "*FlowControl"                 EXACT 0
call :SetParam "*InterruptModeration"         EXACT 0
call :SetParam "*JumboPacket"                 CAP 1514
call :SetParam "*LsoV2IPv4"                   EXACT 0
call :SetParam "*LsoV2IPv6"                   EXACT 0
call :SetParam "*RscIPv4"                     EXACT 0
call :SetParam "*RscIPv6"                     EXACT 0
call :SetParam "*RSS"                         EXACT 1
call :SetParam "*ReceiveBuffers"              CAP 1024
call :SetParam "*TransmitBuffers"             CAP 512
call :SetParam "*WakeOnMagicPacket"           EXACT 0
call :SetParam "*WakeOnPattern"               EXACT 0
call :SetParam "*ModernStandbyWoLMagicPacket" EXACT 0
call :SetParam "*PMARPOffload"                EXACT 0
call :SetParam "*PMNSOffload"                 EXACT 0
call :SetParam "*SelectiveSuspend"            EXACT 0
call :SetParam "*DeviceSleepOnDisconnect"     EXACT 0

:: Realtek / common power-save
call :SetParam "EnableGreenEthernet"          EXACT 0
call :SetParam "AdvancedEEE"                  EXACT 0
call :SetParam "PowerSavingMode"              EXACT 0
call :SetParam "PowerDownPll"                 EXACT 0
call :SetParam "AutoPowerSaveMode"            EXACT 0
call :SetParam "AutoPowerSaveModeEnabled"     EXACT 0
call :SetParam "GigaLite"                     EXACT 0
call :SetParam "AutoDisableGigabit"           EXACT 0
call :SetParam "S5WakeOnLan"                  EXACT 0
call :SetParam "WolShutdownLinkSpeed"         EXACT 2

:: Intel power-save
call :SetParam "EnablePME"                    EXACT 0
call :SetParam "ULPMode"                      EXACT 0
call :SetParam "SipsEnabled"                  EXACT 0
call :SetParam "ReduceSpeedOnPowerDown"       EXACT 0
call :SetParam "ITR"                          EXACT 0
goto :eof


:: SetParam keyword mode [value]
::   EXACT v  set to v if the driver allows it
::   MIN      lowest allowed value
::   CAP v    highest allowed value, capped at v
:: Missing keywords are skipped (NIC-specific detection).
:SetParam
set "KW=%~1"
set "MODE=%~2"
set "TV=%~3"
set "FP=%AKEY%\Ndi\Params\%KW%"
reg query "%FP%" >nul 2>&1 || goto :eof

set "PTYPE="
for /f "tokens=3" %%t in ('reg query "%FP%" /v type 2^>nul ^| findstr /i "REG_SZ"') do set "PTYPE=%%t"

set "VAL="
set "BEST="
set "PMIN="
set "PMAX="

if /i "!PTYPE!"=="enum" goto SetParamEnum
if not defined PTYPE goto SetParamEnum

for /f "tokens=3" %%m in ('reg query "%FP%" /v min 2^>nul ^| findstr /i "REG_SZ"') do set "PMIN=%%m"
for /f "tokens=3" %%m in ('reg query "%FP%" /v max 2^>nul ^| findstr /i "REG_SZ"') do set "PMAX=%%m"
if /i "!MODE!"=="MIN" (
	if not defined PMIN goto :eof
	set "VAL=!PMIN!"
) else (
	set "VAL=!TV!"
	if defined PMIN if !VAL! LSS !PMIN! (
		if /i "!MODE!"=="CAP" goto :eof
		set "VAL=!PMIN!"
	)
	if defined PMAX if !VAL! GTR !PMAX! set "VAL=!PMAX!"
)
goto SetParamWrite

:SetParamEnum
if /i "!MODE!"=="EXACT" (
	reg query "%FP%\Enum" /v "!TV!" >nul 2>&1 || goto :eof
	set "VAL=!TV!"
) else (
	for /f "tokens=1" %%e in ('reg query "%FP%\Enum" 2^>nul ^| findstr /i "REG_SZ"') do call :PickEnum "%%e"
	if not defined BEST goto :eof
	set "VAL=!BEST!"
)

:SetParamWrite
reg add "%AKEY%" /v "%KW%" /t REG_SZ /d "!VAL!" /f >nul 2>&1
goto :eof


:PickEnum
set "C=%~1"
for /f "delims=0123456789" %%z in ("%C%") do goto :eof
if /i "!MODE!"=="MIN" (
	if not defined BEST (set "BEST=%C%") else if %C% LSS !BEST! set "BEST=%C%"
	goto :eof
)
if %C% GTR !TV! goto :eof
if not defined BEST (set "BEST=%C%") else if %C% GTR !BEST! set "BEST=%C%"
goto :eof
