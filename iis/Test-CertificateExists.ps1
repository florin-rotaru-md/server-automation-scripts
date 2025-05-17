function Test-CertificateExists {
    <#
        .SYNOPSIS
        Checks if a certificate exists in the Centralized Certificate Store (CCS) or in the WACS renewal configuration.
        .DESCRIPTION
        This function checks if a certificate for the specified hostname exists in the Centralized Certificate Store (CCS) or in the WACS renewal configuration.
        .PARAMETER HostName
        The hostname of the certificate to check.
        .PARAMETER CCSConfigFile
        The path to the CCS configuration file.
        .EXAMPLE
        Test-CertificateExists -HostName "example.com" -CCSConfigFile "C:\path\to\ccsconfig.json"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$HostName,
        [string]$CCSConfigFile
    )
    
    # Check if the HostName parameter is provided
    if (-not $HostName) {
        throw "HostName parameter is required."
    }

    $wacsRenewalsPath = "C:\ProgramData\win-acme\acme-v02.api.letsencrypt.org\Renewals"
    Write-Host "CCSConfigFile: $CCSConfigFile"

    $ccsConfig = Get-Content -Path $CCSConfigFile | ConvertFrom-Json

    # Check if a renewal config exists in WACS
    $renewalExists = Get-ChildItem "$wacsRenewalsPath\*.renewal.json" -ErrorAction SilentlyContinue | Where-Object {
        (Get-Content $_.FullName -Raw) -match "\b$HostName\b"
    }

    # Check if a .pfx file exists in the Centralized Certificate Store
    $pfxPath = Join-Path $($ccsConfig.physicalPath) "$HostName.pfx"

    Write-Host "PFX Path: $pfxPath"
    $pfxFileExists = Test-Path $pfxPath

    return ($renewalExists -or $pfxFileExists)
}
