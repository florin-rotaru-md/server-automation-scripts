function Uninstall-Product {
    param (
        [string]$ProductName
    )

    # Search for the installed product
    $product = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*$ProductName*" } | Select-Object -First 1

    if ($product) {
        Write-Host "Found '$($product.Name)' installed. Starting uninstallation..." -ForegroundColor Yellow
        $productCode = $product.IdentifyingNumber

        # Uninstall silently
        $uninstallArgs = "/x $productCode /quiet"
        Start-Process "msiexec.exe" -ArgumentList $uninstallArgs -Wait

        Write-Host "'$ProductName' has been uninstalled." -ForegroundColor Green
    } else {
        Write-Host "'$ProductName' is not installed." -ForegroundColor Gray
    }
}