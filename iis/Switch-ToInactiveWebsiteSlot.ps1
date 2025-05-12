function Switch-ToInactiveWebsiteSlot {
    <#
        .SYNOPSIS
            Determines active IIS site based on current production binding and deploys to the inactive slot.
        .PARAMETER SiteName
            The main host name used in bindings (e.g., yoursite.com).
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
        .PARAMETER ConfirmPathsCallback
            ScriptBlock to confirm directory path validity (e.g., Confirm-Paths -Paths <...>).
    #>
    param (
        [string]$WebSiteName,
        [string]$BlueWebSitePath,
        [string]$GreenWebSitePath,
        [string]$BuildPublishPath
        #[scriptblock]$ConfirmPathsCallback
    )

    Import-Module WebAdministration
    . ".\Test-WebsiteHealth.ps1"

    $config = Get-Content ".\Config.json" | ConvertFrom-Json
    $inactiveWebSiteName = $null
    $inactiveWebSitePath = $null
    $inactiveWebSitePort = 0

    Write-Host "Determining active / inactive WebSite slot..." -ForegroundColor Cyan

    # Get binding info
    Write-Host "Trying to get *:80:$WebSiteName binding..."
    $bindingInfo = Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:80:$WebSiteName" } | Select-Object -First 1
     
    if (!$bindingInfo) {
        Write-Host "Trying to get *:$($config.blue.port):$WebSiteName binding..."
        $bindingInfo = Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:$($config.blue.port):$WebSiteName" } | Select-Object -First 1
    }

    Write-Host "Found $($bindingInfo.ItemXPath) binding"

    $activeWebSiteName = $bindingInfo.ItemXPath -replace ".*name='([^']+)'.*", '$1'

    if (!$bindingInfo -or $activeWebSiteName -notmatch "_(blue|green)$") {
        throw "Could not determine active site via bindings for $WebSiteName."
    }

    # Determine inactive slot + paths
    if ($activeWebSiteName -eq "${WebSiteName}_blue") {
        $inactiveWebSiteName = "${WebSiteName}_green"
        $inactiveWebSitePath = $GreenWebSitePath
        $inactiveWebSitePort = $config.green.port
    }
    else {
        $inactiveWebSiteName = "${WebSiteName}_blue"
        $inactiveWebSitePath = $BlueWebSitePath
        $inactiveWebSitePort = $config.blue.port
    }

    # # Confirm path is valid (optional validation callback)
    # if ($ConfirmPathsCallback) {
    #     $ConfirmPathsCallback.Invoke($inactiveWebSitePath)
    # }

    Write-Host "Active Site: $activeWebSiteName" -ForegroundColor Green
    Write-Host "Deploying to inactive site: $inactiveWebSiteName at $inactiveWebSitePath" -ForegroundColor Green

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
    Copy-Item "$BuildPublishPath\*" "$inactiveWebSitePath" -Recurse -Force

    # Update site path explicitly (IIS metadata update)
    Set-ItemProperty "IIS:\\Sites\\$inactiveWebSiteName" -Name physicalPath -Value $inactiveWebSitePath

    # Start AppPool
    Start-WebAppPool -Name $inactiveWebSiteName

    Test-WebsiteHealth -Url "http://localhost:$inactiveWebSitePort/.well-known/live" `
        -Headers @{"Host" = "${WebSiteName}:$inactiveWebSitePort"} `
        -Attempts 33 `
        -TimeoutSec 1 `
        -PauseSec 3

    $activeWebSiteBindingInfo = Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:80:$WebSiteName" } | Select-Object -First 1
    
    if ($activeWebSiteBindingInfo) {
        $activeWebSiteName = $activeWebSiteBindingInfo.ItemXPath -replace ".*name='([^']+)'.*", '$1'
        
        Write-Host "Removing "*:80:$WebSiteName" binding for $activeWebSiteName" -ForegroundColor Green
        Remove-WebBinding -Name $activeWebSiteName -BindingInformation "*:80:$WebSiteName" -Protocol http
    }
    
    Write-Host "New binding *:80:$WebSiteName for $($inactiveWebSiteName)" -ForegroundColor Green
    New-WebBinding -Name $inactiveWebSiteName -Protocol http -Port 80 -IPAddress "*" -HostHeader "$WebSiteName"
    
    return @{
        ActiveWebSiteName   = $activeWebSiteName
        InactiveWebSiteName = $inactiveWebSiteName
        InactiveWebSitePath = $inactiveWebSitePath
        InactiveWebSitePort = $inactiveWebSitePort
    }
}
