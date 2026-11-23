@echo off
setlocal EnableDelayedExpansion

for /f "usebackq tokens=7 delims=\" %%e in (`Reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /d /f "Update Health Tools" /s ^| findstr /i /c:"CurrentVersion\Uninstall\\"`) do set "GUID=%%e"
for /f "usebackq tokens=4 delims=\" %%e in (`Reg query "HKCR\Installer\Products" /d /f "Update Health Tools" /s ^| findstr /i /c:"Installer\Products\\"`) do set "ProdID=%%e"

if "!GUID!"=="" goto :Prod
Reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\!GUID!" /f

:Prod
if "!ProdID!"=="" exit /b 0

for /f "usebackq delims=" %%e in (`Reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UpgradeCodes" /d /f "!ProdID!" /s ^| findstr /i /c:"Installer\UpgradeCodes\\"`) do Reg delete "%%e" /f
Reg delete "HKCR\Installer\Products\!ProdID!" /f
Reg delete "HKCR\Installer\Features\!ProdID!" /f
for /f "usebackq delims=" %%e in (`Reg query "HKCR\Installer\UpgradeCodes" /d /f "!ProdID!" /s ^| findstr /i /c:"Installer\UpgradeCodes\\"`) do Reg delete "%%e" /f
for /f "usebackq delims=" %%e in (`Reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components" /d /f "!ProdID!" /s ^| findstr /i /c:"S-1-5-18\Components\\"`) do Reg delete "%%e" /f
Reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\!ProdID!" /f

PowerShell -NoP -C "$k='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders'; if (Test-Path $k) { (Get-Item $k).Property | Where-Object { $_ -match 'Update Health Tools' } | ForEach-Object { Remove-ItemProperty -LiteralPath $k -Name $_ -ErrorAction SilentlyContinue } }"