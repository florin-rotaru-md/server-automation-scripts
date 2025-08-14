function Deploy-DotNetWebsite {
    <#
        .SYNOPSIS
            Deploys a .NET website to IIS.
        .DESCRIPTION
            This script deploys a .NET website to IIS by cloning the repository, building the project, and publishing it to the specified path.
        .PARAMETER RepoUrl
            The URL of the Git repository.
        .PARAMETER RepoBranch
            The branch of the repository to clone.
        .PARAMETER RepoToken
            The GitHub token for authentication.
        .PARAMETER ProjectPath
            The path to the .NET project file.
        .PARAMETER HostName
            The host name used in bindings (e.g., yoursite.com).
        .PARAMETER GreenHttpPort
            The HTTP port for the green slot site.
        .PARAMETER BlueHttpPort
            The HTTP port for the blue slot site.
        .PARAMETER WacsValidationMethod
            The validation method for Let's Encrypt certificate (e.g., http-01, cloudflare-dns).
        .PARAMETER WacsArgsCloudflarecredentials
            The Cloudflare credentials file path for DNS validation (if applicable).
        .PARAMETER WacsArgsEmailAddress
            The email address for Let's Encrypt notifications.
    #>
    [CmdletBinding()]
    param(
        [string]$RepoUrl = "https://github.com/your-org/your-repo.git",
        [string]$RepoBranch = "main",
        [string]$RepoToken = "ghp_***",
        [string]$ProjectPath = "App/App.csproj",
        [string]$HostName = "demo.com",
        [int]$GreenHttpPort = 8001,
		[int]$BlueHttpPort = 8002,
        [string]$CCSConfigFile = "C:\config\ccs.json",
        [string]$WacsValidationMethod = "cloudflare-dns",
        [string]$WacsArgsCloudflareTokenPath = "C:\config\tokens\clooudflare-zone-dns-demo.com.txt",
        [string]$WacsArgsEmailAddress = "rotaru.i.florin@outlook.com"
    )
    
    $ErrorActionPreference = "Stop"

    if ($GreenHttpPort -eq $BlueHttpPort) {
        throw "GreenHttpPort and BlueHttpPort must be different."
    }

    . "$PSScriptRoot\Confirm-Paths.ps1"
    . "$PSScriptRoot\Get-Repo.ps1"
    . "$PSScriptRoot\Remove-ReferencePathAndOlderDirectories.ps1"
    . "$PSScriptRoot\Switch-ToInactiveWebsiteSlot.ps1"

    if (-not (Get-Module -Name WebAdministration)) {
        Import-Module WebAdministration -ErrorAction Stop
    }

    $deployHash = [guid]::NewGuid().ToString().Split('-')[0]
    $repoName = ($RepoUrl -replace "\.git$", "").Split("/")[-1]

    $buildRoot = "C:\repos\$repoName"
    $buildSourcePath = "$buildRoot\git\$RepoBranch"
    $buildPublishPath = "$buildRoot\publish\$RepoBranch\$HostName\$deployHash"

    $webSitesRootPath = "C:\inetpub\webSites\$HostName"
    $blueWebSitePath = "$webSitesRootPath\blue\$deployHash"
    $greenWebSitePath = "$webSitesRootPath\green\$deployHash"

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

    Write-Host "Published to $buildPublishPath" -ForegroundColor Green

    Switch-ToInactiveWebsiteSlot `
        -HostName $HostName `
        -BlueWebSitePath $blueWebSitePath `
        -GreenWebSitePath $greenWebSitePath `
        -BuildPublishPath $buildPublishPath `
        -GreenHttpPort $GreenHttpPort `
        -BlueHttpPort $BlueHttpPort `
        -CCSConfigFile $CCSConfigFile `
        -WacsValidationMethod $WacsValidationMethod `
        -WacsArgsCloudflareTokenPath $WacsArgsCloudflareTokenPath `
        -WacsArgsEmailAddress $WacsArgsEmailAddress

    Write-Host "Remove - current and older published versions $buildPublishPath" -ForegroundColor Green
    Remove-ReferencePathAndOlderDirectories -Path (Get-Item $buildPublishPath).Parent.FullName -ReferencePath $buildPublishPath
}
