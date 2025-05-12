# Define the product name to search for
$productName = "ModSecurity"

# Search for the installed product
$modSec = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*$productName*" } | Select-Object -First 1

if ($modSec) {
    Write-Host "Found '$($modSec.Name)' installed. Starting uninstallation..." -ForegroundColor Yellow
    $productCode = $modSec.IdentifyingNumber

    # Uninstall silently
    $uninstallArgs = "/x $productCode /quiet"
    Start-Process "msiexec.exe" -ArgumentList $uninstallArgs -Wait

    Write-Host "'$productName' has been uninstalled." -ForegroundColor Green
} else {
    Write-Host "'$productName' is not installed." -ForegroundColor Gray
}