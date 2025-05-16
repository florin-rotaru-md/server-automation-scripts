function Test-CertificateExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$HostName,
        [string]$CCSConfigFile
    )

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
