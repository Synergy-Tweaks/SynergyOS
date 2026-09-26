param (
    [switch]$Chrome,
    [switch]$Brave,
    [switch]$Firefox,
    [switch]$SynToolkit
)

# ----------------------------------------------------------------------------------------------------------- #
# Direct downloads with hidden installers — fast, reliable, and fully silent during playbook execution.       #
# ----------------------------------------------------------------------------------------------------------- #

# --fail is required: without it curl exits 0 on an HTTP 404/500 and happily writes
# the error page to the output path, which then gets Start-Process'd as if it were
# the installer. --proto =https keeps a hijacked redirect from downgrading to http.
$timeouts = @("--fail", "--proto", "=https", "--proto-redir", "=https", "--connect-timeout", "10", "--retry", "5", "--retry-delay", "0", "--retry-all-errors")
$msiArgs = "/qn /quiet /norestart ALLUSERS=1 REBOOT=ReallySuppress"
$arm = ((Get-CimInstance -Class Win32_ComputerSystem).SystemType -match 'ARM64') -or ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64')

function Remove-TempDirectory {
    Pop-Location
    Remove-Item -Path $tempDir -Force -Recurse -EA 0
}

# Download to $Path and refuse to return unless we got a real file. $Sha256 is
# optional; when supplied the file is rejected on mismatch. `if (!$?)` was not a
# reliable check after curl.exe - $LASTEXITCODE is.
function Get-RemoteFile {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Sha256
    )

    & curl.exe -LSs $Url -o $Path $timeouts

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Downloading $Name failed (curl exit $LASTEXITCODE)."
        return $false
    }

    if (!(Test-Path $Path) -or (Get-Item $Path).Length -eq 0) {
        Write-Error "Downloading $Name produced no file."
        return $false
    }

    if ($Sha256) {
        $actual = (Get-FileHash -Path $Path -Algorithm SHA256).Hash
        if ($actual -ne $Sha256) {
            Write-Error "$Name failed checksum verification. Expected $Sha256, got $actual."
            Remove-Item -Path $Path -Force -EA 0
            return $false
        }
        # Write-Host, not Write-Output: anything written to the output pipeline inside
        # this function would be returned alongside the boolean and break the callers.
        Write-Host "$Name checksum verified."
    }

    return $true
}

function Get-LatestSynToolkitInstaller {
    param(
        [Parameter(Mandatory = $true)][string]$MetadataPath
    )

    $releaseApiUrl = 'https://api.github.com/repos/Synergy-Tweaks/SynToolkit/releases/latest'
    if (!(Get-RemoteFile -Url $releaseApiUrl -Path $MetadataPath -Name 'SynToolkit release metadata')) {
        return $null
    }

    try {
        $release = Get-Content -LiteralPath $MetadataPath -Raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Error "SynToolkit release metadata could not be read."
        return $null
    }

    if ($release.prerelease -or $release.draft) {
        Write-Error 'SynToolkit latest-release metadata did not identify a published Stable release.'
        return $null
    }

    $stableAssets = @($release.assets | Where-Object {
            $_.name -match '^SynToolkit-Setup-\d+(?:\.\d+){1,3}-Stable\.exe$'
        })

    if ($stableAssets.Count -eq 0) {
        $stableAssets = @($release.assets | Where-Object {
                $_.name -match '^SynToolkit-Setup(?:-\d+(?:\.\d+){1,3})?\.exe$'
            })
    }

    if ($stableAssets.Count -ne 1) {
        Write-Error "SynToolkit release '$($release.tag_name)' did not contain exactly one Stable installer asset."
        return $null
    }

    $asset = $stableAssets[0]
    try {
        $downloadUri = [Uri]$asset.browser_download_url
    }
    catch {
        Write-Error 'SynToolkit release metadata contained an invalid installer URL.'
        return $null
    }

    if (($downloadUri.Scheme -ne 'https') -or ($downloadUri.Host -ne 'github.com')) {
        Write-Error 'SynToolkit release metadata pointed to an unexpected installer host.'
        return $null
    }

    $digest = [string]$asset.digest
    if ($digest -notmatch '^sha256:([A-Fa-f0-9]{64})$') {
        Write-Error "SynToolkit release '$($release.tag_name)' did not provide a valid SHA-256 checksum."
        return $null
    }

    return [PSCustomObject]@{
        Version = [string]$release.tag_name
        Url     = $downloadUri.AbsoluteUri
        FileName = [string]$asset.name
        Sha256  = $Matches[1].ToUpperInvariant()
    }
}

