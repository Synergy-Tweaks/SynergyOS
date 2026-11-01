@echo off
setlocal enabledelayedexpansion

set "MINSUDO=%windir%\MinSudo.exe"

for %%z in (
      MsSecCore
      MsSecFlt
      MsSecWfp
      SecurityHealthService
      Sense
      WdBoot
      WdFilter
      WdNisDrv
      WdNisSvc
      WinDefend
      wscsvc
      MDCoreSvc
      SgrmAgent
      SgrmBroker
      webthreatdefsvc
      webthreatdefusersvc
) do (
    "%MINSUDO%" --NoLogo --TrustedInstaller --Privileged cmd /c "Reg.exe add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%%z" /v "Start" /t REG_DWORD /d "4" /f" >nul 2>&1
)

endlocal
exit /b 0
