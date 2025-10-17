# Ensure script is running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Please run this script as Administrator"
    exit 1
}

. "$PSScriptRoot\Install-Application.ps1"

$ProgressPreference = 'SilentlyContinue'

$tempInstallerPath = "C:\temp"
New-Item -Path $tempInstallerPath -ItemType Directory -Force | Out-Null

if ($PSVersionTable.PSVersion.ToString() -notmatch "^7\.5\..*") {
	Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.5.1/PowerShell-7.5.1-win-x64.msi" -OutFile "$tempInstallerPath\PowerShell-7.5.1-win-x64.msi"
	Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $tempInstallerPath\PowerShell-7.5.1-win-x64.msi /qn" -Wait
}

# Install Git SCM if not already installed
Install-Application -AppName "Git" `
    -AppExecutablePath "C:\Program Files\Git\bin" `
    -InstallerUrl "https://github.com/git-for-windows/git/releases/download/v2.49.0.windows.1/Git-2.49.0-64-bit.exe" `
    -InstallerPath "$tempInstallerPath\Git-2.49.0-64-bit.exe" `
    -InstallArgs '/VERYSILENT /NORESTART /COMPONENTS="icons,ext,ext\reg,assoc,assoc_sh" /LOG="C:\temp\git_install.log"'

# Post-install Git config adjustments
$gitExe = "C:\Program Files\Git\bin\git.exe"

if (Test-Path $gitExe) {
    Write-Host "Configuring Git user settings..." -ForegroundColor Cyan

    & $gitExe config --global core.autocrlf true                             # Windows-style checkout, UNIX-style commit
    & $gitExe config --global core.editor "code --wait"                      # Use Visual Studio Code as default editor
    & $gitExe config --global credential.helper manager                      # Use Git Credential Manager
    & $gitExe config --global merge.ff false                                 # Fast-forward or merge
    & $gitExe config --global gui.encoding utf-8
    & $gitExe config --global core.fileMode false                            # Optional: disable file mode checking
    & $gitExe config --global core.preloadIndex true                         # File system caching
    & $gitExe config --global core.fscache true                              # Extra file system cache boost
    & $gitExe config --global init.defaultBranch main                        # Optional: default branch name

    Write-Host "Git configuration completed." -ForegroundColor Green
} else {
    Write-Warning "Git executable not found. Skipping Git configuration."
}

# Install Visual C++ Redistributable x64
Install-Application `
    -AppName "Visual C++ Redistributable x64" `
    -AppExecutablePath "C:\Windows\System32\vcruntime140.dll" `
    -InstallerUrl "https://aka.ms/vs/17/release/vc_redist.x64.exe" `
    -InstallerPath "$tempInstallerPath\vc_redist.x64.exe" `
	-InstallArgs "/install /quiet /norestart"

# https://slproweb.com/products/Win32OpenSSL.html
# Install OpenSSL
Install-Application -AppName "OpenSSL" `
    -AppExecutablePath "C:\Program Files\OpenSSL-Win64\bin" `
    -InstallerUrl "https://slproweb.com/download/Win64OpenSSL-3_5_0.msi" `
    -InstallerPath "$tempInstallerPath/Win64OpenSSL-3_5_0.msi" `
    -InstallArgs "/quiet /norestart"

# Install .NET 10 Hosting Bundle
Install-Application -AppName ".NET 10 Hosting Bundle" `
    -AppExecutablePath  "C:\Program Files\IIS\Asp.Net Core Module\V2\110.0.25148" `
    -InstallerUrl "https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/10.0.0-preview.5.25277.114/dotnet-hosting-10.0.0-preview.5.25277.114-win.exe" `
    -InstallerPath "$tempInstallerPath\dotnet-hosting-10.0.0-win.exe"

