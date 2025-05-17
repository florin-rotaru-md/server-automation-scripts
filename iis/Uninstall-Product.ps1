function Uninstall-Product {
    <#
        .SYNOPSIS
        Uninstalls a specified product from the system.
        .DESCRIPTION
        This script uninstalls a specified product using its name. It searches for the product in the installed software list and uninstalls it silently.
        .PARAMETER ProductName
        The name of the product to uninstall.
        .EXAMPLE
        Uninstall-Product -ProductName "MySoftware"
        This command uninstalls "MySoftware" from the system.
    #>
    [CmdletBinding()]
    param (
        [string]$ProductName
    )

    # Check if the product name is provided
    if (-not $ProductName) {
        throw "Product name is required."
    }

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