function Get-ExistingLetsEncryptCertificate {
    <#
        .SYNOPSIS
            Retrieves an existing Let's Encrypt certificate for a specified hostname.
        .DESCRIPTION
            This function searches the local machine's certificate store for a valid Let's Encrypt certificate that matches the specified hostname and has not expired.
        .PARAMETER HostName
            The hostname for which to retrieve the certificate.
        .PARAMETER MinimumDaysValid
            The minimum number of days the certificate must be valid. Default is 3 days.
        .EXAMPLE
            Get-ExistingLetsEncryptCertificate -HostName "example.com"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$HostName,

        [Parameter(Mandatory = $false)]
        [int]$MinimumDaysValid = 3
    )

    $cert = Get-ChildItem -Path "Cert:\LocalMachine\My" |
    Where-Object {
        $_.Subject -eq "CN=$HostName" -and $_.Issuer -like "*Let's Encrypt*" -and $_.NotAfter -gt (Get-Date).AddDays($MinimumDaysValid)
    } | Select-Object Subject, Issuer, NotBefore, NotAfter, Thumbprint | Sort-Object NotAfter -Descending | Select-Object -First 1

    return $cert
}
