$policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"

If (-not (Test-Path $policyPath)) {
    New-Item -Path $policyPath -Force | Out-Null
}

If (-not (Get-ItemProperty -Path $policyPath -Name "AUOptions" -ErrorAction SilentlyContinue)) {
    New-ItemProperty -Path $policyPath -Name "AUOptions" -Value 7 -PropertyType DWord -Force | Out-Null
} Else {
    Set-ItemProperty -Path $policyPath -Name "AUOptions" -Value 7 -Type DWord
}

If (-not (Get-ItemProperty -Path $policyPath -Name "NoAutoUpdate" -ErrorAction SilentlyContinue)) {
    New-ItemProperty -Path $policyPath -Name "NoAutoUpdate" -Value 0 -PropertyType DWord -Force | Out-Null
} Else {
    Set-ItemProperty -Path $policyPath -Name "NoAutoUpdate" -Value 0 -Type DWord
}


Write-Host "Applying Group Policy changes..."
gpupdate /force