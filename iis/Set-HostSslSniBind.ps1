function Set-HostSslSniBind {
    <#
        .SYNOPSIS
        Sets the SSL SNI binding for a specified IIS website.
        .DESCRIPTION
        This function checks if an SSL SNI binding exists for the specified hostname and port. If it does, it removes it and creates a new one.
        .PARAMETER WebSiteName
        The name of the IIS website to bind the SSL certificate to.
        .PARAMETER HostName
        The hostname for the SSL binding.
        .EXAMPLE
        Set-HostSslSniBind -WebSiteName "MyWebsite" -HostName "example.com"
        This command sets the SSL SNI binding for the "MyWebsite" IIS website to the hostname "example.com".
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WebSiteName,

        [Parameter(Mandatory = $true)]
        [string]$HostName
    )

    $webSiteBindingInfo = Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:443:$HostName" } | Select-Object -First 1

    if ($webSiteBindingInfo) {
        Write-Host "Remove (*:443:$HostName) binding"
        Remove-WebBinding -BindingInformation "*:443:$HostName"
        $webSiteBindingInfo = $null
    }
    
    if (!$webSiteBindingInfo) {
        Write-Host "Creating new SSL binding (443:$HostName)"
        New-WebBinding -Name $WebSiteName -Protocol https -Port 443 -IPAddress "*" -HostHeader $HostName -SslFlags 3
    }
}
