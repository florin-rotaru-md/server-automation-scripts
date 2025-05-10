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
        [string]$SiteName,
        [string]$BlueWebSitePath,
        [string]$GreenWebSitePath,
        [string]$BuildPublishPath
        #[scriptblock]$ConfirmPathsCallback
    )

    . ".\Test-WebsiteHealth.ps1"

    $config = Get-Content ".\Config.json" | ConvertFrom-Json
    $inactiveWebSiteName = $null
    $inactiveWebSitePath = $null
    $inactiveWebSitePort = 0

    Write-Host "Determining active / inactive WebSite slot..." -ForegroundColor Cyan

    # Get binding info
    $bindingInfo = Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:80:$SiteName" } | Select-Object -First 1
     
    if (!$bindingInfo) {
        $bindingInfo = Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:$($config.ports.blue):$SiteName" } | Select-Object -First 1
    }

    $activeWebSiteName = $bindingInfo.ItemXPath -replace ".*name='([^']+)'.*", '$1'

    if (!$bindingInfo -or $activeWebSiteName -notmatch "_(blue|green)$") {
        throw "Could not determine active site via bindings for $SiteName."
    }

    # Determine inactive slot + paths
    if ($activeWebSiteName -eq "${site}_blue") {
        $inactiveWebSiteName = "${site}_green"
        $inactiveWebSitePath = $GreenWebSitePath
        $inactiveWebSitePort = $config.green.port
    }
    else {
        $inactiveWebSiteName = "${site}_blue"
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
        -Headers @{"Host" = "${site}:$inactiveWebSitePort"} `
        -Attempts 33 `
        -TimeoutSec 1 `
        -PauseSec 3

    $activeWebSiteBindingInfo = Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:80:$SiteName" } | Select-Object -First 1
    
    if ($activeWebSiteBindingInfo) {
        $activeWebSiteName = $activeWebSiteBindingInfo.ItemXPath -replace ".*name='([^']+)'.*", '$1'
        
        Write-Host "Removing "*:80:$SiteName" binding for $activeWebSiteName" -ForegroundColor Green
        Remove-WebBinding -Name $activeWebSiteName -BindingInformation "*:80:$SiteName" -Protocol http
    }
    
    Write-Host "New binding *:80:$SiteName for $($inactiveWebSiteName)" -ForegroundColor Green
    New-WebBinding -Name $inactiveWebSiteName -Protocol http -Port 80 -IPAddress "*" -HostHeader "$SiteName"
    
    return @{
        ActiveWebSiteName   = $activeWebSiteName
        InactiveWebSiteName = $inactiveWebSiteName
        InactiveWebSitePath = $inactiveWebSitePath
        InactiveWebSitePort = $inactiveWebSitePort
    }
}
