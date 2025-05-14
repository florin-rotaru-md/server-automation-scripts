function Get-ExistingLetsEncryptCertificate {
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