# Install .NET 10 SDK
Install-Application -AppName ".NET 10 SDK" `
    -AppExecutablePath  "C:\Program Files\dotnet\sdk\10.0.100-preview.5.25277.114" `
    -InstallerUrl "https://builds.dotnet.microsoft.com/dotnet/Sdk/10.0.100-preview.5.25277.114/dotnet-sdk-10.0.100-preview.5.25277.114-win-x64.exe" `
    -InstallerPath "$tempInstallerPath\dotnet-sdk-10.0.0-win-x64.exe"

# Install ASP.NET Core Runtime 10
Install-Application -AppName "ASP.NET Core Runtime 10" `
    -AppExecutablePath "C:\Program Files\dotnet\shared\Microsoft.AspNetCore.App\10.0.0-preview.5.25277.114" `
    -InstallerUrl "https://builds.dotnet.microsoft.com/dotnet/Runtime/10.0.0-preview.5.25277.114/dotnet-runtime-10.0.0-preview.5.25277.114-win-x64.exe" `
    -InstallerPath "$tempInstallerPath\aspnetcore-runtime-10.0.0-win-x64.exe" `
    -InstallArgs "/quiet /norestart"

# Install Notepad++ if not already installed
Install-Application -AppName "Notepad++" `
    -AppExecutablePath  "C:\Program Files\Notepad++" `
    -InstallerUrl "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.7.9/npp.8.7.9.Installer.x64.exe" `
    -InstallerPath "$tempInstallerPath\npp.8.7.9.Installer.x64.exe"

# Install Visual Studio Code if not already installed
Install-Application -AppName "Visual Studio Code" `
    -AppExecutablePath "C:\Program Files\Microsoft VS Code" `
    -InstallerUrl "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64" `
    -InstallerPath "$tempInstallerPath\vscode_installer.exe" `
    -InstallArgs "/verysilent /mergetasks=!runcode"

# https://www.iis.net/downloads/microsoft/application-request-routing
# Install Request Router (IIS extension)
Install-Application -AppName "Request Router" `
    -AppExecutablePath "C:\Program Files\IIS\Application Request Routing" `
    -InstallerUrl "https://download.microsoft.com/download/E/9/8/E9849D6A-020E-47E4-9FD0-A023E99B54EB/requestRouter_amd64.msi" `
    -InstallerPath "$tempInstallerPath\requestRouter_x64.msi" `
    -InstallArgs "/quiet /norestart"


$nssmDestinationFolder = "C:\Program Files\nssm-2.24"
if (!(Test-Path $nssmDestinationFolder)) {
    New-Item -ItemType Directory -Path $nssmDestinationFolder
    
    $nssmUrl = "https://nssm.cc/release/nssm-2.24.zip"
    $nssmZipFilePath = "$nssmDestinationFolder\nssm-2.24.zip"
    Invoke-WebRequest -Uri $nssmUrl -OutFile $nssmZipFilePath
    Expand-Archive -Path $nssmZipFilePath -DestinationPath (Get-Item $nssmDestinationFolder).Parent.FullName -Force

    Remove-Item $nssmZipFilePath -Force
    Write-Host "nssm has been installed."
} Else {
    Write-Host "nssm is already installed."
}

$dockerDestinationFolder = "C:\Program Files\docker"
if (!(Test-Path $dockerDestinationFolder)) {
    New-Item -ItemType Directory -Path $dockerDestinationFolder
    
    $dockerUrl = "https://download.docker.com/win/static/stable/x86_64/docker-28.3.3.zip"
    $dockerZipFilePath = "$dockerDestinationFolder\docker-28.3.3.zip"
    Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerZipFilePath
    Expand-Archive -Path $dockerZipFilePath -DestinationPath (Get-Item $dockerDestinationFolder).Parent.FullName -Force

	Invoke-WebRequest "https://github.com/docker/compose/releases/download/v2.39.1/docker-compose-windows-x86_64.exe" -OutFile "$dockerDestinationFolder\docker-compose.exe"

	$env:Path += ";C:\Program Files\docker"
	[Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Machine)
	
    Remove-Item $dockerZipFilePath -Force
    Write-Host "Docker has been installed."
} Else {
    Write-Host "Docker is already installed."
}

# Define paths to Docker and NSSM executables
$dockerdPath = "$dockerDestinationFolder\dockerd.exe"
$nssmPath = "$nssmDestinationFolder\win64\nssm.exe"

# Define the Windows service name
$dockerdServiceName = "DockerEngine"

# Check if the service already exists
$existingService = Get-Service -Name $dockerdServiceName -ErrorAction SilentlyContinue

