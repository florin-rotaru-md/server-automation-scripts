# Set-ExecutionPolicy Unrestricted

# ======================================
# Create a new "Server Mode" power plan
# OS: Windows 11
# ======================================

# | Setting                   | Plugged in | On battery |
# | ------------------------- | ---------- | ---------- |
# | **Turn off display**      | 1 min      | 1 min      |
# | **Sleep**                 | Never      | 3 hours    |
# | **Turn off SSD/HDD**      | Never      | 30 min     |
# | **Minimum CPU state**     | 1%         | 1%         |
# | **Maximum CPU state**     | 100%       | 40%        |
# | **Lid close action**      | Do nothing | Do nothing |
# | **Hibernation**           | Off        | Off        |

# ======================================
# Create or Update "Server Mode" Power Plan
# OS: Windows 11
# ======================================

$newSchemeName = "Server Mode"
$baseScheme = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"  # High Performance GUID

# Function to apply all custom settings to a given plan GUID
function Set-ServerModeSettings {
    param($schemeGuid)

    Write-Host "Applying settings to $newSchemeName..." -ForegroundColor Cyan

    # Turn off display after (minutes)
    powercfg /setacvalueindex $schemeGuid SUB_VIDEO VIDEOIDLE 1
    powercfg /setdcvalueindex $schemeGuid SUB_VIDEO VIDEOIDLE 1

    # Sleep after (minutes)
    powercfg /setacvalueindex $schemeGuid SUB_SLEEP STANDBYIDLE 0
    powercfg /setdcvalueindex $schemeGuid SUB_SLEEP STANDBYIDLE 180

    # Turn off hard disk after (seconds)
    powercfg /setacvalueindex $schemeGuid SUB_DISK DISKIDLE 0
    powercfg /setdcvalueindex $schemeGuid SUB_DISK DISKIDLE 1800

    # Minimum processor state (%)
    powercfg /setacvalueindex $schemeGuid SUB_PROCESSOR PROCTHROTTLEMIN 1
    powercfg /setdcvalueindex $schemeGuid SUB_PROCESSOR PROCTHROTTLEMIN 1

    # Maximum processor state (%)
    powercfg /setacvalueindex $schemeGuid SUB_PROCESSOR PROCTHROTTLEMAX 100
    powercfg /setdcvalueindex $schemeGuid SUB_PROCESSOR PROCTHROTTLEMAX 40

    # Lid close action
    powercfg /setacvalueindex $schemeGuid SUB_BUTTONS LIDACTION 0
    powercfg /setdcvalueindex $schemeGuid SUB_BUTTONS LIDACTION 0
}

# Check if the plan already exists
$existingSchemeGuid = (powercfg /list | Select-String -Pattern $newSchemeName) -replace '.*GUID: ([a-f0-9\-]+).*', '$1'

if ($existingSchemeGuid) {
    Write-Host "Power plan '$newSchemeName' already exists. Updating settings..." -ForegroundColor Yellow
    Set-ServerModeSettings $existingSchemeGuid
    $schemeToActivate = $existingSchemeGuid
} else {
    Write-Host "Power plan '$newSchemeName' does not exist. Creating it..." -ForegroundColor Cyan
    $newSchemeGuid = (powercfg /duplicatescheme $baseScheme) -replace '.*: ([a-f0-9\-]+).*', '$1'
    powercfg /changename $newSchemeGuid "$newSchemeName"
    Set-ServerModeSettings $newSchemeGuid
    $schemeToActivate = $newSchemeGuid
}

# Disable hibernation globally
Write-Host "Disabling hibernation..." -ForegroundColor Yellow
powercfg /hibernate off

# Activate the plan
powercfg /setactive $schemeToActivate
Write-Host "Power plan '$newSchemeName' is now active with all custom settings applied." -ForegroundColor Green