$tempDir = Join-Path -Path $env:TEMP -ChildPath ([guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
Push-Location $tempDir

if ($SynToolkit) {
    $synToolkitInstaller = Get-LatestSynToolkitInstaller -MetadataPath "$tempDir\SynToolkit-release.json"
    if (!$synToolkitInstaller) {
        Remove-TempDirectory
        exit 1
    }

    $synToolkitInstallerPath = Join-Path $tempDir $synToolkitInstaller.FileName
    Write-Output "Downloading SynToolkit $($synToolkitInstaller.Version)..."
    if (!(Get-RemoteFile -Url $synToolkitInstaller.Url -Path $synToolkitInstallerPath -Name 'SynToolkit' -Sha256 $synToolkitInstaller.Sha256)) {
        Remove-TempDirectory
        exit 1
    }

    Write-Output "Installing SynToolkit..."
    $installerProcess = Start-Process -FilePath $synToolkitInstallerPath -WindowStyle Hidden -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -Wait -PassThru

    if ($installerProcess.ExitCode -ne 0) {
        Write-Error "SynToolkit setup failed with exit code $($installerProcess.ExitCode)."
        Remove-TempDirectory
        exit 1
    }

    Remove-TempDirectory
    exit
}

# Brave
if ($Brave) {
    Write-Output "Downloading Brave..."
    if (!(Get-RemoteFile -Url "https://laptop-updates.brave.com/latest/winx64" `
                         -Path "$tempDir\BraveSetup.exe" -Name "Brave")) {
        Remove-TempDirectory
        exit 1
    }

    Write-Output "Installing Brave..."
    Start-Process -FilePath "$tempDir\BraveSetup.exe" -WindowStyle Hidden -ArgumentList '/silent /install'

    do {
        $processesFound = Get-Process | Where-Object { "BraveSetup" -contains $_.Name } | Select-Object -ExpandProperty Name
        if ($processesFound) {
            Write-Output "Still running BraveSetup."
            Start-Sleep -Seconds 2
        }
        else {
            Remove-TempDirectory
        }
    } until (!$processesFound)

    Stop-Process -Name "brave" -Force -EA 0

    exit
}

# Firefox
if ($Firefox) {
    $firefoxArch = ('win64', 'win64-aarch64')[$arm]

    Write-Output "Downloading Firefox..."
    if (!(Get-RemoteFile -Url "https://download.mozilla.org/?product=firefox-latest-ssl&os=$firefoxArch&lang=en-US" `
                         -Path "$tempDir\firefox.exe" -Name "Firefox")) {
        Remove-TempDirectory
        exit 1
    }

    Write-Output "Installing Firefox..."
    Start-Process -FilePath "$tempDir\firefox.exe" -WindowStyle Hidden -ArgumentList '/S /ALLUSERS=1' -Wait

    Remove-TempDirectory
    exit
}

# Chrome
if ($Chrome) {
    Write-Output "Downloading Google Chrome..."
    $chromeArch = ('64', '_Arm64')[$arm]
    if (!(Get-RemoteFile -Url "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise$chromeArch.msi" `
                         -Path "$tempDir\chrome.msi" -Name "Google Chrome")) {
        Remove-TempDirectory
        exit 1
    }

    Write-Output "Installing Google Chrome..."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$tempDir\chrome.msi`" /qn /norestart" -WindowStyle Hidden -Wait

    Remove-TempDirectory
    exit
}

#####################
##    Utilities    ##
#####################

# Visual C++ Runtimes (referred to as vcredists for short)
# https://learn.microsoft.com/en-US/cpp/windows/latest-supported-vc-redist
$legacyArgs = '/q /norestart'
$modernArgs = "/install /quiet /norestart"

$vcredists = [ordered]@{
    # 2005 - version 8.0.50727.6195 (MSI 8.0.61000/8.0.61001) SP1
    "https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.exe"       = @("2005-x64", "/c /q /t:")
    "https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.exe"       = @("2005-x86", "/c /q /t:")
    # 2008 - version 9.0.30729.6161 (EXE 9.0.30729.5677) SP1
    "https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe"       = @("2008-x64", "/q /extract:")
    "https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe"       = @("2008-x86", "/q /extract:")
    # 2010 - version 10.0.40219.325 SP1
    "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe"       = @("2010-x64", $legacyArgs)
    "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe"       = @("2010-x86", $legacyArgs)
    # 2012 - version 11.0.61030.0
    "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe" = @("2012-x64", $modernArgs)
    "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe" = @("2012-x86", $modernArgs)
    # 2013 - version 12.0.40664.0
    "https://aka.ms/highdpimfc2013x64enu"                                                                       = @("2013-x64", $modernArgs)
    "https://aka.ms/highdpimfc2013x86enu"                                                                       = @("2013-x86", $modernArgs)
    # 2015-2022 (2015+) - latest version
    "https://aka.ms/vs/17/release/vc_redist.x64.exe"                                                            = @("2015+-x64", $modernArgs)
    "https://aka.ms/vs/17/release/vc_redist.x86.exe"                                                            = @("2015+-x86", $modernArgs)
}

foreach ($a in $vcredists.GetEnumerator()) {
    $vcName = $a.Value[0]
    $vcArgs = $a.Value[1]
    $vcUrl = $a.Name
    $vcExePath = "$tempDir\vcredist-$vcName.exe"

    Write-Output "Downloading and installing Visual C++ Runtime $vcName..."
    if (!(Get-RemoteFile -Url $vcUrl -Path $vcExePath -Name "Visual C++ Runtime $vcName")) {
        Write-Output "Skipping Visual C++ Runtime $vcName."
        continue
    }

    if ($vcArgs -match ":") {
        $msiDir = "$tempDir\vcredist-$vcName"
        Start-Process -FilePath $vcExePath -ArgumentList "$vcArgs`"$msiDir`"" -Wait -WindowStyle Hidden

        $msiPaths = (Get-ChildItem -Path $msiDir -Filter *.msi -EA 0).FullName
        if (!$msiPaths) {
            Write-Output "Failed to extract MSI for $vcName, not installing."
        }
        else {
            $msiPaths | ForEach-Object {
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/log `"$msiDir\logfile.log`" /i `"$_`" $msiArgs" -WindowStyle Hidden -Wait
            }
        }
    }
    else {
        Start-Process -FilePath $vcExePath -ArgumentList $vcArgs -Wait -WindowStyle Hidden
    }
}

# 7-Zip
# The download URL is scraped from the 7-zip.org homepage, so the scrape result has
# to be validated before it is used - previously a layout change upstream produced an
# empty/multi-value match that was concatenated into a junk URL and executed anyway.
$website = 'https://7-zip.org/'
$7zipArch = ('x64', 'arm64')[$arm]
$7zipLink = @((Invoke-WebRequest $website -UseBasicParsing).Links.href | Where-Object { $_ -like "a/7z*-$7zipArch.exe" })

if ($7zipLink.Count -ne 1) {
    Write-Error "Could not determine the 7-Zip download URL ($($7zipLink.Count) candidates). Skipping 7-Zip."
}
else {
    $download = $website + $7zipLink[0]
    Write-Output "Downloading 7-Zip..."
    if (Get-RemoteFile -Url $download -Path "$tempDir\7zip.exe" -Name "7-Zip") {
        Write-Output "Installing 7-Zip..."
        Start-Process -FilePath "$tempDir\7zip.exe" -WindowStyle Hidden -ArgumentList '/S' -Wait
    }
}

# Legacy DirectX runtimes
Write-Output "Downloading legacy DirectX runtimes..."
if (Get-RemoteFile -Url "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe" `
                   -Path "$tempDir\directx.exe" -Name "legacy DirectX runtimes") {
    Write-Output "Extracting legacy DirectX runtimes..."
    Start-Process -FilePath "$tempDir\directx.exe" -WindowStyle Hidden -ArgumentList "/q /c /t:`"$tempDir\directx`"" -Wait

    if (Test-Path "$tempDir\directx\dxsetup.exe") {
        Write-Output "Installing legacy DirectX runtimes..."
        Start-Process -FilePath "$tempDir\directx\dxsetup.exe" -WindowStyle Hidden -ArgumentList '/silent' -Wait
    }
    else {
        Write-Error "DirectX redist did not extract as expected, skipping install."
    }
}

Remove-TempDirectory
