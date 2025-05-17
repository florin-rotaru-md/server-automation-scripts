function Write-CrsResponse999ExclusionRules {
    <#
        .SYNOPSIS
        Generates a configuration file for OWASP Core Rule Set (CRS) exclusion rules.
        .DESCRIPTION
        This script creates a configuration file with recommended exclusion rules for the OWASP Core Rule Set (CRS).
        .PARAMETER FilePath
        The path where the configuration file will be created.
        .EXAMPLE
        Write-CrsResponse999ExclusionRules -FilePath "C:\path\to\your\file.conf"
        This command generates a configuration file at the specified path.
    #>
    [CmdletBinding()]
    param (
        [string]$FilePath
    )
   
    # Check if the file path is provided
    if (-not $FilePath) {
        throw "File path is required."
    }

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
