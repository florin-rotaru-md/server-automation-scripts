function Get-Repo {
    <#
        .SYNOPSIS
            Clone or update a Git repository.
        .DESCRIPTION
            This function checks if a specified Git repository exists at the destination path. If it does not exist, it clones the repository. If it does exist, it fetches and resets the local copy to match the remote branch.
        .PARAMETER repoUrl
            The URL of the Git repository to clone or update.
        .PARAMETER repoBranch
            The branch of the repository to clone or update.
        .PARAMETER destinationPath
            The local path where the repository should be cloned or updated.
        .EXAMPLE
            Get-Repo -repoUrl "
    #>
    [CmdletBinding()]
    param (
        [string]$RepoUrl,
        [string]$RepoBranch,
        [string]$DestinationPath
    )
    
    if (!((Get-ChildItem -Path $DestinationPath).Count -gt 0)) {
        $secureRepoUrl = $RepoUrl -replace "https://", "https://$repoToken@"
        Write-Host "git clone --branch $RepoBranch $DestinationPath"
        git clone --branch $RepoBranch $secureRepoUrl $DestinationPath
    }
    else {
        $initialLocation = Get-Location
        Set-Location $DestinationPath
        
        Write-Host "git reset --hard origin/$RepoBranch $DestinationPath"
        git fetch origin
        git reset --hard origin/$RepoBranch
        
        Set-Location $initialLocation
    }
}