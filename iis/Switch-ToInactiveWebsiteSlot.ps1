function Switch-ToInactiveWebsiteSlot {
    <#
        .SYNOPSIS
            Determines active IIS site based on current production binding and deploys to the inactive slot.
        .PARAMETER HostName
            The host name used in bindings (e.g., yoursite.com).
        .PARAMETER BlueWebSiteName
            Name of the blue slot IIS website.
        .PARAMETER GreenWebSiteName
            Name of the green slot IIS website.
        .PARAMETER BlueWebSitePath
            Physical path for the blue slot site.
        .PARAMETER GreenWebSitePath
            Physical path for the green slot site.
        .PARAMETER BuildPublishPath
            Path to the output of the dotnet publish.
        .PARAMETER GreenHttpPort
            HTTP port for the green slot site.
        .PARAMETER BlueHttpPort
            HTTP port for the blue slot site.
        .PARAMETER WacsValidationMethod
            Validation method for Let's Encrypt certificate (e.g., http-01, cloudflare-dns).
        .PARAMETER WacsArgsCloudflareTokenPath
            Cloudflare token file path for DNS validation (if applicable).
        .PARAMETER WacsArgsEmailAddress
            Email address for Let's Encrypt notifications.
    #>
    param (
        [string]$HostName,
        [string]$BlueWebSitePath,
        [string]$GreenWebSitePath,
        [string]$BuildPublishPath,
        [int]$GreenHttpPort,
        [int]$BlueHttpPort,
        [ValidateSet("http-01", "cloudflare-dns")]
        [string]$WacsValidationMethod,
        [string]$WacsArgsCloudflareTokenPath,
        [string]$WacsArgsEmailAddress
        #[scriptblock]$ConfirmPathsCallback
    )

    Import-Module WebAdministration

    . ".\Confirm-WebSite.ps1"
    . ".\Get-ExistingLetsEncryptCertificate.ps1"
    . ".\Remove-DirectoryContents.ps1"
    . ".\Request-CloudflareDns01LetsEncryptCertificate.ps1"
    . ".\Request-Http01LetsEncryptCertificate.ps1"
    . ".\Set-LetsEncryptCertificateToIIS.ps1"
    . ".\Test-WebsiteHealth.ps1"

    $inactiveWebSiteName = $null
    $inactiveWebSitePath = $null
    $inactiveWebSiteHttpPort = 0

    Write-Host "Confirm - $HostName on ${HostName}_green - WebSite"
    Confirm-WebSite -WebSiteName "${HostName}_green" `
        -HostName $HostName `
        -PhysicalPath $GreenWebSitePath `
        -GreenHttpPort $GreenHttpPort `
        -BlueHttpPort $BlueHttpPort
    
    Write-Host "Confirm - $HostName on ${HostName}_blue - WebSite"
    Confirm-WebSite -WebSiteName "${HostName}_blue" `
        -HostName $HostName `
        -PhysicalPath $BlueWebSitePath `
        -GreenHttpPort $GreenHttpPort `
        -BlueHttpPort $BlueHttpPort

    $tempCompressedFiles = "C:\inetpub\temp\IIS Temporary Compressed Files"

    Confirm-Paths -Paths @("$tempCompressedFiles\${HostName}_green", "$tempCompressedFiles\${HostName}_blue")
    icacls "$tempCompressedFiles" /grant IIS_IUSRS:F

    Write-Host "Determining active / inactive WebSite slot..."

    # Get binding info
    Write-Host "Trying to get *:443:$HostName binding..."
    $bindingInfo = Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:443:$HostName" } | Select-Object -First 1
     
    if (!$bindingInfo) {
        Write-Host "Trying to get *:80:$HostName binding..."
        $bindingInfo = Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:80:$HostName" } | Select-Object -First 1
    }

    if (!$bindingInfo) {
        Write-Host "Trying to get *:${BlueHttpPort}:$HostName binding..."
        $bindingInfo = Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:${BlueHttpPort}:$HostName" } | Select-Object -First 1
    }

    $activeWebSiteName = $bindingInfo.ItemXPath -replace ".*name='([^']+)'.*", '$1'
    if (!$bindingInfo -or $activeWebSiteName -notmatch "_(blue|green)$") {
        throw "Could not determine active WebSite via bindings for $HostName."
    }
    
    Write-Host "Found $($bindingInfo.ItemXPath) binding"

    # Determine inactive slot + paths
    if ($activeWebSiteName -eq "${HostName}_blue") {
        $inactiveWebSiteName = "${HostName}_green"
        $inactiveWebSitePath = $GreenWebSitePath
        $inactiveWebSiteHttpPort = $GreenHttpPort
    }
    else {
        $inactiveWebSiteName = "${HostName}_blue"
        $inactiveWebSitePath = $BlueWebSitePath
        $inactiveWebSiteHttpPort = $BlueHttpPort
    }

    # # Confirm path is valid (optional validation callback)
    # if ($ConfirmPathsCallback) {
    #     $ConfirmPathsCallback.Invoke($inactiveWebSitePath)
    # }

    Write-Host "Active Site: $activeWebSiteName, Deploying to inactive site: $inactiveWebSiteName at $inactiveWebSitePath" -ForegroundColor Green

    # Stop AppPool if needed
    $state = Get-WebAppPoolState -Name $inactiveWebSiteName
    if ($state.Value -ne "Stopped") {
        Write-Host "Stopping App Pool for $inactiveWebSiteName"
        Stop-WebAppPool -Name $inactiveWebSiteName
        do {
            Start-Sleep -Milliseconds 330
            $state = Get-WebAppPoolState -Name $inactiveWebSiteName
        } while ($state.Value -ne "Stopped")
    }

    # Copy build output
    Write-Host "Copying published files to $inactiveWebSitePath..."
    Copy-Item -Path "${BuildPublishPath}\*" -Destination "$inactiveWebSitePath" -Recurse -Force

    # Update site path explicitly (IIS metadata update)
    Set-ItemProperty "IIS:\\Sites\\$inactiveWebSiteName" -Name physicalPath -Value $inactiveWebSitePath

    $activeHttpWebSiteBindingInfo = Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:80:$HostName" } | Select-Object -First 1
    if ($activeHttpWebSiteBindingInfo) {
        $activeHttpWebSiteName = $activeHttpWebSiteBindingInfo.ItemXPath -replace ".*name='([^']+)'.*", '$1'
                
        if ($activeHttpWebSiteName -ne $inactiveWebSiteName) {
            Write-Host "Remove (*:80:$HostName) binding"
            Remove-WebBinding -BindingInformation "*:80:$HostName"

            Write-Host "Create new binding (*:80:$HostName) for $($inactiveWebSiteName)"
            New-WebBinding -Name $inactiveWebSiteName -Protocol http -Port 80 -IPAddress "*" -HostHeader "$HostName"
        }
    }
    else {
        Write-Host "Create new binding (*:80:$HostName) for $($inactiveWebSiteName)"
        New-WebBinding -Name $inactiveWebSiteName -Protocol http -Port 80 -IPAddress "*" -HostHeader "$HostName"
    }

    # Start AppPool
    Start-WebAppPool -Name $inactiveWebSiteName

    Test-WebsiteHealth -Url "http://localhost:$inactiveWebSiteHttpPort/.well-known/live" `
        -Headers @{"Host" = "${HostName}:$inactiveWebSiteHttpPort" } `
        -Attempts 33 `
        -TimeoutSec 1 `
        -PauseSec 3

    $cert = Get-ExistingLetsEncryptCertificate -HostName $HostName -MinimumDaysValid 3
    $thumbprint = $null
    if ($cert) {
        Write-Host "Valid cert exists for $HostName (expires: $($cert.NotAfter))"
        $thumbprint = $cert.Thumbprint
    }
    else {
        Write-Host "Requesting new certificate for $HostName using $WacsValidationMethod" -ForegroundColor Green

        switch ($WacsValidationMethod) {
            "http-01" {
                $thumbprint = Request-Http01LetsEncryptCertificate `
                    -Hostname $HostName `
                    -WebRoot "$inactiveWebSitePath" `
                    -WacsArgsEmailAddress $WacsArgsEmailAddress
            }
            "cloudflare-dns" { 
                $thumbprint = Request-CloudflareDns01LetsEncryptCertificate `
                    -Hostname $HostName `
                    -WacsArgsCloudflareTokenPath $WacsArgsCloudflareTokenPath `
                    -WacsArgsEmailAddress $WacsArgsEmailAddress
            }
            Default { throw "Invalid WacsValidationMethod: $WacsValidationMethod" }
        }  
    }

    Set-LetsEncryptCertificateToIIS -WebSiteName $inactiveWebSiteName `
        -HostName $HostName `
        -Thumbprint $thumbprint `
        -HttpsPort 443

    Write-Host "Remove - non active WebSite versions of $inactiveWebSiteName" -ForegroundColor Green
    Remove-DirectoryContents -Directory (Get-Item $inactiveWebSitePath).Parent.FullName -ExcludeNames @((Get-Item $inactiveWebSitePath).Name)
}
