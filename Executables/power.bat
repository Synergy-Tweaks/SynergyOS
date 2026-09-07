@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

for %%i in (
  EnhancedPowerManagementEnabled
  AllowIdleIrpInD3
  EnableSelectiveSuspend 
  DeviceSelectiveSuspended
  SelectiveSuspendEnabled 
  SelectiveSuspendOn 
  EnumerationRetryCount 
  ExtPropDescSemaphore 
  WaitWakeEnabled
  D3ColdSupported 
  WdfDirectedPowerTransitionEnable 
  EnableIdlePowerManagement 
  IdleInWorkingState
) do for /f %%a in ('Reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /s /f "%%i"^| findstr "HKEY"') do Reg add "%%a" /v "%%i" /t REG_DWORD /d "0" /f  

powercfg /h off

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EnergyEstimationEnabled" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "SleepStudyDisabled" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "CoalescingFlushInterval" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "CoalescingTimerInterval" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "EventProcessorEnabled" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "FxAccountingTelemetryDisabled" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "SleepstudyAccountingEnabled" /t REG_DWORD /d "0" /f

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "MSDisabled" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "PlatformAoAcOverride" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "PlatformRoleOverride" /t REG_DWORD /d "0" /f

reg add "HKLM\SYSTEM\CurrentControlSet\Control\usbflags" /v "DisableHCS0Idle" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\usbflags" /v "Allow64KLowOrFullSpeedControlTransfers" /t REG_DWORD /d "1" /f

reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IdlePowerMode" /t REG_DWORD /d "0" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "DisableDSTThrottle" /t REG_DWORD /d "1" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v "StorageD3InModernStandby" /t REG_DWORD /d "0" /f

reg add "HKLM\SYSTEM\CurrentControlSet\Services\WmiAcpi" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\AcpiPmi" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\acpitime" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\GpuEnergyDrv" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\GraphicsPerfSvc" /v "Start" /t REG_DWORD /d "4" /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\intelpmt" /v "Start" /t REG_DWORD /d "4" /f

powershell "Set-CimInstance -Query 'SELECT InstanceName FROM MSPower_DeviceWakeEnable WHERE (Enable = True)' -Namespace 'root\WMI' -Property @{Enable = $false}"
powershell "Set-CimInstance -Query 'SELECT InstanceName FROM MSPower_DeviceEnable WHERE (Enable = True)' -Namespace 'root\WMI' -Property @{Enable = $false}"

powercfg -delete 77777777-7777-7777-7777-777777777777
powercfg -import "%WinDir%\sos.pow" 77777777-7777-7777-7777-777777777777
powercfg -setactive 77777777-7777-7777-7777-777777777777
