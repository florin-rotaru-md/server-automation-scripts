function Request-CloudflareDns01LetsEncryptCertificate {
    <#
        .SYNOPSIS
            Requests a Let's Encrypt certificate using wacs.exe with Cloudflare DNS validation.
        .DESCRIPTION
            This function requests a Let's Encrypt certificate for the specified host name using wacs.exe with Cloudflare DNS validation.
        .PARAMETER HostName
            The host name for which to request the certificate.
        .PARAMETER CCSConfigFile
            The path to the Central SSL Store configuration file.
        .PARAMETER WacsArgsCloudflareTokenPath
            The path to the Cloudflare API token file.
        .PARAMETER WacsArgsEmailAddress
            The email address for Let's Encrypt notifications (optional).
        .EXAMPLE
            Request-CloudflareDns01LetsEncryptCertificate -HostName "example.com" -CCSConfigFile "C:\path\to\ccsconfig.json" -WacsArgsCloudflareTokenPath "C:\path\to\token.txt" -WacsArgsEmailAddress "
    #>
    [CmdletBinding()]
    param(
        [string]$HostName,
        [string]$CCSConfigFile,
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

    # $arguments = @(
    #     "--installation none"
    #     "--source iis"
    #     "--host $HostName"
    #     "--validation cloudflare"
    #     "--cloudflareapitoken $cloudflareApiToken"
    #     "--store certificatestore"
    #     "--certificatestore My"
    #     "--accepttos"
    #     "--emailaddress $WacsArgsEmailAddress"
    #     # "--nocache"
    #     # "--test"
    #     # "--verbose"
    # ) -join " "

    $ccsConfig = Get-Content -Path $CCSConfigFile | ConvertFrom-Json
 
    $arguments = @(
        "--installation none"
        "--source manual"
        "--host $HostName"
        "--validation cloudflare"
        "--cloudflareapitoken $cloudflareApiToken" 
        "--store centralssl"
        "--centralsslstore $($ccsConfig.physicalPath)"
        "--pfxpassword """"" 
        "--accepttos"
        "--emailaddress $WacsArgsEmailAddress"
        # "--nocache"
        # "--test"
        # "--verbose"
    ) -join " "

    Start-Process -FilePath $wacsPath -ArgumentList $arguments -Wait -NoNewWindow
}
