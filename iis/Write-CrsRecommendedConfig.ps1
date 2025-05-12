function Write-CrsRecommendedConfig {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

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
