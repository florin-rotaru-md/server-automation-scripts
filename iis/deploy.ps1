param(
    [string]$repoUrl = "https://github.com/your-org/your-repo.git",
    [string]$repoBranch = "main",
    [string]$repoToken = "ghp_***",
    [string]$projectPath = "App/App.csproj",
    [string]$site = "demo.com"
)

. ".\Confirm-Paths.ps1"
. ".\Confirm-WebSite.ps1"
. ".\Get-Repo.ps1"
. ".\Remove-DirectoryContents.ps1"
. ".\Remove-ReferencePathAndOlderDirectories.ps1"

$ErrorActionPreference = "Stop"
if (-not (Get-Module -Name WebAdministration)) {
    Import-Module WebAdministration -ErrorAction Stop
}


$deployHash = [guid]::NewGuid().ToString().Split('-')[0]

# Remove ".git" extension and split by "/" then take the last segment
$repoName = ($repoUrl -replace "\.git$", "").Split("/")[-1]

$buildRoot = "C:\repos\$repoName"
$buildSourcePath = "$buildRoot\git\$repoBranch"
$buildPublishPath = "$buildRoot\publish\$repoBranch\$site\$deployHash"

$webSitesRootPath = "C:\inetpub\sites\$site"
$blueWebSitePath = "$webSitesRootPath\blue\$deployHash"
$greenWebSitePath = "$webSitesRootPath\green\$deployHash"


Write-Host "Confirm - repo: $repoName, branch: $repoBranch - build paths" -ForegroundColor Green
Confirm-Paths -Paths @($buildSourcePath, $buildPublishPath)

Write-Host "Get - repo: $repoName, branch: $repoBranch - $repoUrl" -ForegroundColor Green
Get-Repo -RepoUrl $repoUrl `
    -RepoBranch $repoBranch `
    -RepoToken $repoToken `
    -DestinationPath $buildSourcePath

Write-Host "Publish - repo: $repoName, branch: $repoBranch - $projectPath" -ForegroundColor Green
$csprojPath = Join-Path $buildSourcePath $projectPath
Write-Host "dotnet publish $csprojPath -c Release -r win-x64 -o $buildPublishPath /p:PublishReadyToRun=true"
dotnet publish $csprojPath -c Release -r win-x64 -o $buildPublishPath /p:PublishReadyToRun=true


$greenWebSiteName = "${site}_green"
$greenWebSitePort = 8081

$blueWebSiteName = "${site}_blue"
$blueWebSitePort = 8082

Write-Host "Confirm - $greenWebSiteName - WebSite"
Confirm-WebSite -SiteName $greenWebSiteName `
    -Port $greenWebSitePort `
    -HostHeader $site `
    -PhysicalPath $greenWebSitePath 
	
