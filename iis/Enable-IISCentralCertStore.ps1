function Enable-IISCentralCertStore {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CCSConfigFile
    )

    Import-Module WebAdministration

    try {

        if (-not (Test-Path $CCSConfigFile)) {
            throw "CCSConfigFile { physicalPath, userName, password } $CCSConfigFile not found"
        }

        $ccsConfig = Get-Content -Path $CCSConfigFile | ConvertFrom-Json

        $physicalPath = $ccsConfig.physicalPath

        # Create directory if it doesn't exist
        if (-not (Test-Path $physicalPath)) {
            New-Item -Path $physicalPath -ItemType Directory -Force | Out-Null
            Write-Host "Created directory: $physicalPath"
        }

        # Grant IIS access
        icacls $physicalPath /grant IIS_IUSRS:F
   
        $securePassword = $($ccsConfig.password) | ConvertTo-SecureString -AsPlainText -Force
        # $securePrivateKeyPassword = $($ccsConfig.privateKeyPassword) | ConvertTo-SecureString -AsPlainText -Force
        $securePrivateKeyPassword = New-Object -TypeName System.Security.SecureString

        Enable-IISCentralCertProvider `
            -CertStoreLocation $physicalPath `
            -UserName $($ccsConfig.userName) `
            -Password $securePassword `
            -PrivateKeyPassword $securePrivateKeyPassword
    }
    catch {
        throw "Failed to enable CCS: $_"
    }
}
