
# 001-setup.ps1

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

$tempInstallerPath = "C:\temp"
New-Item -Path $tempInstallerPath -ItemType Directory -Force | Out-Null

function Install-Application {
    param (
        [string]$AppName, # Name of the application (e.g., Notepad++, VSCode)
        [string]$AppExecutablePath, # Path to check if the app is already installed
        [string]$InstallerUrl, # URL to download the installer
        [string]$InstallerPath, # Temporary path for the installer
        [string]$InstallArgs = "/S" # Arguments for silent installation
    )

    # Check if the application is already installed
    If (-Not (Test-Path $AppExecutablePath)) {
        Write-Host "Installing $AppName..."
        
        # Download the installer
        Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath
        
        # Install the application silently
        Start-Process -FilePath $InstallerPath -ArgumentList $InstallArgs -Wait
        
        # Clean up installer file
        Remove-Item -Path $InstallerPath
        
        Write-Host "$AppName has been installed."
    }
    Else {
        Write-Host "$AppName is already installed."
    }
}

# Install .NET 8 Hosting Bundle
Install-Application -AppName ".NET 8 Hosting Bundle" `
    -AppExecutablePath  "C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App\8.0.15" `
    -InstallerUrl "https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/8.0.15/dotnet-hosting-8.0.15-win.exe" `
    -InstallerPath "$tempInstallerPath\dotnet-hosting-8.0.15-win.exe"

# Install Notepad++ if not already installed
Install-Application -AppName "Notepad++" `
    -AppExecutablePath  "C:\Program Files\Notepad++" `
    -InstallerUrl "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.7.9/npp.8.7.9.Installer.x64.exe" `
    -InstallerPath "$tempInstallerPath\npp_installer.exe"

# Install Visual Studio Code if not already installed
Install-Application -AppName "Visual Studio Code" `
    -AppExecutablePath "C:\Program Files\Microsoft VS Code" `
    -InstallerUrl "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" `
    -InstallerPath "$tempInstallerPath\vscode_installer.exe" `
    -InstallArgs "/verysilent /mergetasks=!runcode"
    
$pgInstallArgs = @(
    "--mode", "unattended",
    "--superpassword", "postgres",
    "--prefix", "`"C:\Program Files\PostgreSQL\17`"",
    "--datadir", "`"C:\Program Files\PostgreSQL\17\data`"",
    "--unattendedmodeui", "none",
    "--install_runtimes", "1" # Skip installing VC++ runtimes (optional)
) -join " "

# Install PostgreSQL 17 Server if not already installed
Install-Application -AppName "PostgreSQL 17 Server" `
    -AppExecutablePath "C:\Program Files\PostgreSQL\17" `
    -InstallerUrl "https://get.enterprisedb.com/postgresql/postgresql-17.1-1-windows-x64.exe" `
    -InstallerPath "$tempInstallerPath\postgresql.exe" `
    -InstallArgs $pgInstallArgs 

# # Open port 5432 in Windows Firewall
$ruleName = "PostgreSQL 5432"

# Check if the firewall rule already exists
$existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

if (-Not $existingRule) {
    # If the rule doesn't exist, create it
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol TCP -LocalPort 5432 -Action Allow
    Write-Host "Firewall rule '$ruleName' has been created."
}
else {
    Write-Host "Firewall rule '$ruleName' already exists."
}

# Modify PostgreSQL configuration for remote access
$pgDataPath = "C:\\Program Files\\PostgreSQL\\17\\data"
$pgConfPath = Join-Path $pgDataPath "postgresql.conf"
$pgHbaPath = Join-Path $pgDataPath "pg_hba.conf"

if (Test-Path $pgConfPath) {
    Write-Host "Enabling listen_addresses = '*'" -ForegroundColor Cyan
    (Get-Content $pgConfPath) -replace "#listen_addresses = 'localhost'", "listen_addresses = '*'" |
    Set-Content $pgConfPath

    $fileContent = Get-Content -Path $pgHbaPath
    $allowAllIpV4Clients = "host    all             all             0.0.0.0/0               scram-sha-256"
    
    # Write-Host "Allowing all IPv4 clients with scram-sha-256 auth in pg_hba.conf" -ForegroundColor Cyan
    if (-Not ($fileContent -contains $allowAllIpV4Clients)) {
        Add-Content -Path $pgHbaPath -Value $allowAllIpV4Clients
    }
}

# Restart PostgreSQL service
Restart-Service -Name "postgresql-x64-17"

Write-Host "PostgreSQL setup complete. Remote connections enabled, password is 'postgres'." -ForegroundColor Green

Remove-Item -Path $tempInstallerPath -Recurse -Force