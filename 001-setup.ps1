
# WebAppServerSetup.ps1
# PowerShell script to set up DNS, IIS, .NET 8, VS Code, Notepad++, PostgreSQL 17, and pgAdmin 4 on Windows Server 2022

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
    } else {
        Write-Host "Feature already installed: $FeatureName" -ForegroundColor Green
    }
}

function Install-IfNotInstalled {
    param (
        [string]$PackageId
    )
    if (winget list --id $PackageId -e | Select-String $PackageId) {
        Write-Host "$PackageId is already installed." -ForegroundColor Green
    } else {
        Write-Host "Installing $PackageId..." -ForegroundColor Cyan
        winget install --id $PackageId -e --accept-package-agreements --accept-source-agreements
    }
}

# DNS Role
Ensure-WindowsFeature -FeatureName "DNS"

# IIS and Features
$features = @(
    "Web-Server",
    "Web-Default-Doc", "Web-Http-Errors", "Web-Static-Content", "Web-Http-Redirect",
    "Web-Stat-Compression",
    "Web-Filtering", "Web-Cert-Auth", "Web-IP-Security",
    "Web-Mgmt-Console", "Web-Mgmt-Service", "Web-Scripting-Tools"
)
foreach ($feature in $features) {
    Ensure-WindowsFeature -FeatureName $feature
}

# Enable Management Service (WMSVC)
Set-Service -Name WMSVC -StartupType Automatic
Start-Service WMSVC

# .NET 8 Hosting Bundle
$dotnetPath = "C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App\8.0.0"
if (-not (Test-Path $dotnetPath)) {
    $dotnetInstaller = "$env:TEMP\dotnet-hosting.exe"
    $dotnetDownloadUrl = "https://download.visualstudio.microsoft.com/download/pr/c7e5f8ff-d93f-4f47-9111-4f2d99b8e469/0c2a4d05fdf16c01054a21366c70a257/dotnet-hosting-8.0.4-win.exe"
    Write-Host "Downloading .NET 8 Hosting Bundle..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $dotnetDownloadUrl -OutFile $dotnetInstaller
    Write-Host "Installing .NET 8 Hosting Bundle..." -ForegroundColor Cyan
    Start-Process -FilePath $dotnetInstaller -ArgumentList "/quiet" -Wait
} else {
    Write-Host ".NET 8 Hosting Bundle is already installed." -ForegroundColor Green
}

# Install tools via winget
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Install-IfNotInstalled -PackageId "Microsoft.VisualStudioCode"
    Install-IfNotInstalled -PackageId "Notepad++.Notepad++"
    Install-IfNotInstalled -PackageId "PostgreSQL.PostgreSQL.17"
    Install-IfNotInstalled -PackageId "PostgreSQL.pgAdmin"
} else {
    Write-Warning "winget not found. Please install required programs manually."
}

Write-Host "✅ Setup complete. You may need to reboot the server." -ForegroundColor Green
