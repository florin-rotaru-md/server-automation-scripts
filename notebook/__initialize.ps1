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
# | **USB selective suspend** | Disabled   | Disabled   |
# | **Hibernation**           | Off        | Off        |


# 1. Create a new plan based on High Performance
$baseScheme = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"  # High performance GUID
$newSchemeName = "Server Mode"
Write-Host "Creating new power plan: $newSchemeName..." -ForegroundColor Cyan
$newSchemeGuid = (powercfg /duplicatescheme $baseScheme) -replace '.*: ([a-f0-9\-]+).*', '$1'

# 2. Rename the new plan
powercfg /changename $newSchemeGuid "$newSchemeName"

# 3. Turn off display after (minutes)
powercfg /setacvalueindex $newSchemeGuid SUB_VIDEO VIDEOIDLE 1     # Plugged in: 1 min
powercfg /setdcvalueindex $newSchemeGuid SUB_VIDEO VIDEOIDLE 1     # On battery: 1 min

# 4. Put the computer to sleep after (minutes)
powercfg /setacvalueindex $newSchemeGuid SUB_SLEEP STANDBYIDLE 0   # Plugged in: Never
powercfg /setdcvalueindex $newSchemeGuid SUB_SLEEP STANDBYIDLE 180 # On battery: 3h

# 5. Turn off hard disk after (seconds)
powercfg /setacvalueindex $newSchemeGuid SUB_DISK DISKIDLE 0       # Plugged in: Never (SSD safe)
powercfg /setdcvalueindex $newSchemeGuid SUB_DISK DISKIDLE 1800    # On battery: 30 min

# 6. Minimum processor state (%)
powercfg /setacvalueindex $newSchemeGuid SUB_PROCESSOR PROCTHROTTLEMIN 1  # Plugged in: 1%
powercfg /setdcvalueindex $newSchemeGuid SUB_PROCESSOR PROCTHROTTLEMIN 1  # On battery: 1%

# 7. Maximum processor state (%)
powercfg /setacvalueindex $newSchemeGuid SUB_PROCESSOR PROCTHROTTLEMAX 100 # Plugged in: 100%
powercfg /setdcvalueindex $newSchemeGuid SUB_PROCESSOR PROCTHROTTLEMAX 40  # On battery: 40%

# 8. Lid close action
# 0 = Do nothing, 1 = Sleep, 2 = Hibernate, 3 = Shut down
powercfg /setacvalueindex $newSchemeGuid SUB_BUTTONS LIDACTION 0
powercfg /setdcvalueindex $newSchemeGuid SUB_BUTTONS LIDACTION 0

# 9. Disable USB selective suspend
# 0 = Disable, 1 = Enable
powercfg /setacvalueindex $newSchemeGuid SUB_USB USBSELECTIVE 0
powercfg /setdcvalueindex $newSchemeGuid SUB_USB USBSELECTIVE 0

# 10. Disable hibernation globally
Write-Host "Disabling hibernation..." -ForegroundColor Yellow
powercfg /hibernate off

# 11. Activate the new plan
powercfg /setactive $newSchemeGuid

Write-Host "Power plan '$newSchemeName' created and activated successfully." -ForegroundColor Green
