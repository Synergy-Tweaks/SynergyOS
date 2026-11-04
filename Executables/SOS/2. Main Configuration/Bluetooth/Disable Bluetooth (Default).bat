@echo off
for %%z in (
    BTAGService
    bthserv
    BthAvctpSvc
    NaturalAuthentication
    BluetoothUserService
) do (
Reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%%z" /v "Start" /t REG_DWORD /d "4" /f 
) >nul 2>&1
echo Please Restart Your Computer to Apply
pause