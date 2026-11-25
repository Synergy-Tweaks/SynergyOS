#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

$SystemProfile = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
$MmcssService  = 'HKLM:\SYSTEM\CurrentControlSet\Services\MMCSS'
$LogDirectory  = 'C:\SOS\Logs'
$LogPath       = Join-Path $LogDirectory 'mmcss.log'

if (-not (Test-Path -LiteralPath $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}

function Write-MmcssLog {
    param([string]$Message)
    Add-Content -LiteralPath $LogPath -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message)
}

function Set-RegistryValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('DWord', 'String')][string]$Type,
        [Parameter(Mandatory)]$Value
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    Set-ItemProperty -LiteralPath $Path -Name $Name -Type $Type -Value $Value -Force
}

function Get-ExpandedDriverPath {
    param([string]$ServiceName)

    if ([string]::IsNullOrWhiteSpace($ServiceName)) { return $null }

    $raw = (Get-ItemProperty -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName" -Name ImagePath -ErrorAction SilentlyContinue).ImagePath
    if (-not $raw) { return $null }

    $path = [Environment]::ExpandEnvironmentVariables([string]$raw).Trim()

    if ($path.StartsWith('"')) {
        $end = $path.IndexOf('"', 1)
        if ($end -gt 1) { $path = $path.Substring(1, $end - 1) }
    } else {
        $path = ($path -split '\s+', 2)[0]
    }

    if ($path.StartsWith('\??\')) { $path = $path.Substring(4) }
    if ($path.StartsWith('\\?\')) { $path = $path.Substring(4) }

    if ($path -match '^(?i)\\SystemRoot\\') {
        $path = Join-Path $env:SystemRoot $path.Substring(12)
    } elseif ($path -match '^(?i)System32\\') {
        $path = Join-Path $env:SystemRoot $path
    } elseif (-not [IO.Path]::IsPathRooted($path)) {
        $path = Join-Path $env:SystemRoot $path
    }

    return $path
}

function ConvertFrom-Rva {
    param(
        [byte[]]$Image,
        [uint32]$Rva,
        [int]$SectionTable,
        [int]$Sections
    )

    for ($i = 0; $i -lt $Sections; $i++) {
        $off = $SectionTable + ($i * 40)
        if (($off + 40) -gt $Image.Length) { break }

        $virtSize = [BitConverter]::ToUInt32($Image, $off + 8)
        $virtAddr = [BitConverter]::ToUInt32($Image, $off + 12)
        $rawSize  = [BitConverter]::ToUInt32($Image, $off + 16)
        $rawPtr   = [BitConverter]::ToUInt32($Image, $off + 20)
        $span     = [Math]::Max([uint64]$virtSize, [uint64]$rawSize)

        if ([uint64]$Rva -ge [uint64]$virtAddr -and [uint64]$Rva -lt ([uint64]$virtAddr + $span)) {
            $fileOff = [uint64]$rawPtr + ([uint64]$Rva - [uint64]$virtAddr)
            if ($fileOff -lt [uint64]$Image.Length) { return [int]$fileOff }
        }
    }

    return $null
}

function Read-CString {
    param([byte[]]$Image, [int]$Offset)

    if ($Offset -lt 0 -or $Offset -ge $Image.Length) { return $null }

    $end = $Offset
    while ($end -lt $Image.Length -and $Image[$end] -ne 0 -and ($end - $Offset) -lt 512) { $end++ }
    if ($end -le $Offset) { return $null }

    return [Text.Encoding]::ASCII.GetString($Image, $Offset, $end - $Offset)
}

function Get-PeImportedModules {
    param([byte[]]$Image)

    try {
        if ($Image.Length -lt 256 -or $Image[0] -ne 0x4D -or $Image[1] -ne 0x5A) { return @() }

        $pe = [BitConverter]::ToInt32($Image, 0x3C)
        if ($pe -lt 0 -or ($pe + 24) -gt $Image.Length) { return @() }
        if ([BitConverter]::ToUInt32($Image, $pe) -ne 0x00004550) { return @() }

        $sectionCount = [BitConverter]::ToUInt16($Image, $pe + 6)
        $optSize      = [BitConverter]::ToUInt16($Image, $pe + 20)
        $optOff       = $pe + 24
        if (($optOff + $optSize) -gt $Image.Length) { return @() }

        $magic = [BitConverter]::ToUInt16($Image, $optOff)
        $ddOff = if ($magic -eq 0x10B) { $optOff + 96 } elseif ($magic -eq 0x20B) { $optOff + 112 } else { return @() }
        if (($ddOff + 16) -gt $Image.Length) { return @() }

        $importRva  = [BitConverter]::ToUInt32($Image, $ddOff + 8)
        $importSize = [BitConverter]::ToUInt32($Image, $ddOff + 12)
        if ($importRva -eq 0) { return @() }

        $secTable = $optOff + $optSize
        $impOff   = ConvertFrom-Rva -Image $Image -Rva $importRva -SectionTable $secTable -Sections $sectionCount
        if ($null -eq $impOff) { return @() }

        $names = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        $cursor = $impOff
        $limit  = if ($importSize -gt 0) { [Math]::Min($Image.Length, $impOff + [int]$importSize) } else { $Image.Length }

        while (($cursor + 20) -le $limit) {
            $oft  = [BitConverter]::ToUInt32($Image, $cursor)
            $time = [BitConverter]::ToUInt32($Image, $cursor + 4)
            $fwd  = [BitConverter]::ToUInt32($Image, $cursor + 8)
            $name = [BitConverter]::ToUInt32($Image, $cursor + 12)
            $ft   = [BitConverter]::ToUInt32($Image, $cursor + 16)

            if (($oft -bor $time -bor $fwd -bor $name -bor $ft) -eq 0) { break }

            $nameOff = ConvertFrom-Rva -Image $Image -Rva $name -SectionTable $secTable -Sections $sectionCount
            if ($null -ne $nameOff) {
                $module = Read-CString -Image $Image -Offset $nameOff
                if ($module) { [void]$names.Add($module.ToLowerInvariant()) }
            }

            $cursor += 20
        }

        return @($names)
    } catch {
        return @()
    }
}

function Get-AdapterServiceName {
    param([string]$ClassKey)

    if (-not $ClassKey -or -not (Test-Path -LiteralPath $ClassKey)) { return $null }

    $service = (Get-ItemProperty -LiteralPath (Join-Path $ClassKey 'Ndi') -Name Service -ErrorAction SilentlyContinue).Service
    if (-not $service) {
        $service = (Get-ItemProperty -LiteralPath $ClassKey -Name Service -ErrorAction SilentlyContinue).Service
    }
    if (-not $service) { return $null }

    return ([string]$service).Trim().TrimEnd([char]'.')
}

function Resolve-AdapterDriverKind {
    param(
        [string]$ClassKey,
        [string]$AdapterName
    )

    $service = Get-AdapterServiceName -ClassKey $ClassKey
    if (-not $service) { return $null }

    $driverPath = Get-ExpandedDriverPath -ServiceName $service
    if ($driverPath -and (Test-Path -LiteralPath $driverPath)) {
        try {
            $bytes = [IO.File]::ReadAllBytes($driverPath)
            $imports = @(Get-PeImportedModules -Image $bytes)

            if ($imports -contains 'netadaptercx.sys') { return 'NetAdapterCx' }
            if ($imports -contains 'ndis.sys') { return 'NDIS' }

            $ascii = [Text.Encoding]::ASCII.GetString($bytes)
            if ($ascii -match '(?i)netadaptercx(?:\.sys)?') { return 'NetAdapterCx' }
            if ($ascii -match '(?i)ndis\.sys') { return 'NDIS' }

            $unicode = [Text.Encoding]::Unicode.GetString($bytes)
            if ($unicode -match '(?i)netadaptercx(?:\.sys)?') { return 'NetAdapterCx' }
            if ($unicode -match '(?i)ndis\.sys') { return 'NDIS' }
        } catch { }
    }

    $props = Get-ItemProperty -LiteralPath $ClassKey -ErrorAction SilentlyContinue
    if ($props -and ($props.PSObject.Properties.Name -contains 'InfPath') -and $props.InfPath) {
        $inf = Join-Path "$env:SystemRoot\INF" ([string]$props.InfPath)
        if (Test-Path -LiteralPath $inf) {
            try {
                $text = Get-Content -LiteralPath $inf -Raw -ErrorAction Stop
                if ($text -match '(?i)netadaptercx(?:\.sys)?') { return 'NetAdapterCx' }
            } catch { }
        }
    }

    if ($AdapterName) {
        $idle = Get-NetAdapterAdvancedProperty -Name $AdapterName -AllProperties -ErrorAction SilentlyContinue |
            Where-Object { $_.RegistryKeyword -eq '*IdleRestriction' } |
            Select-Object -First 1
        if ($idle) { return 'NetAdapterCx' }
    }

    if ($driverPath -and (Test-Path -LiteralPath $driverPath)) { return 'NDIS' }
    return $null
}

function Get-DriverKindForAdapter {
    param(
        [string]$PnpDeviceId,
        [string]$AdapterName
    )

    if (-not $PnpDeviceId) { return $null }

    $driver = (Get-ItemProperty -LiteralPath "HKLM:\SYSTEM\CurrentControlSet\Enum\$PnpDeviceId" -Name Driver -ErrorAction SilentlyContinue).Driver
    if (-not $driver) { return $null }

    return Resolve-AdapterDriverKind -ClassKey "HKLM:\SYSTEM\CurrentControlSet\Control\Class\$driver" -AdapterName $AdapterName
}

function Select-PrimaryPhysicalAdapter {
    $adapters = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue)
    if ($adapters.Count -eq 0) {
        $adapters = @(Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.HardwareInterface })
    }
    if ($adapters.Count -eq 0) { return $null }

    $byIndex = @{}
    foreach ($a in $adapters) { $byIndex[[int]$a.ifIndex] = $a }

    $candidates = @()
    foreach ($prefix in '0.0.0.0/0', '::/0') {
        foreach ($route in @(Get-NetRoute -DestinationPrefix $prefix -ErrorAction SilentlyContinue)) {
            $idx = [int]$route.ifIndex
            if (-not $byIndex.ContainsKey($idx)) { continue }

            $metric = 0
            $ipIf = Get-NetIPInterface -InterfaceIndex $idx -AddressFamily $route.AddressFamily -ErrorAction SilentlyContinue |
                Sort-Object InterfaceMetric |
                Select-Object -First 1
            if ($ipIf) { $metric = [int]$ipIf.InterfaceMetric }

            $candidates += [pscustomobject]@{
                Adapter         = $byIndex[$idx]
                Source          = 'DefaultRoute'
                Prefix          = $prefix
                RouteMetric     = [int]$route.RouteMetric
                InterfaceMetric = $metric
                TotalMetric     = [int]$route.RouteMetric + $metric
            }
        }
    }

    if ($candidates.Count -gt 0) {
        return ($candidates |
            Sort-Object @{ Expression = { if ($_.Adapter.Status -eq 'Up') { 0 } else { 1 } } },
                        @{ Expression = { $_.TotalMetric } },
                        @{ Expression = { $_.RouteMetric } },
                        @{ Expression = { $_.Adapter.ifIndex } } |
            Select-Object -First 1)
    }

    $fallback = $adapters |
        Sort-Object @{ Expression = { if ($_.Status -eq 'Up') { 0 } else { 1 } } },
                    @{ Expression = { $_.ifIndex } } |
        Select-Object -First 1

    if (-not $fallback) { return $null }

    return [pscustomobject]@{
        Adapter         = $fallback
        Source          = 'PhysicalFallback'
        Prefix          = $null
        RouteMetric     = $null
        InterfaceMetric = $null
        TotalMetric     = $null
    }
}

function Get-PnpIdForInterface {
    param([int]$IfIndex)

    $cim = Get-CimInstance -Namespace 'root\cimv2' -ClassName Win32_NetworkAdapter -Filter "InterfaceIndex=$IfIndex" -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($cim) { return [string]$cim.PNPDeviceID }
    return $null
}

function Get-PrimaryDriverKind {
    $selection = Select-PrimaryPhysicalAdapter
    if ($selection) {
        $adapter = $selection.Adapter
        $kind = Get-DriverKindForAdapter -PnpDeviceId (Get-PnpIdForInterface -IfIndex $adapter.ifIndex) -AdapterName $adapter.Name
        if ($kind) {
            if ($selection.Source -eq 'DefaultRoute') {
                Write-MmcssLog ("Primary adapter: {0} Source={1} Prefix={2} RouteMetric={3} InterfaceMetric={4} TotalMetric={5} -> {6}" -f `
                    $adapter.Name, $selection.Source, $selection.Prefix, $selection.RouteMetric, $selection.InterfaceMetric, $selection.TotalMetric, $kind)
            } else {
                Write-MmcssLog ("Primary adapter: {0} Source={1} -> {2}" -f $adapter.Name, $selection.Source, $kind)
            }
            return $kind
        }

        Write-MmcssLog ("WARNING: Could not resolve driver kind for '{0}'; scanning other physical adapters" -f $adapter.Name)
    } else {
        Write-MmcssLog 'WARNING: No physical adapter selected from default routes'
    }

    foreach ($adapter in @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue |
        Sort-Object @{ Expression = { if ($_.Status -eq 'Up') { 0 } else { 1 } } },
                    @{ Expression = { $_.ifIndex } })) {
        $kind = Get-DriverKindForAdapter -PnpDeviceId (Get-PnpIdForInterface -IfIndex $adapter.ifIndex) -AdapterName $adapter.Name
        if ($kind) {
            Write-MmcssLog ("  Fallback adapter: {0} -> {1}" -f $adapter.Name, $kind)
            return $kind
        }
    }

    return $null
}

function Set-NetAdapterCxProfile {
    Write-MmcssLog 'NetAdapterCx detected - disabling MMCSS'
    Set-RegistryValue -Path $MmcssService -Name Start -Type DWord -Value 4
    Set-RegistryValue -Path $SystemProfile -Name SystemResponsiveness -Type DWord -Value 100
}

function Set-NdisProfile {
    Write-MmcssLog 'NDIS detected - applying custom MMCSS profile'
    Set-RegistryValue -Path $MmcssService -Name Start -Type DWord -Value 2
    Set-RegistryValue -Path $SystemProfile -Name SystemResponsiveness -Type DWord -Value 10
    Set-RegistryValue -Path $SystemProfile -Name NoLazyMode -Type DWord -Value 0
    Set-RegistryValue -Path $SystemProfile -Name IdleDetectionCycles -Type DWord -Value 1


    foreach ($task in 'Audio', 'Playback', 'Pro Audio') {
        $taskPath = Join-Path $SystemProfile "Tasks\$task"
        Set-RegistryValue -Path $taskPath -Name 'Priority' -Type DWord -Value 1
        Set-RegistryValue -Path $taskPath -Name 'Scheduling Category' -Type String -Value 'Medium'
        Set-RegistryValue -Path $taskPath -Name 'Priority When Yielded' -Type DWord -Value 1
    }
}

Write-MmcssLog 'Starting MMCSS NIC detection'

$driverKind = Get-PrimaryDriverKind
if (-not $driverKind) {
    Write-MmcssLog 'ERROR: Could not determine driver type - MMCSS config skipped'
    exit 1
}

if ($driverKind -eq 'NetAdapterCx') {
    Set-NetAdapterCxProfile
} else {
    Set-NdisProfile
}

Write-MmcssLog 'Done'
