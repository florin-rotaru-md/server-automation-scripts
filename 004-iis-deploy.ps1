param(
    [string]$repoUrl,
    [string]$repoBranch,
    [string]$repoToken,
    [string]$repoLocalRootPath,
    [string]$projectPath,
    [string]$blueRootPath,
    [string]$greenRootPath,
    [string]$siteName,
    [string]$httpBinding
)

$ErrorActionPreference = "Stop"
if (-not (Get-Module -Name WebAdministration)) {
    Import-Module WebAdministration -ErrorAction Stop
}

function Kill-LockedProcess {
    param([string]$path)
	
	$ErrorActionPreference = "Stop"
    $handlePath = "C:\Program Files\Handle\handle.exe"
    if (-Not (Test-Path $handlePath)) {
        Write-Warning "handle.exe not found at $handlePath. Skipping lock cleanup."
        return
    }
    $output = & $handlePath -accepteula $path 2>$null
    $processIds = $output | Select-String -Pattern "processId: (\d+)" | ForEach-Object { $_.Matches[0].Groups[1].Value } | Sort-Object -Unique
    foreach ($processId in $processIds) {
        try {
            Write-Host "Killing process with PID $processId..."
            Stop-Process -Id $processId -Force
        } catch {
            Write-Warning "Failed to kill process ${processId}: $_"
        }
    }
}

function Cleanup-Folders {
    param ([string[]]$folders)
	
	$ErrorActionPreference = "Stop"
    foreach ($folder in $folders) {
        if (Test-Path $folder) {
            try {
                Kill-LockedProcess -path $folder
                Remove-Item -Recurse -Force $folder
                Write-Host "Deleted folder: $folder"
            } catch {
                Write-Warning "Could not delete folder ${folder}: $_"
            }
        }
    }
}

try {
    $greenPath = Join-Path $greenRootPath $siteName
    if (-Not (Test-Path $greenPath)) {
        New-Item -ItemType Directory -Path $greenPath | Out-Null
        Write-Host "Created site root path: $greenPath"
    }

    if (-Not (Get-Website -Name $siteName -ErrorAction SilentlyContinue)) {
        Write-Host "Creating IIS site and app pool..."

        if (Test-Path "IIS:\AppPools\$siteName") {
			Write-Host "App pool '$siteName' already exists. Removing it..."
			Remove-WebAppPool -Name $siteName -ErrorAction SilentlyContinue
		}

        New-WebAppPool -Name $siteName
		Set-ItemProperty "IIS:\AppPools\$siteName" -Name "managedRuntimeVersion" -Value ""
		Set-ItemProperty "IIS:\AppPools\$siteName" -Name "processModel.loadUserProfile" -Value $true
		
        New-Website -Name $siteName -Port 80 -IPAddress "*" -HostHeader $httpBinding -PhysicalPath $greenPath -ApplicationPool $siteName
    }

    $guid = [guid]::NewGuid().ToString()
    $localRepoPath = Join-Path $repoLocalRootPath "$siteName-$guid"
    $blueDeployPath = Join-Path $blueRootPath "$siteName-$guid"
    New-Item -ItemType Directory -Path $localRepoPath | Out-Null
    New-Item -ItemType Directory -Path $blueDeployPath | Out-Null

    $secureRepoUrl = $repoUrl -replace "https://", "https://$repoToken@"
    $gitCloneProcess = Start-Process -FilePath "git" -ArgumentList "clone", "--branch", $repoBranch, $secureRepoUrl, $localRepoPath -NoNewWindow -Wait -PassThru

    if ($gitCloneProcess.ExitCode -ne 0) {
		Cleanup-Folders -folders @($localRepoPath, $blueDeployPath)
        throw "Git clone failed with exit code $($gitCloneProcess.ExitCode)"
    }

    $csprojPath = Join-Path $localRepoPath $projectPath
    $publishProcess = Start-Process -FilePath "dotnet" -ArgumentList "publish", $csprojPath, "-c", "Release", "-o", $blueDeployPath -NoNewWindow -Wait -PassThru

    if ($publishProcess.ExitCode -ne 0) {
		Cleanup-Folders -folders @($localRepoPath, $blueDeployPath)
        throw "dotnet publish failed with exit code $($publishProcess.ExitCode)"
    }

	Set-ItemProperty "IIS:\\Sites\\$siteName" -Name physicalPath -Value $blueDeployPath
	Restart-WebAppPool -Name $siteName

	try {
		Kill-LockedProcess -path $greenPath
		Remove-Item "$greenPath\*" -Recurse -Force
		Copy-Item -Path "$blueDeployPath\*" -Destination $greenPath -Recurse -Force
		Set-ItemProperty "IIS:\\Sites\\$siteName" -Name physicalPath -Value $greenPath
		
		Set-ItemProperty "IIS:\AppPools\$siteName" -Name "managedRuntimeVersion" -Value ""
		Set-ItemProperty "IIS:\AppPools\$siteName" -Name "processModel.loadUserProfile" -Value $true
		Restart-WebAppPool -Name $siteName
	} catch {
		Write-Warning "Could not cleanup folder ${greenPath}: $_"
	}

    Cleanup-Folders -folders @($localRepoPath, $blueDeployPath)

    Write-Host "Deployment completed successfully."
} catch {
    Write-Error "Deployment failed: $_"
    Cleanup-Folders -folders @($localRepoPath, $blueDeployPath)
    exit 1
}
