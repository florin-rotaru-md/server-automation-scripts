function Write-CrsRecommendedConfig {
    <#
        .SYNOPSIS
        Generates a configuration file for OWASP Core Rule Set (CRS) with recommended values.
        .DESCRIPTION
        This script creates a configuration file with recommended values for the OWASP Core Rule Set (CRS).
        .PARAMETER FilePath
        The path where the configuration file will be created.
        .EXAMPLE
        Write-CrsRecommendedConfig -FilePath "C:\path\to\your\file.conf"
        This command generates a configuration file at the specified path.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    # Check if the file path is provided
    if (-not $FilePath) {
        throw "File path is required."
    }

    $configContent = @"
# Recommended CRS Setup Configuration

SecAction \
    "id:900990,\
    phase:1,\
    pass,\
    t:none,\
    nolog,\
    tag:'OWASP_CRS',\
    ver:'OWASP_CRS/4.14.0',\
    setvar:tx.crs_setup_version=4140"
"@

    $configContent | Set-Content -Path $FilePath -Encoding UTF8

    Write-Host "$FilePath created with recommended values."
}