Write-Host "Confirm - $blueWebSiteName - WebSite"
Confirm-WebSite -SiteName $blueWebSiteName `
    -Port $blueWebSitePort `
    -HostHeader $site `
    -PhysicalPath $blueWebSitePath 
	

Write-Host "Determine active / inactive WebSite"
$bindingInfo = @(Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:80:$site" })
if ($bindingInfo.Count -eq 0) {
    $bindingInfo = @(Get-WebBinding | Where-Object { $_.bindingInformation -eq "*:${blueWebSitePort}:$site" })
}

# $bindingInfo[0].PSObject.Properties | ForEach-Object { Write-Host "$($_.Name): $($_.Value)" }

$activeWebSiteName = $bindingInfo[0].ItemXPath -replace ".*name='([^']+)'.*", '$1'

$inactiveWebSiteName = $null
$inactiveWebSitePath = ""

if ($activeWebSiteName -eq $blueWebSiteName) { 
    $inactiveWebSiteName = $greenWebSiteName 
    $inactiveWebSitePath = $greenWebSitePath

    Confirm-Paths -Paths $greenWebSitePath
}
else { 
    $inactiveWebSiteName = $blueWebSiteName 
    $inactiveWebSitePath = $blueWebSitePath

    Confirm-Paths -Paths $blueWebSitePath
}

Write-Host "Active Site: $activeWebSiteName, deploying to inactive site: $inactiveWebSiteName at $inactiveWebSitePath" -ForegroundColor Green

$state = Get-WebAppPoolState -Name $inactiveWebSiteName
if ($state.Value -ne "Stopped") {
    Stop-WebAppPool -Name $inactiveWebSiteName
    do {
        $state = Get-WebAppPoolState -Name $inactiveWebSiteName
        Start-Sleep -Milliseconds 330
    } while ($state.Value -ne "Stopped")
}


Copy-Item "$buildPublishPath\*" "$inactiveWebSitePath" -Recurse
Set-ItemProperty "IIS:\\Sites\\$inactiveWebSiteName" -Name physicalPath -Value $inactiveWebSitePath
Start-WebAppPool -Name $inactiveWebSiteName

Write-Host "Remove - current and older published versions $buildPublishPath" -ForegroundColor Green
Remove-ReferencePathAndOlderDirectories -Path (Get-Item $buildPublishPath).Parent.FullName -ReferencePath $buildPublishPath

Write-Host "Remove - non active WebSite versions of $inactiveWebSiteName" -ForegroundColor Green
Remove-DirectoryContents -Directory (Get-Item $inactiveWebSitePath).Parent.FullName -ExcludeNames @((Get-Item $inactiveWebSitePath).Name)



# $headers = @{"Host" = "api.waa.ro:8082"}
# Invoke-WebRequest -Uri "http://localhost:8082" -Headers $headers

# Health check before going live
$inactiveWebSitePort = if ($inactiveWebSiteName -eq $blueWebSiteName) { $blueWebSitePort } else { $greenWebSitePort }
try {
	$headers = @{"Host" = "${site}:$inactiveWebSitePort"}
	$healthUrl = "http://localhost:$inactiveWebSitePort/.well-know/live"
	Write-Host "Host = ${site}:$inactiveWebSitePort, http://localhost:$inactiveWebSitePort/.well-know/live"
	
    Write-Host "Health check on $inactiveWebSiteName" -ForegroundColor Green
    $healthResponse = Invoke-WebRequest -Uri $healthUrl -Headers $headers -TimeoutSec 60
    Write-Host "Health check response: $($healthResponse.StatusCode)" -ForegroundColor Green
    if ($healthResponse.StatusCode -ne 200) {
        throw "Health check failed with status code $($healthResponse.StatusCode)"
    }
    Write-Host "Health check passed for $inactiveWebSiteName"
}
catch {
    Write-Error "Health check failed on $inactiveWebSiteName. Deployment aborted."
    exit 1
}

# # Swap binding (activate new, backup old)
# Write-Host "🔁 Swapping production binding to $inactiveSite"
# try {
# # Remove prod binding from active
# Remove-WebBinding -Name $activeSite -BindingInformation $prodBinding -Protocol http
# # Add prod binding to inactive
# New-WebBinding -Name $inactiveSite -Protocol http -Port 80 -IPAddress "*" -HostHeader ""

# # Optional post-deployment health check (sanity)
# $finalCheck = Invoke-WebRequest -Uri "http://localhost$healthCheckPath" -UseBasicParsing -TimeoutSec 10
# if ($finalCheck.StatusCode -ne 200) {
# throw "Final health check failed after go-live."
# }

# Write-Host "🎉 Deployment successful! Live site is now $inactiveSite"
# }
# catch {
# Write-Error "⚠️ Error after binding swap: $_. Rolling back to $activeSite"

# # Restore binding to previous active site
# Remove-WebBinding -Name $inactiveSite -BindingInformation $prodBinding -Protocol http -ErrorAction SilentlyContinue
# New-WebBinding -Name $activeSite -Protocol http -Port 80 -IPAddress "*" -HostHeader ""

# Write-Host "🔁 Rollback completed. $activeSite is live again."
# }