if ($existingService) {
    Write-Host "Service '$dockerdServiceName' already exists."
} else {
    # Create the service using NSSM
    & "$nssmPath" install $dockerdServiceName "$dockerdPath"

    # Set the service to start automatically at boot
    & "$nssmPath" set $dockerdServiceName Start SERVICE_AUTO_START

    # Start the service
    Start-Service $dockerdServiceName

    Write-Host "Service '$dockerdServiceName' has been created and started."  -ForegroundColor Cyan
}

$handleDestinationFolder = "C:\Program Files\Handle"
if (!(Test-Path $handleDestinationFolder)) {
    New-Item -ItemType Directory -Path $handleDestinationFolder
    
    $handleUrl = "https://download.sysinternals.com/files/Handle.zip"
    $handleZipFilePath = "$handleDestinationFolder\Handle.zip"
    Invoke-WebRequest -Uri $handleUrl -OutFile $handleZipFilePath
    Expand-Archive -Path $handleZipFilePath -DestinationPath $handleDestinationFolder -Force
    Remove-Item $handleZipFilePath -Force
    Write-Host "Handle has been installed."
} Else {
    Write-Host "Handle is already installed."
}
	
$winAcmeDestinationFolder = "C:\Program Files\Win-Acme"
if (!(Test-Path $winAcmeDestinationFolder)) {
    New-Item -ItemType Directory -Path $winAcmeDestinationFolder

    $winAcmeUrl = "https://github.com/win-acme/win-acme/releases/download/v2.2.9.1701/win-acme.v2.2.9.1701.x64.pluggable.zip"
    $winAcmeZipFilePath = "$winAcmeDestinationFolder\win-acme.zip"
    Invoke-WebRequest -Uri $winAcmeUrl -OutFile $winAcmeZipFilePath
    Expand-Archive -Path $winAcmeZipFilePath -DestinationPath $winAcmeDestinationFolder -Force
    Remove-Item $winAcmeZipFilePath -Force
    Write-Host "Win-Acme has been installed."
} Else {
    Write-Host "Win-Acme is already installed."
}

$winAcmePluginDestinationFolder = "C:\Program Files\Win-Acme\plugin.validation.dns.cloudflare.v2.2.9.1701"
if (!(Test-Path $winAcmePluginDestinationFolder)) {
    New-Item -ItemType Directory -Path $winAcmePluginDestinationFolder

    $winAcmePluginUrl = "https://github.com/win-acme/win-acme/releases/download/v2.2.9.1701/plugin.validation.dns.cloudflare.v2.2.9.1701.zip"
    $winAcmePluginZipFilePath = "$winAcmePluginDestinationFolder\plugin.validation.dns.cloudflare.v2.2.9.1701.zip"
    Invoke-WebRequest -Uri $winAcmePluginUrl -OutFile $winAcmePluginZipFilePath
    Expand-Archive -Path $winAcmePluginZipFilePath -DestinationPath $winAcmePluginDestinationFolder -Force
    Remove-Item $winAcmePluginZipFilePath -Force
    Write-Host "Win-Acme plugin.validation.dns.cloudflare has been installed."
} Else {
    Write-Host "Win-Acme plugin.validation.dns.cloudflare is already installed."
}

$pgInstallArgs = @(
    "--mode", "unattended",
    "--superpassword", "postgres",
    "--prefix", "`"C:\Program Files\PostgreSQL\18`"",
    "--datadir", "`"C:\Program Files\PostgreSQL\18\data`"",
    "--unattendedmodeui", "none",
    "--install_runtimes", "1" # Skip installing VC++ runtimes (optional)
) -join " "

# Install PostgreSQL 18 Server if not already installed
Install-Application -AppName "PostgreSQL 18 Server" `
    -AppExecutablePath "C:\Program Files\PostgreSQL\18" `
    -InstallerUrl "https://get.enterprisedb.com/postgresql/postgresql-18.0-2-windows-x64.exe" `
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
$pgDataPath = "C:\\Program Files\\PostgreSQL\\18\\data"
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
Restart-Service -Name "postgresql-x64-18"

Write-Host "PostgreSQL setup complete. Remote connections enabled, password is 'postgres'." -ForegroundColor Green

Remove-Item -Path $tempInstallerPath -Recurse -Force