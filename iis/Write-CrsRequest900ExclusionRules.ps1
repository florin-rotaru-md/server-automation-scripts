function Write-CrsRequest900ExclusionRules {
    param (
        [string]$FilePath
    )

    # Define the recommended exclusion rules for REQUEST-900
    $rules = @"
# Exclusion Rules for OWASP CRS (Pre-Processing)
SecRuleRemoveById 920420

# Disable rules that may interfere with APIs
SecRuleRemoveByTag "api-protection"

# Modify Rule Targets
SecRuleUpdateTargetById 920420 "!ARGS:token"

# Allow common API parameters without triggering false positives
SecRuleUpdateTargetById 920440 "!REQUEST_HEADERS:Authorization"
SecRuleUpdateTargetById 920450 "!REQUEST_HEADERS:User-Agent"

# Disable enforcement for trusted IPs
SecRuleRemoveById 920300
SecRuleRemoveById 920320
SecRuleRemoveById 920340

# Fine-tune security levels before CRS evaluation
SecRuleUpdateActionById 949110 "t:none,drop"
SecRuleUpdateActionById 959100 "t:none,drop"
"@

    # Write the content to the specified file path
    $rules | Out-File -Encoding utf8 -FilePath $FilePath

    Write-Output "Configuration file created at: $FilePath"
}