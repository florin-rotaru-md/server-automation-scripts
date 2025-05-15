function Initialize-IIS {
    param (
        [bool]$UseModSecurity = $false
    )

    . ".\Install-Application.ps1"
    . ".\Set-RegistryPropertyIfExists.ps1"
    . ".\Write-CrsRecommendedConfig.ps1"
    . ".\Write-CrsRequest900ExclusionRules.ps1"
    . ".\Write-CrsResponse999ExclusionRules.ps1"
    . ".\Remove-NonRequiredIISModules.ps1"

    Write-Host "Setting up IIS..."

    Remove-NonRequiredIISModules -UseModSecurity $UseModSecurity

    Write-Host "Disable Outdated protocols"
    # Disable SSL 2.0 and SSL 3.0 if paths exist
    Set-RegistryPropertyIfExists -path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server" -name "Enabled" -value 0
    Set-RegistryPropertyIfExists -path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server" -name "Enabled" -value 0

    # Disable TLS 1.0 and TLS 1.1 if paths exist
    Set-RegistryPropertyIfExists -path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Server" -name "Enabled" -value 0
    Set-RegistryPropertyIfExists -path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" -name "Enabled" -value 0

    Write-Host "Enable TLS 1.3 (Server)"
    Set-RegistryPropertyIfExists -path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Server" -name "Enabled" -value 1

    Write-Host "Enable TLS 1.3 (Client)"
    Set-RegistryPropertyIfExists -path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client" -name "Enabled" -value 1

    $tempInstallerPath = "C:\temp"
    New-Item -Path $tempInstallerPath -ItemType Directory -Force | Out-Null

    # https://www.iis.net/downloads/microsoft/application-request-routing
    # Install Request Router (IIS extension)
    Install-Application -AppName "Request Router" `
        -AppExecutablePath "C:\Program Files\IIS\Application Request Routing" `
        -InstallerUrl "https://download.microsoft.com/download/E/9/8/E9849D6A-020E-47E4-9FD0-A023E99B54EB/requestRouter_amd64.msi" `
        -InstallerPath "$tempInstallerPath\requestRouter_x64.msi" `
        -InstallArgs "/quiet /norestart"


    Write-Host "Enabling ARR proxy settings..."
    Import-Module WebAdministration

    Set-WebConfigurationProperty -Filter "system.webServer/proxy" -Name "enabled" -Value "True" -PSPath "IIS:\"
    Set-WebConfigurationProperty -Filter "system.webServer/proxy" -Name "preserveHostHeader" -Value "True" -PSPath "IIS:\"

    if ($UseModSecurity) {
        Write-Host "Enabling ModSecurity..."
        
        # Install ModSecurity for IIS
        Install-Application -AppName "ModSecurity IIS" `
            -AppExecutablePath "C:\Program Files\ModSecurity IIS" `
            -InstallerUrl "https://updates.atomicorp.com/channels/rules/binaries/ModSecurityIIS_2.9.7-64b-64.msi" `
            -InstallerPath "$tempInstallerPath\ModSecurityIIS_2.9.7-64b-64.msi" `
            -InstallArgs "/quiet /norestart"

        $modSecConfPath = "C:\Program Files\ModSecurity IIS\modsecurity.conf"

        if ((Test-Path $modSecConfPath) -and !(Test-Path "${modSecConfPath}.backup")) {
            Write-Host "Creating ModSecurity log folder..."
            New-Item -ItemType Directory -Path "C:\inetpub\logs\modsec" -Force | Out-Null

            icacls "C:\inetpub\logs\modsec\modsec_audit.log" /grant IIS_IUSRS:F

            if (Test-Path "C:\Program Files\ModSecurity IIS\coreruleset") {
                Remove-Item -Path "C:\Program Files\ModSecurity IIS\coreruleset" -Recurse -Force
            }

            if (Test-Path "$tempInstallerPath\coreruleset") {
                Remove-Item -Path "$tempInstallerPath\coreruleset" -Recurse -Force
            }
    
            Write-Host "Downloading OWASP Core Rule Set (CRS)..."
            Invoke-WebRequest -Uri "https://github.com/coreruleset/coreruleset/releases/download/v4.14.0/coreruleset-4.14.0-minimal.zip" -OutFile "$tempInstallerPath\coreruleset-4.14.0-minimal.zip"
            Expand-Archive -Path "$tempInstallerPath\coreruleset-4.14.0-minimal.zip" -DestinationPath "$tempInstallerPath\coreruleset" -Force

            $tmpCoreRuleSetPath = "$tempInstallerPath\coreruleset\coreruleset-4.14.0"

            Copy-Item -Path "$tmpCoreRuleSetPath\crs-setup.conf.example" -Destination "$tmpCoreRuleSetPath\crs-setup.conf"

            Write-CrsRecommendedConfig -FilePath "$tmpCoreRuleSetPath\crs-setup.conf"
            Write-CrsRequest900ExclusionRules -FilePath "$tmpCoreRuleSetPath\rules\REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf"
            Write-CrsResponse999ExclusionRules -FilePath "$tmpCoreRuleSetPath\rules\RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf"
    
            # if (!(Test-Path "C:\Program Files\ModSecurity IIS\coreruleset")) {
            #     New-Item -Path "C:\Program Files\ModSecurity IIS\coreruleset"
            # }

            Copy-Item -Path "$tmpCoreRuleSetPath" -Destination "C:\Program Files\ModSecurity IIS\coreruleset" -Recurse -Force

            Write-Host "$tmpCoreRuleSetPath to C:\Program Files\ModSecurity IIS\coreruleset"

            Copy-Item -Path $modSecConfPath -Destination "$modSecConfPath.backup"
            Set-Content -Path $modSecConfPath -Value @"
SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess Off
SecAuditEngine RelevantOnly
SecAuditLogParts ABIJDEFHZ
SecAuditLogType Serial
SecAuditLog C:\inetpub\logs\modsec\modsec_audit.log
"@
            Write-Host "modsecurity.conf updated."

            Set-Content -Path "C:\Program Files\ModSecurity IIS\modsecurity_iis.conf" `
                -Value @"
Include modsecurity.conf
Include coreruleset/crs-setup.conf
Include coreruleset/rules/*.conf

SecDefaultAction "phase:1,pass,nolog,auditlog"
SecDefaultAction "phase:2,pass,nolog,auditlog"

SecRuleUpdateActionById 959100 "t:none,deny"
SecRuleUpdateActionById 949110 "t:none,deny"

SecRuleEngine Off

SecAuditEngine Off
SecAuditLogRelevantStatus "^(4|5)\d{2}$"
SecAuditLogParts ABIF
SecDebugLogLevel 0
"@
        }
    }

    Write-Host "Cleaning up..."
    Remove-Item -Path $tempInstallerPath -Recurse -Force
}