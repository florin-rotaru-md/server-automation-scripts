<#
.SYNOPSIS
    Backup and restore Windows Balanced power plan (overwrite mode).

.DESCRIPTION
    -Backup   : Exports the current Balanced power plan to PowerPlan.pow in the current directory (unless ExportPath is specified).
    -Restore  : Restores Balanced from PowerPlan.pow, deleting the existing Balanced plan first and overwriting it.
#>

param(
    [switch]$Backup,
    [switch]$Restore,
    [string]$ExportPath = (Join-Path -Path (Get-Location) -ChildPath "PowerPlan.pow")
)

# Balanced GUID (fixed)
$balancedGuid = "381b4222-f694-41f0-9685-ff5bb260df2e"

function Backup-Balanced {
    Write-Host ">> Exporting Balanced power plan to $ExportPath ..."
    powercfg /export "$ExportPath" $balancedGuid

    if (Test-Path $ExportPath) {
        Write-Host ">> Backup completed successfully."
    } else {
        Write-Host "!! Backup failed."
    }
}

function Restore-Balanced {
    if (-not (Test-Path $ExportPath)) {
        Write-Host "!! Backup file not found at $ExportPath"
        exit 1
    }

    Write-Host ">> Switching to High Performance plan to allow deleting Balanced..."
    $highPerfGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    powercfg /setactive $highPerfGuid

    Write-Host ">> Deleting existing Balanced plan..."
    try {
        powercfg /delete $balancedGuid
        Write-Host "   - Balanced plan deleted."
    } catch {
        Write-Host "   - Could not delete Balanced plan (may not exist, safe to continue)."
    }

    Write-Host ">> Importing Balanced plan from $ExportPath ..."
    powercfg /import "$ExportPath" $balancedGuid

    Write-Host ">> Activating Balanced plan..."
    powercfg /setactive $balancedGuid

    Write-Host ">> Balanced plan has been restored and activated."
}

if ($Backup) {
    Backup-Balanced
} elseif ($Restore) {
    Restore-Balanced
} else {
    Write-Host "Usage:"
    Write-Host "  .\PowerPlan.ps1 -Backup   (to export Balanced)"
    Write-Host "  .\PowerPlan.ps1 -Restore  (to restore Balanced)"
    Write-Host "Optional parameter: -ExportPath <file path>"
}
