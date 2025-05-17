function Set-LetsEncryptCertificateToIIS {
    <#
        .SYNOPSIS
        Binds a Let's Encrypt certificate to an IIS website.
        .DESCRIPTION
        This function binds a Let's Encrypt certificate to the specified IIS website using the provided hostname and thumbprint.
        .PARAMETER WebSiteName
        The name of the IIS website to bind the certificate to.
        .PARAMETER HostName
        The hostname for the SSL binding.
        .PARAMETER Thumbprint
        The thumbprint of the certificate to bind.
        .PARAMETER HttpsPort
        The HTTPS port for the binding (default is 443).
        .EXAMPLE
        Set-LetsEncryptCertificateToIIS -WebSiteName "MyWebsite" -HostName "example.com" -Thumbprint "ABC1234567890ABC1234567890ABC1234567890AB"
        This command binds the specified Let's Encrypt certificate to the "MyWebsite" IIS website for the hostname "example.com" on port 443.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WebSiteName,
    
        [Parameter(Mandatory = $true)]
        [string]$HostName,

        [Parameter(Mandatory = $true)]
        [string]$Thumbprint,

        [Parameter(Mandatory = $false)]
        [int]$HttpsPort = 443
    )

    $ErrorActionPreference = "Stop"
    
    Import-Module WebAdministration
    Write-Host "Bind (${HostName}:$HttpsPort) certificate to: $WebSiteName" -ForegroundColor Green

    if (-not (Get-Item "IIS:\Sites\$WebSiteName" -ErrorAction SilentlyContinue)) {
        throw "'$WebSiteName' WebSite not found"
    }

    $webSiteBindingInfo = Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:${HttpsPort}:$HostName" } | Select-Object -First 1
    if ($webSiteBindingInfo) {
        $bindWebSiteName = $webSiteBindingInfo.ItemXPath -replace ".*name='([^']+)'.*", '$1'
            
        if (($bindWebSiteName -ne $WebSiteName) -or ($webSiteBindingInfo.protocol -ne "https") -or ($webSiteBindingInfo.certificateHash -ne $Thumbprint.ToUpper())) {
            Write-Host "Remove (*:${HttpsPort}:$HostName) binding"
            Remove-WebBinding -BindingInformation "*:${HttpsPort}:$HostName"
            $webSiteBindingInfo = $null
        }
    }
   
    if ($webSiteBindingInfo) {
        Write-Host "Binding certificate ($Thumbprint) to $WebSiteName (${HttpsPort}:$HostName)"
        $webSiteBindingInfo.AddSslCertificate($Thumbprint, "My")
        return
    }
    
    $sslBinding = Get-ChildItem "IIS:\SslBindings\" | Where-Object {
        $_.Port -eq $HttpsPort -and
        $_.Host -eq $HostName
    } | Select-Object -First 1
    
    
    if ($sslBinding -and ($sslBinding.Thumbprint -ne $Thumbprint.ToUpper())) {
        Write-Host "Removing existing SSL binding (${HttpsPort}:$HostName)"
        Remove-Item $sslBinding.PSPath -Force
        $sslBinding = $null
    } 
    
    if (!$sslBinding) {
        Write-Host "Creating new SSL binding (${HttpsPort}:$HostName)"
        New-Item "IIS:\SslBindings\0.0.0.0!$HttpsPort!$HostName" -Thumbprint $Thumbprint -SSLFlags 1
    }   

    Write-Host "Binding certificate ($Thumbprint) to $WebSiteName (${HttpsPort}:$HostName)"
    New-WebBinding -Name $WebSiteName -Protocol https -Port $HttpsPort -IPAddress "*" -HostHeader $HostName
    $webSiteBindingInfo = Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:${HttpsPort}:$HostName" } | Select-Object -First 1
    $webSiteBindingInfo.AddSslCertificate($Thumbprint, "My")
}