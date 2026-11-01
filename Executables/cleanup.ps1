# Windows Update holds SoftwareDistribution open
Stop-Service -Name wuauserv, bits -Force -ErrorAction SilentlyContinue

$foldersToRemove = @(
    "CbsTemp",
    "Logs",
    "SoftwareDistribution",
    "System32\LogFiles",
    "System32\SleepStudy",
    "System32\sru",
    "System32\WDI\LogFiles",
    "SystemTemp",
    "Temp"

    # "WinSxS\Backup"
    # "Panther",
    # "Prefetch"
)

foreach ($folderName in $foldersToRemove) {
    $folderPath = Join-Path $env:SystemRoot $folderName
    if (Test-Path $folderPath) {
        # locked files (CBS.log, in-use ETL logs) are expected, skip them silently
        Remove-Item -Path "$folderPath\*" -Force -Recurse -ErrorAction SilentlyContinue
    }
}

Stop-Process -Name 'StartMenuExperienceHost' -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Start" -Name "Config" -Force -ErrorAction SilentlyContinue

Get-ChildItem "$env:LOCALAPPDATA\Packages" -Directory |
    Where-Object { $_.Name -match "Microsoft.Windows.StartMenuExperienceHost" } |
    ForEach-Object {
        Remove-Item "$env:LOCALAPPDATA\Packages\$($_.Name)\LocalState" -Recurse -Force -ErrorAction SilentlyContinue
    }

Get-ChildItem "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount" -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match "start.tilegrid" } |
    Remove-Item -Force
Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Start" -Name Config -Force -ErrorAction SilentlyContinue
