@echo off
setlocal EnableExtensions

for %%P in ("MicrosoftEdgeUpdate" "msedge") do (
    taskkill /f /im "%%~P.exe" 2>nul
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Process -Name 'MicrosoftEdge*' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$setupProcesses = Get-CimInstance Win32_Process -Filter \"name='setup.exe'\" -ErrorAction SilentlyContinue | Where-Object { $_.ExecutablePath -and $_.ExecutablePath -like '*\\Edge*' }; foreach ($p in $setupProcesses) { Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue }"

powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like '*MicrosoftEdge*' } | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue"

for %%S in ("edgeupdate" "edgeupdatem" "MicrosoftEdgeElevationService") do (
    sc stop "%%~S" >nul 2>&1
    sc delete "%%~S" >nul 2>&1
)


powershell -NoProfile -ExecutionPolicy Bypass -Command "$packages = @('Microsoft.MicrosoftEdge.Stable*','Microsoft.MicrosoftEdgeDevToolsClient*'); foreach ($p in $packages) { Get-AppxPackage -AllUsers -Name $p -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue }"


if exist "%SystemDrive%\Users\Public\Desktop\Microsoft Edge.lnk" del /f /q "%SystemDrive%\Users\Public\Desktop\Microsoft Edge.lnk" 2>nul
if exist "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" del /f /q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" 2>nul
if exist "%windir%\system32\MicrosoftEdgeBCHost.exe" del /f /q "%windir%\system32\MicrosoftEdgeBCHost.exe" 2>nul
if exist "%windir%\system32\MicrosoftEdgeCP.exe" del /f /q "%windir%\system32\MicrosoftEdgeCP.exe" 2>nul
if exist "%windir%\system32\MicrosoftEdgeDevTools.exe" del /f /q "%windir%\system32\MicrosoftEdgeDevTools.exe" 2>nul
if exist "%windir%\system32\MicrosoftEdgeSH.exe" del /f /q "%windir%\system32\MicrosoftEdgeSH.exe" 2>nul
for %%F in ("%windir%\system32\Tasks\MicrosoftEdge*") do if exist "%%~fF" del /f /q "%%~fF" 2>nul
for /d %%D in ("%windir%\system32\Tasks\MicrosoftEdge*") do if exist "%%~fD" rd /s /q "%%~fD" 2>nul

if exist "%ProgramFiles(x86)%\Microsoft\Edge" rd /s /q "%ProgramFiles(x86)%\Microsoft\Edge" 2>nul
if exist "%ProgramFiles(x86)%\Microsoft\EdgeUpdate" rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeUpdate" 2>nul
if exist "%ProgramFiles(x86)%\Microsoft\EdgeCore" rd /s /q "%ProgramFiles(x86)%\Microsoft\EdgeCore" 2>nul

reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMigratedBrowserPin" /f 2>nul
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f 2>nul
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" /f 2>nul
reg delete "HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate" /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}" /f 2>nul
reg delete "HKCR\CLSID\{1FCBE96C-1697-43AF-9140-2897C7C69767}" /f 2>nul
reg delete "HKCR\AppID\{1FCBE96C-1697-43AF-9140-2897C7C69767}" /f 2>nul
reg delete "HKCR\Interface\{C9C2B807-7731-4F34-81B7-44FF7779522B}" /f 2>nul
reg delete "HKCR\TypeLib\{C9C2B807-7731-4F34-81B7-44FF7779522B}" /f 2>nul
reg delete "HKCR\MSEdgeHTM" /f 2>nul
reg delete "HKCR\MSEdgePDF" /f 2>nul
reg delete "HKCR\MSEdgeMHT" /f 2>nul
reg delete "HKCR\AppID\{628ACE20-B77A-456F-A88D-547DB6CEEDD5}" /f 2>nul
reg delete "HKLM\SOFTWARE\Clients\StartMenuInternet\Microsoft Edge" /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" /f 2>nul
reg delete "HKCR\AppID\ie_to_edge_bho.dll" /f 2>nul
reg delete "HKCR\AppID\{31575964-95F7-414B-85E4-0E9A93699E13}" /f 2>nul
reg delete "HKCR\CLSID\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}" /f 2>nul
reg delete "HKCR\WOW6432Node\CLSID\{1FD49718-1D00-4B19-AF5F-070AF6D5D54C}" /f 2>nul
reg delete "HKCR\ie_to_edge_bho.IEToEdgeBHO" /f 2>nul
reg delete "HKCR\ie_to_edge_bho.IEToEdgeBHO.1" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\Edge" /f 2>nul


