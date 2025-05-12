function Write-CrsResponse999ExclusionRules {
    param (
        [string]$FilePath
    )

    # Define the recommended exclusion rules
    $rules = @"
# Exclusion Rules for OWASP CRS
SecRuleRemoveById 942100

# Exclude all SQL injection detection rules
SecRuleRemoveByTag "attack-sqli"

# Modify Rule Targets
SecRuleUpdateTargetById 942100 "!ARGS:password"

# Cookie-Based False Positive Exclusions
# SecRuleUpdateTargetById 942420 "!REQUEST_COOKIES:session"
# SecRuleUpdateTargetById 942440 "!REQUEST_COOKIES:session"
# SecRuleUpdateTargetById 942450 "!REQUEST_COOKIES:session"

# Disable Host Header IP Check
SecRuleRemoveById 920350

# Drop Connection for DoS Attack Prevention
SecRuleUpdateActionById 949110 "t:none,drop"
SecRuleUpdateActionById 959100 "t:none,drop"
"@

    # Write the content to the specified file path
    $rules | Out-File -Encoding utf8 -FilePath $FilePath

    Write-Output "Configuration file created at: $FilePath"
}
