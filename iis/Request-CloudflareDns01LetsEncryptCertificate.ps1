function Request-CloudflareDns01LetsEncryptCertificate {
    param(
        [string]$HostName,
        [string]$WacsArgsCloudflareTokenPath,
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

    if (-not (Test-Path $WacsArgsCloudflareTokenPath)) {
        Write-Error "Cloudflare token file not found at '$WacsArgsCloudflareTokenPath'"
        return
    }

    $cloudflareApiToken = Get-Content -Path $WacsArgsCloudflareTokenPath -Raw

    $settingsDefaultJsonPath = "C:\Program Files\Win-Acme\settings_default.json"
    $settingsDefaultContent = Get-Content -Path $settingsDefaultJsonPath -Raw | ConvertFrom-Json
    $settingsDefaultContent.Validation.DnsServers = @("1.1.1.1", "1.0.0.1")
    $newSettingsDefaultJsonContent = $settingsDefaultContent | ConvertTo-Json -Depth 10

    Set-Content -Path $settingsDefaultJsonPath -Value $newSettingsDefaultJsonContent -Encoding UTF8

    $arguments = @(
        "--installation none"
        "--source manual"
        "--host $HostName"
        "--validation cloudflare"
        "--cloudflareapitoken $cloudflareApiToken"
        #"--validationmode dns-01"
        "--store certificatestore"
        "--certificatestore My"
        "--accepttos"
        "--emailaddress $WacsArgsEmailAddress"
        # "--nocache"
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
