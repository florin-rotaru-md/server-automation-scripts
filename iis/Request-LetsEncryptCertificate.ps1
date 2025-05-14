function Request-LetsEncryptCertificate {
    param (
        [Parameter(Mandatory = $true)]
        [string]$HostName,
        [string]$WebRoot,
        [string]$EmailAddress = ""
    )

    $config = Get-Content ".\Config.json" | ConvertFrom-Json
    $wacsPath = $($config.wacs.path)

    if (-not (Test-Path $wacsPath)) {
        Write-Error "wacs.exe not found at '$wacsPath'"
        return $null
    }

    Write-Host "Requesting Let's Encrypt certificate for $HostName..."
    Write-Host "WebRoot: $WebRoot"

    if (-not $EmailAddress) {
        $config = Get-Content ".\Config.json" | ConvertFrom-Json
        $EmailAddress = $($config.wacs.emailAddress)

        while (-not $EmailAddress) {
            Write-Warning "Email address cannot be empty. Please enter a valid email address."
            $EmailAddress = Read-Host "Enter your email address for Let's Encrypt notifications"
        }
    }

    $arguments = @(
        "--target manual"
        "--host $HostName"
        "--validation filesystem"
        "--webroot $WebRoot"
        "--store certificatestore"
        "--certificatestore My"
        "--installation none"
        "--accepttos"
        "--emailaddress $EmailAddress"
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
