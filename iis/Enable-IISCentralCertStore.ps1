function Enable-IISCentralCertStore {
    <#
        .SYNOPSIS
        Enable the IIS Central Certificate Store (CCS) for SSL certificate management.
        .DESCRIPTION
        This function enables the IIS Central Certificate Store (CCS) by creating a directory for the CCS,
        granting IIS_IUSRS access to it, and configuring the CCS with the provided credentials.
        .PARAMETER CCSConfigFile
        The path to the JSON configuration file containing CCS settings.
        .EXAMPLE
        Enable-IISCentralCertStore -CCSConfigFile "C:\path\to\ccs_config.json"
    #>
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
        icacls $physicalPath /grant "IIS_IUSRS:(OI)(CI)F"
   
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
