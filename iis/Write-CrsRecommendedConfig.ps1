function Write-CrsRecommendedConfig {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $configContent = @"
# Recommended CRS Setup Configuration

SecDefaultAction "phase:1,log,auditlog,pass"
SecDefaultAction "phase:2,log,auditlog,pass"

# Set paranoia level (1-4)
# Level 1 = safe, Level 2+ = more strict, more false positives
setvar:'tx.paranoia_level=1'

# Anomaly scoring thresholds
setvar:'tx.anomaly_score_blocking=on'
setvar:'tx.inbound_anomaly_score_threshold=5'
setvar:'tx.outbound_anomaly_score_threshold=4'

# Uncomment to allow application/json or other content types
# setvar:'tx.allowed_request_content_type=application/json'

# Uncomment to test rules without blocking
# setvar:'tx.anomaly_score_blocking=off'

# Uncomment and customize to whitelist specific paths
# setvar:'tx.crs_exclusions_path=/admin'

# Uncomment to disable SQLi rules if needed
# setvar:'tx.crs_exclusions_sql_injection=1'
"@

    $configContent | Set-Content -Path $FilePath -Encoding UTF8

    Write-Host "$FilePath created with recommended values."
}
