# Ensure script is running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Please run this script as Administrator"
    exit 1
}

$ProgressPreference = 'SilentlyContinue'

function Install-WindowsFeatureIfNeeded {
    param (
        [string]$FeatureName
    )
    if (-not (Get-WindowsFeature -Name $FeatureName).Installed) {
        Write-Host "Installing feature: $FeatureName" -ForegroundColor Cyan
        Install-WindowsFeature -Name $FeatureName -IncludeManagementTools
    }
    else {
        Write-Host "Feature already installed: $FeatureName" -ForegroundColor Green
    }
}

# DNS Role
Install-WindowsFeatureIfNeeded -FeatureName "DNS"

# IIS and Features
$features = @(
	"Containers",
    "Web-Server",
    "Web-Default-Doc", 
    "Web-Http-Errors", 
    "Web-Static-Content", 
    "Web-Http-Redirect",
    "Web-Stat-Compression",
    "Web-Filtering", 
    "Web-Cert-Auth", 
    "Web-IP-Security",
    "Web-Mgmt-Console", 
    "Web-Mgmt-Service", 
    "Web-Scripting-Tools",
    "Web-App-Dev",
    "Web-ISAPI-Ext",
    "Web-ISAPI-Filter",
    "Web-Dyn-Compression",
    "Web-CertProvider"
	
)
foreach ($feature in $features) {
    Install-WindowsFeatureIfNeeded -FeatureName $feature
}

# Remove features
$featuresToRemove = @(
    "Web-DAV-Publishing",    
    "Web-Dir-Browsing",
    "Web-Http-Logging"
)
foreach ($feature in $featuresToRemove) {
    if ((Get-WindowsFeature -Name $feature).Installed) {
        Write-Host "Removing feature: $feature" -ForegroundColor Cyan
        Uninstall-WindowsFeature -Name $feature
    }
}

# Enable Management Service (WMSVC)
Set-Service -Name WMSVC -StartupType Automatic
Start-Service WMSVC

Set-DnsServerRecursion -Enable $False
Clear-DnsServerCache -Force
