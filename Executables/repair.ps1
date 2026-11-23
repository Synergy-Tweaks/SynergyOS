# Undo the tweaks that earlier versions of this playbook applied.
# Runs on every apply, including an upgrade over an older install.

$ErrorActionPreference = 'SilentlyContinue'

# 1. WebView2 runtime install/update was blocked through the EdgeUpdate policy
$edgeUpdatePolicy = 'HKLM:\Software\Policies\Microsoft\EdgeUpdate'
foreach ($v in 'Install{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}', 'Update{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}') {
    Remove-ItemProperty -Path $edgeUpdatePolicy -Name $v
}

# 2. NIC offloads and jumbo frame went back to their driver defaults
$virtual = 'virtual|miniport|hyper-v|bluetooth|teredo|tunnel|loopback|openvpn|wireguard|vmware|virtualbox|npcap|pppoe|wintun|zerotier|hamachi|tailscale|nordlynx|wi-fi direct|kernel debug'
Get-NetAdapter -Physical | Where-Object { $_.InterfaceDescription -notmatch $virtual } | ForEach-Object {
    $name = $_.Name
    $has = @(Get-NetAdapterAdvancedProperty -Name $name | ForEach-Object { $_.RegistryKeyword })
    foreach ($k in '*LsoV2IPv4', '*LsoV2IPv6', '*RscIPv4', '*RscIPv6', '*PMARPOffload') {
        if ($has -contains $k) { Set-NetAdapterAdvancedProperty -Name $name -RegistryKeyword $k -RegistryValue 1 }
    }
    if ($has -contains '*JumboPacket') { Set-NetAdapterAdvancedProperty -Name $name -RegistryKeyword '*JumboPacket' -RegistryValue 1514 }
}
Enable-NetAdapterBinding -Name '*' -ComponentID ms_lldp, ms_lltdio, ms_implat, ms_rspndr
Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Enabled -PacketCoalescingFilter Enabled

# 3. PnP override that stopped Windows from power managing the adapter
$nicClass = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}'
Get-ChildItem $nicClass | ForEach-Object { Remove-ItemProperty -Path $_.PSPath -Name 'PnPCapabilities' }
Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\NDIS\Parameters' -Name 'DefaultPnPCapabilities'

# 4. a runtime that was never installed has to come back from Microsoft
$webview = "${env:ProgramFiles(x86)}\Microsoft\EdgeWebView\Application"
if (-not (Test-Path $webview) -or -not (Get-ChildItem $webview)) {
    $setup = Join-Path $env:TEMP 'MicrosoftEdgeWebview2Setup.exe'
    try {
        Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/p/?LinkId=2124703' -OutFile $setup -UseBasicParsing
        Start-Process -FilePath $setup -ArgumentList '/silent', '/install' -Wait
    } catch {
        Write-Output "WebView2 runtime could not be installed: $($_.Exception.Message)"
    }
}
