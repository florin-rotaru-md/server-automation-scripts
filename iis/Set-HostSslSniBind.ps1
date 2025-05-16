function  Set-HostSslSniBind {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WebSiteName,

        [Parameter(Mandatory = $true)]
        [string]$HostName
    )

    $webSiteBindingInfo = Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:443:$HostName" } | Select-Object -First 1

    if ($webSiteBindingInfo -and (($webSiteBindingInfo.protocol -ne "https") -or ($webSiteBindingInfo.sslFlags -ne 3))) {
        Write-Host "Remove (*:443:$HostName) binding"
        Remove-WebBinding -BindingInformation "*:443:$HostName"
        $webSiteBindingInfo = $null
    }
    
    if (!$webSiteBindingInfo) {
        Write-Host "Creating new SSL binding (443:$HostName)"
        New-WebBinding -Name $WebSiteName -Protocol https -Port 443 -IPAddress "*" -HostHeader $HostName -SslFlags 3
    }
}
