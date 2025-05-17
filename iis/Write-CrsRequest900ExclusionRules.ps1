function Write-CrsRequest900ExclusionRules {
    <#
        .SYNOPSIS
        Generates a configuration file for OWASP Core Rule Set (CRS) exclusion rules for Request 900.
        .DESCRIPTION
        This script creates a configuration file with recommended exclusion rules for the OWASP Core Rule Set (CRS) Request 900.
        .PARAMETER FilePath
        The path where the configuration file will be created.
        .EXAMPLE
        Write-CrsRequest900ExclusionRules -FilePath "C:\path\to\your\file.conf"
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