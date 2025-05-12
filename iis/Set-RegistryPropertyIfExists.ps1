function Set-RegistryPropertyIfExists {
    param (
        [string]$path,
        [string]$name,
        [int]$value
    )

    # Check if the registry path exists before modifying
    if (Test-Path $path) {
        New-ItemProperty -Path $path -Name $name -Value $value -PropertyType DWORD -Force
        Write-Output "Updated: $path\$name = $value"
    } else {
        Write-Output "Skipping: Registry path does not exist - $path"
    }
}