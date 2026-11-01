$CabPath = "C:\Windows\NoDefender.cab"
$certRegPath = "HKLM:\Software\Microsoft\SystemCertificates\ROOT\Certificates"

function ProcessCab($cabPath) {
	$filePath = Split-Path $cabPath -Leaf
	Write-Host "`nInstalling $filePath..." -ForegroundColor Cyan
	Write-Host ("-" * 84) -ForegroundColor Magenta
	Write-Host "[INFO] Checking certificate..."
	try {
		$cert = (Get-AuthenticodeSignature $cabPath).SignerCertificate
		if ($cert.Extensions.EnhancedKeyUsages.Value -ne "1.3.6.1.4.1.311.10.3.6") {
			Write-Host "[ERROR] Cert doesn't have proper key usages, can't continue." -ForegroundColor Red
			$script:errorLevel++
			return $false
		}

		# add test cert
		# isn't cleared later as it's required for the alt repair source
		$certRegPath = "HKLM:\Software\Microsoft\SystemCertificates\ROOT\Certificates\8A334AA8052DD244A647306A76B8178FA215F344"
		if (!(Test-Path "$certRegPath")) {
			New-Item -Path $certRegPath -Force | Out-Null
		}
	} catch {
		Write-Host "[ERROR] Cert error from '$cabPath': $_" -ForegroundColor Red
		$script:errorLevel++
		return $false
	}

	Write-Host "[INFO] Adding package..."
	try {
		Add-WindowsPackage -Online -PackagePath $cabPath -NoRestart -IgnoreCheck -LogLevel 1 *>$null
	} catch {
		Write-Host "[ERROR] Error when adding package '$cabPath': $_" -ForegroundColor Red
		$script:errorLevel++
		return $false
	}

	Write-Host "[INFO] Completed sucessfully."
	return $true
}

ProcessCab $CabPath
Write-Host "Completed!" -ForegroundColor Green
