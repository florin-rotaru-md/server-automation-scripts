function Set-RegistryPropertyIfExists {
    <#
        .SYNOPSIS
        Sets a registry property if the specified path exists.
        .DESCRIPTION
        This function checks if a registry path exists and sets a property with the specified name and value.
        .PARAMETER path
        The registry path to check.
        .PARAMETER name
        The name of the registry property to set.
        .PARAMETER value
        The value to set for the registry property.
        .EXAMPLE
        Set-RegistryPropertyIfExists -path "HKLM:\SOFTWARE\MyApp" -name "MySetting" -value 1
        This command sets the registry property "MySetting" to 1 if the path exists.
    #>
    [CmdletBinding()]
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