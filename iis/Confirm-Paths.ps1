function Confirm-Paths {
    <#
        .SYNOPSIS
            Ensure that the specified paths exist, creating them if necessary.
        .DESCRIPTION
            This function checks if the specified paths exist. If a path does not exist, it creates the directory.
        .PARAMETER Paths
            An array of paths to check and create if they do not exist.
        .EXAMPLE
            Confirm-Paths -Paths "C:\MyFolder", "D:\AnotherFolder"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string[]]$Paths
    )

    foreach ($path in $Paths) {
        Write-Host "Confirm path $path"
        if (-not (Test-Path -Path $path)) {
            New-Item -Path $path -ItemType Directory -Force | Out-Null
        } 
    }
}