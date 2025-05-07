# Ensure script is running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Please run this script as Administrator"
    exit 1
}

function Ensure-WindowsFeature {
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
Ensure-WindowsFeature -FeatureName "DNS"

# IIS and Features
$features = @(
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
    "Web-Scripting-Tools"
)
foreach ($feature in $features) {
    Ensure-WindowsFeature -FeatureName $feature
}

# Remove features
$featuresToRemove = @(
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
