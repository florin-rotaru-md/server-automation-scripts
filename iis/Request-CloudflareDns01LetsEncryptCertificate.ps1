function Request-CloudflareDns01LetsEncryptCertificate {
    param(
        [string]$HostName,
        [string]$WacsArgsCloudflarecredentials,
        [string]$WacsArgsEmailAddress
    )

    $wacsPath = "C:\Program Files\Win-Acme\wacs.exe"
   
    if (-not (Test-Path $wacsPath)) {
        throw "wacs.exe not found at '$wacsPath'"
    }

    if (-not $WacsArgsEmailAddress) {
        while (-not $WacsArgsEmailAddress) {
            Write-Warning "Email address cannot be empty. Please enter a valid email address."
            $WacsArgsEmailAddress = Read-Host "Enter your email address for Let's Encrypt notifications"
        }
    }

    if (-not (Test-Path $WacsArgsCloudflarecredentials)) {
        Write-Error "Cloudflare token file not found at '$WacsArgsCloudflarecredentials'"
        return
    }

    $arguments = @(
        "--installation none"
        "--target manual"
        "--host $HostName"
        "--validation dns-01"
        "--validationmode dns-01"
        "--store certificatestore"
        "--certificatestore My"
        "--plugin validation.dns.cloudflare"
        "--pluginargs tokenFile=$WacsArgsCloudflarecredentials"
        "--accepttos"
        "--WacsArgsEmailAddress $WacsArgsEmailAddress"
        # "--test"
        # "--verbose"
    ) -join " "

    Start-Process -FilePath $wacsPath -ArgumentList $arguments -Wait -NoNewWindow

    Start-Sleep -Seconds 5

    $cert = Get-ExistingLetsEncryptCertificate -HostName $HostName -MinimumDaysValid 0
    if ($cert) {
        Write-Host "Certificate obtained: $($cert.Thumbprint)"
        return $cert.Thumbprint
    }

    throw "Failed to get certificate for $HostName"
}
