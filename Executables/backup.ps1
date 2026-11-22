param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath
)

$FilePath = $FilePath.Trim('"')
$dir = Split-Path $FilePath

if (!(Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

if (Test-Path $FilePath) {
    Remove-Item $FilePath -Force
}

Set-Content -Path $FilePath `
    -Value "Windows Registry Editor Version 5.00`r`n" `
    -Encoding Unicode

Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services" | ForEach-Object {
    $props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
    if ($null -eq $props) { return }
    
    if ($props.PSObject.Properties.Name -contains "Start") {
        $startValue = $props.Start
        if ($startValue -ge 0 -and $startValue -le 4) {
            Add-Content -Path $FilePath `
                -Value "[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$($_.PSChildName)]" `
                -Encoding Unicode
            Add-Content -Path $FilePath `
                -Value "`"Start`"=dword:0000000$startValue`r`n" `
                -Encoding Unicode
        }
    }
}