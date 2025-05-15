function Install-Application {
    param (
        [string]$AppName, # Name of the application (e.g., Notepad++, VSCode)
        [string]$AppExecutablePath, # Path to check if the app is already installed
        [string]$InstallerUrl, # URL to download the installer
        [string]$InstallerPath, # Temporary path for the installer
        [string]$InstallArgs = "/S" # Arguments for silent installation
    )

	$ProgressPreference = 'SilentlyContinue'
	
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