reg delete "HKLM\SOFTWARE\RegisteredApplications" /v "Microsoft Edge" /f 2>nul
reg delete "HKCR\.htm\OpenWithProgIds" /v "MSEdgeHTM" /f 2>nul
reg delete "HKCR\.html\OpenWithProgIds" /v "MSEdgeHTM" /f 2>nul
reg delete "HKCR\.shtml\OpenWithProgids" /v "MSEdgeHTM" /f 2>nul
reg delete "HKCR\.svg\OpenWithProgIds" /v "MSEdgeHTM" /f 2>nul
reg delete "HKCR\.xht\OpenWithProgIds" /v "MSEdgeHTM" /f 2>nul
reg delete "HKCR\.xhtml\OpenWithProgIds" /v "MSEdgeHTM" /f 2>nul
reg delete "HKCR\.webp\OpenWithProgids" /v "MSEdgeHTM" /f 2>nul
reg delete "HKCR\.xml\OpenWithProgIds" /v "MSEdgeHTM" /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "MSEdgeHTM_microsoft-edge" /f 2>nul
reg delete "HKLM\SOFTWARE\Microsoft\Internet Explorer\Main\EnterpriseMode" /v "MSEdgePath" /f 2>nul
reg delete "HKCU\SOFTWARE\RegisteredApplications" /v "Microsoft Edge" /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.htm\OpenWithProgids" /v "MSEdgeHTM" /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.html\OpenWithProgids" /v "MSEdgeHTM" /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.shtml\OpenWithProgids" /v "MSEdgeHTM" /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.svg\OpenWithProgids" /v "MSEdgeHTM" /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.xht\OpenWithProgids" /v "MSEdgeHTM" /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.xhtml\OpenWithProgids" /v "MSEdgeHTM" /f 2>nul
reg delete "HKCU\SOFTWARE\Classes\.webp\OpenWithProgids" /v "MSEdgeHTM" /f 2>nul
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "MSEdgeHTM_microsoft-edge" /f 2>nul


reg add "HKLM\Software\Policies\Microsoft\EdgeUpdate" /v "Install{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\Software\Policies\Microsoft\EdgeUpdate" /v "Update{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\Software\Policies\Microsoft\EdgeUpdate" /v "Update{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\Software\Policies\Microsoft\EdgeUpdate" /v "Update{2CD8A007-E189-409D-A2C8-9AF4EF3C72AA}" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\Software\Policies\Microsoft\EdgeUpdate" /v "Update{65C35B14-6C1D-4122-AC46-7148CC9D6497}" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\Software\Policies\Microsoft\EdgeUpdate" /v "Update{0D50BFEC-CD6A-4F9A-964C-C7416E3ACB10}" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\Software\Policies\Microsoft\EdgeUpdate" /v "Install{65C35B14-6C1D-4122-AC46-7148CC9D6497}" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\Software\Policies\Microsoft\EdgeUpdate" /v "InstallDefault" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\Software\Policies\Microsoft\EdgeUpdate" /v "CreateDesktopShortcutDefault" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\Software\Policies\Microsoft\EdgeUpdate" /v "UpdateDefault" /t REG_DWORD /d 0 /f 2>nul
reg add "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /v "DoNotUpdateToEdgeWithChromium" /t REG_DWORD /d 1 /f 2>nul
reg add "HKLM\Software\OEM\MicrosoftEdge" /v "AutoLaunchOnLogonBehavior" /t REG_DWORD /d 0 /f 2>nul

powershell -NoProfile -ExecutionPolicy Bypass -Command "$pkg = Get-WindowsPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like '*Internet-Browser-Deployment*' }; if ($pkg) { $pkg | Remove-WindowsPackage -Online -NoRestart -ErrorAction SilentlyContinue }"
