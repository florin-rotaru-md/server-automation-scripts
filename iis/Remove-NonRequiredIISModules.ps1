function Remove-NonRequiredIISModules {
    param (
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
        if (!($RequiredModules -contains $name)) {
            try {
                Write-Host "Removing: $name" -ForegroundColor Yellow
                Remove-WebGlobalModule -Name $name -ErrorAction Stop
            } catch {
                Write-Host "Failed to remove ${name}: $_" -ForegroundColor Red
            }
        }
    }
}
