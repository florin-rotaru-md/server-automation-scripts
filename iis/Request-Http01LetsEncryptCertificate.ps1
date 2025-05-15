function Request-Http01LetsEncryptCertificate {
    param (
        [string]$HostName,
        [string]$WebRoot,
        [string]$WacsArgsEmailAddress = ""
    )
    <#
        .SYNOPSIS
            Requests a Let's Encrypt certificate using wacs.exe.
        .DESCRIPTION
            This function requests a Let's Encrypt certificate for the specified host name using wacs.exe.
        .PARAMETER HostName
            The host name for which to request the certificate.
        .PARAMETER WebRoot
            The web root directory for the validation process.
        .PARAMETER WacsArgsEmailAddress
            The email address for Let's Encrypt notifications (optional).
        .EXAMPLE
            Request-LetsEncryptCertificate -HostName "example.com" -WebRoot "C:\inetpub\wwwroot"
        .NOTES  
            This script requires wacs.exe to be installed and available at the specified path.
            The script will prompt for an email address if not provided.
            The script will throw an error if the certificate request fails.
    #>

    $wacsPath = "C:\Program Files\Win-Acme\wacs.exe"
   
    if (-not (Test-Path $wacsPath)) {
        throw "wacs.exe not found at '$wacsPath'"
    }

    Write-Host "Requesting Let's Encrypt certificate for $HostName..."
    Write-Host "WebRoot: $WebRoot"

    if (-not $WacsArgsEmailAddress) {
        while (-not $WacsArgsEmailAddress) {
            Write-Warning "Email address cannot be empty. Please enter a valid email address."
            $WacsArgsEmailAddress = Read-Host "Enter your email address for Let's Encrypt notifications"
        }
    }

    $arguments = @(
        "--installation none"
        "--target manual"
        "--host $HostName"
        "--validation filesystem"
        "--webroot $WebRoot"
        "--store certificatestore"
        "--certificatestore My"
        "--accepttos"
        "--emailaddress $WacsArgsEmailAddress"
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
