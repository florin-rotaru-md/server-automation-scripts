function Confirm-WebSite {
	param (
		[string]$WebSiteName,
		[string]$HostName,
		[string]$PhysicalPath
	)
	<#
	.SYNOPSIS
		Ensure that the specified IIS website exists, creating it if necessary.
	.DESCRIPTION
		This function checks if the specified IIS website exists. If it does not exist, it creates the website and its associated application pool.
	.PARAMETER WebSiteName
		The name of the IIS website to check or create.
	.PARAMETER HostName
		The host name used in bindings (e.g., yoursite.com).
	.PARAMETER PhysicalPath
		The physical path to the website's content.	
	.EXAMPLE
		Confirm-WebSite -WebSiteName "MyWebsite" -HostName "www.example.com" -PhysicalPath "C:\inetpub\wwwroot\MyWebsite"
	#>

	. ".\Confirm-Paths.ps1"
	
	$httpPort = 0

	$config = Get-Content ".\Config.json" | ConvertFrom-Json
	if ($WebSiteName -match "_(green|blue)$") {
		$webSiteEnding = $matches[1]
		if ($webSiteEnding -eq "green") {
			$httpPort = $config.green.httpPort
		}
		else {
			$httpPort = $config.blue.httpPort
		} 
	}
	else {
		throw "WebSiteName must end with either '_green' or '_blue'."
	}

	$webSite = Get-Website -Name $WebSiteName -ErrorAction SilentlyContinue | Select-Object -First 1

	function Add-WebSite {
		Confirm-Paths -Paths $PhysicalPath

		if (Test-Path "IIS:\AppPools\$WebSiteName") {
			Write-Host "App pool '$WebSiteName' already exists. Removing it..."
			Remove-WebAppPool -Name $WebSiteName -ErrorAction SilentlyContinue
		}
	
		if (Get-Website -Name $WebSiteName -ErrorAction SilentlyContinue) {
			Remove-WebSite -Name $WebSiteName -ErrorAction SilentlyContinue
		}

		New-WebAppPool -Name $WebSiteName
		Set-ItemProperty "IIS:\AppPools\$WebSiteName" -Name "managedRuntimeVersion" -Value ""
		Set-ItemProperty "IIS:\AppPools\$WebSiteName" -Name "processModel.loadUserProfile" -Value $true
		
		New-Website -Name $WebSiteName -Port $httpPort -IPAddress "*" -HostHeader $HostName -PhysicalPath $PhysicalPath -ApplicationPool $WebSiteName
	}

	if (!$webSite) {
		Write-Host "Creating IIS site and app pool..."
		Add-WebSite
		return
	}
 	else {
		Write-Host "IIS site '$WebSiteName' already exists. Checking bindings..."
		$webSiteBindingInfo = Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:${httpPort}:$HostName" } | Select-Object -First 1
		if (!$webSiteBindingInfo) {
			Add-WebSite
			return
		}

		$bindWebSiteName = $webSiteBindingInfo.ItemXPath -replace ".*name='([^']+)'.*", '$1'
		if (($bindWebSiteName -ne $WebSiteName) -or ($webSiteBindingInfo.protocol -ne "http")) {
			Write-Host "Remove (*:${httpPort}:$HostName) binding"
			Remove-WebBinding -BindingInformation "*:${httpPort}:$HostName"
			$webSiteBindingInfo = $null
		}

		if (!$webSiteBindingInfo) {
			Add-WebSite
			return
		}
	}
}
