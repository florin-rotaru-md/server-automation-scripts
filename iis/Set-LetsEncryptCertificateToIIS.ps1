function Set-LetsEncryptCertificateToIIS {
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