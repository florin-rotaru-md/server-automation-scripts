function Install-Application {
    <#
    .SYNOPSIS
        Installs an application if it is not already installed.
    .DESCRIPTION
        This function checks if a specified application is installed by verifying the existence of its executable file.
        If the application is not installed, it downloads the installer from a specified URL and installs it silently.
    .PARAMETER AppName
        The name of the application to install (e.g., Notepad++, VSCode).
    .PARAMETER AppExecutablePath
        The path to the application's executable file to check if the app is already installed.
    .PARAMETER InstallerUrl
        The URL to download the installer for the application.
    .PARAMETER InstallerPath
        The temporary path where the installer will be downloaded.
    .PARAMETER InstallArgs
        The arguments for silent installation (default is "/S").
    .EXAMPLE
        Install-Application -AppName "Notepad++" -AppExecutablePath "C:\Program Files\Notepad++\notepad++.exe" `
                            -InstallerUrl "https://notepad-plus-plus.org/downloads/v8.4.9/notepad++-8.4.9-installer.exe" `
                            -InstallerPath "C:\Temp\notepad++-installer.exe"
    #>
    [CmdletBinding()]
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