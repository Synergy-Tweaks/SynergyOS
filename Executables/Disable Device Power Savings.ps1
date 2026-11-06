# Created by Kwanteks, https://dsc.gg/kwanteks, https://youtube.com/@kwanteks
$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', "`"$PSCommandPath`""
    )
    exit 0
}

Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable -ErrorAction SilentlyContinue |
    Where-Object { $_.Enable } |
    ForEach-Object {
        $_.Enable = $false
        Set-CimInstance -CimInstance $_ -ErrorAction SilentlyContinue
    }
