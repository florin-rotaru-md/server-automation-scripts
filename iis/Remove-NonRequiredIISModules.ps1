function Remove-NonRequiredIISModules {
    <#
        .SYNOPSIS
        Removes non-required global IIS modules.
        .DESCRIPTION
        This function removes global IIS modules that are not required for the specified web application.
        .PARAMETER UseModSecurity
        Indicates whether to keep the ModSecurity module.
        .PARAMETER RequiredModules
        An array of required module names. Only these modules will be kept.
        .EXAMPLE
        Remove-NonRequiredIISModules -UseModSecurity $true -RequiredModules @("Module1", "Module2")
        This command removes all global IIS modules except for ModSecurity and the specified modules.
    #>
    [CmdletBinding()]
    param (
        [bool]$UseModSecurity = $false,
        [string[]]$RequiredModules = @(
            "AspNetCoreModuleV2",
            "AnonymousAuthenticationModule",
            "RequestFilteringModule",
            "ApplicationRequestRouting",
            "StaticFileModule",
            "StaticCompressionModule"
        )
    )

    Import-Module WebAdministration

    Write-Host "`n--- Removing Non Required Global IIS Modules ---" -ForegroundColor Cyan
    Write-Host "Required modules: $($RequiredModules -join ', ')" -ForegroundColor Cyan
    
    $globalModules = Get-WebGlobalModule

    foreach ($module in $globalModules) {
        $name = $module.Name
        if ($name.ToLower() -like "*modsecurity*" -and $UseModSecurity) {
            continue
        }

        if (!($RequiredModules -contains $name)) {
            try {
                Write-Host "Removing: $name" -ForegroundColor Yellow
                Remove-WebGlobalModule -Name $name -ErrorAction Stop
            }
            catch {
                Write-Host "Failed to remove ${name}: $_" -ForegroundColor Red
            }
        }
    }
}
