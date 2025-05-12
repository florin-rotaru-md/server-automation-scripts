function Deploy-DotNetWebsite {
    param(
        [string]$RepoUrl = "https://github.com/your-org/your-repo.git",
        [string]$RepoBranch = "main",
        [string]$RepoToken = "ghp_***",
        [string]$ProjectPath = "App/App.csproj",
        [string]$WebSiteName = "demo.com"
    )

    $ErrorActionPreference = "Stop"

    . ".\Confirm-Paths.ps1"
    . ".\Confirm-WebSite.ps1"
    . ".\Get-Repo.ps1"
    . ".\Remove-DirectoryContents.ps1"
    . ".\Remove-ReferencePathAndOlderDirectories.ps1"
    . ".\Switch-ToInactiveWebsiteSlot.ps1"

    if (-not (Get-Module -Name WebAdministration)) {
        Import-Module WebAdministration -ErrorAction Stop
    }

    $config = Get-Content ".\Config.json" | ConvertFrom-Json

    $deployHash = [guid]::NewGuid().ToString().Split('-')[0]
    $repoName = ($RepoUrl -replace "\.git$", "").Split("/")[-1]

    $buildRoot = "C:\repos\$repoName"
    $buildSourcePath = "$buildRoot\git\$RepoBranch"
    $buildPublishPath = "$buildRoot\publish\$RepoBranch\$WebSiteName\$deployHash"

    $WebSiteNamesRootPath = "C:\inetpub\sites\$WebSiteName"
    $blueWebSitePath = "$WebSiteNamesRootPath\blue\$deployHash"
    $greenWebSitePath = "$WebSiteNamesRootPath\green\$deployHash"

    Write-Host "Confirm - repo: $repoName, branch: $RepoBranch - build paths" -ForegroundColor Green
    Confirm-Paths -Paths @($buildSourcePath, $buildPublishPath)

    Write-Host "Get - repo: $repoName, branch: $RepoBranch - $RepoUrl" -ForegroundColor Green
    Get-Repo -RepoUrl $RepoUrl `
        -RepoBranch $RepoBranch `
        -RepoToken $RepoToken `
        -DestinationPath $buildSourcePath

    Write-Host "Publish - repo: $repoName, branch: $RepoBranch - $ProjectPath" -ForegroundColor Green
    $csprojPath = Join-Path $buildSourcePath $ProjectPath
    Write-Host "dotnet publish $csprojPath -c Release -r win-x64 -o $buildPublishPath /p:PublishReadyToRun=true"
    dotnet publish $csprojPath -c Release -r win-x64 -o $buildPublishPath /p:PublishReadyToRun=true

    Write-Host "Confirm - ${WebSiteName}_green - WebSite"
    Confirm-WebSite -SiteName "${WebSiteName}_green" `
        -Port $config.green.port `
        -HostHeader $WebSiteName `
        -PhysicalPath $greenWebSitePath 
    
    Write-Host "Confirm - ${WebSiteName}_blue - WebSite"
    Confirm-WebSite -SiteName "${WebSiteName}_blue" `
        -Port $config.blue.port `
        -HostHeader $WebSiteName `
        -PhysicalPath $blueWebSitePath 

    $tempCompressedFiles = "C:\inetpub\temp\IIS Temporary Compressed Files"

    Confirm-Paths -Paths @("$tempCompressedFiles\${WebSiteName}_green", "$tempCompressedFiles\${WebSiteName}_blue")
    icacls "$tempCompressedFiles" /grant IIS_IUSRS:F

    $slotInfo = Switch-ToInactiveWebsiteSlot `
        -WebSiteName $WebSiteName `
        -BlueWebSitePath $blueWebSitePath `
        -GreenWebSitePath $greenWebSitePath `
        -BuildPublishPath $buildPublishPath 

    Write-Host "Remove - current and older published versions $buildPublishPath" -ForegroundColor Green
    Remove-ReferencePathAndOlderDirectories -Path (Get-Item $buildPublishPath).Parent.FullName -ReferencePath $buildPublishPath

    Write-Host "Remove - non active WebSite versions of $($slotInfo.InactiveWebSiteName)" -ForegroundColor Green
    Remove-DirectoryContents -Directory (Get-Item $slotInfo.InactiveWebSitePath).Parent.FullName -ExcludeNames @((Get-Item $slotInfo.InactiveWebSitePath).Name)
}
