function Confirm-WebSite {
	param (
		[string]$SiteName,
		[int]$Port,
		[string]$HostHeader,
		[string]$PhysicalPath
	)
	<#
	.SYNOPSIS
		Ensure that the specified IIS website exists, creating it if necessary.
	.DESCRIPTION
		This function checks if the specified IIS website exists. If it does not exist, it creates the website and its associated application pool.
	.PARAMETER SiteName
		The name of the IIS website to check or create.
	.PARAMETER Port
		The port number on which the website should listen.
	.PARAMETER HostHeader
		The host header for the website.
	.PARAMETER PhysicalPath
		The physical path to the website's content.	
	.EXAMPLE
		Confirm-WebSite -SiteName "MyWebsite" -Port 80 -HostHeader "www.example.com" -PhysicalPath "C:\inetpub\wwwroot\MyWebsite"
	#>

	. ".\Confirm-Paths.ps1"

	if (-Not (Get-Website -Name $SiteName -ErrorAction SilentlyContinue)) {
		Confirm-Paths -Paths $PhysicalPath
		Write-Host "Creating IIS site and app pool..."

		if (Test-Path "IIS:\AppPools\$SiteName") {
			Write-Host "App pool '$SiteName' already exists. Removing it..."
			Remove-WebAppPool -Name $SiteName -ErrorAction SilentlyContinue
		}

		New-WebAppPool -Name $SiteName
		Set-ItemProperty "IIS:\AppPools\$SiteName" -Name "managedRuntimeVersion" -Value ""
		Set-ItemProperty "IIS:\AppPools\$SiteName" -Name "processModel.loadUserProfile" -Value $true
		
		New-Website -Name $SiteName -Port $Port -IPAddress "*" -HostHeader $HostHeader -PhysicalPath $PhysicalPath -ApplicationPool $SiteName
	}
}