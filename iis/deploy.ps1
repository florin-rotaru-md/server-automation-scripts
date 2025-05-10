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
. ".\Switch-ToInactiveWebsiteSlot.ps1"

$ErrorActionPreference = "Stop"
if (-not (Get-Module -Name WebAdministration)) {
    Import-Module WebAdministration -ErrorAction Stop
}

$config = Get-Content ".\Config.json" | ConvertFrom-Json
# Write-Host "Config: $($config | ConvertTo-Json -Depth 7)" -ForegroundColor Green

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

Write-Host "Confirm - ${site}_green - WebSite"
Confirm-WebSite -SiteName "${site}_green" `
    -Port $config.green.port `
    -HostHeader $site `
    -PhysicalPath $greenWebSitePath 
	
Write-Host "Confirm - ${site}_blue - WebSite"
Confirm-WebSite -SiteName "${site}_blue" `
    -Port $config.blue.port `
    -HostHeader $site `
    -PhysicalPath $blueWebSitePath 
	
$slotInfo = Switch-ToInactiveWebsiteSlot `
    -SiteName $site `
    -BlueWebSitePath $blueWebSitePath `
    -GreenWebSitePath $greenWebSitePath `
    -BuildPublishPath $buildPublishPath 
    # -ConfirmPathsCallback { param($path) Confirm-Paths -Paths $path }

# Write-Host "slotInfo: $($slotInfo | ConvertTo-Json -Depth 7)" -ForegroundColor Green

Write-Host "Remove - current and older published versions $buildPublishPath" -ForegroundColor Green
Remove-ReferencePathAndOlderDirectories -Path (Get-Item $buildPublishPath).Parent.FullName -ReferencePath $buildPublishPath

Write-Host "Remove - non active WebSite versions of $($slotInfo.InactiveWebSiteName)" -ForegroundColor Green
Remove-DirectoryContents -Directory (Get-Item $slotInfo.InactiveWebSitePath).Parent.FullName -ExcludeNames @((Get-Item $slotInfo.InactiveWebSitePath).Name)
