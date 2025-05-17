function Remove-DirectoryContents {
    <#
        .SYNOPSIS
            Remove all contents of a directory, excluding specified names.
        .DESCRIPTION
            This function removes all files and subdirectories from a specified directory, except for those that match the names in the ExcludeNames array.
        .PARAMETER Directory
            The path to the directory whose contents should be removed.
        .PARAMETER ExcludeNames
            An array of names to exclude from deletion.
        .EXAMPLE
            Remove-DirectoryContents -Directory "C:\MyFolder" -ExcludeNames @("keep.txt", "important")
    #>
    [CmdletBinding()]
    param (
        [string]$Directory,
        [string[]]$ExcludeNames )

    if (-not (Test-Path -Path $Directory)) {
        return
    }

    Write-Host "Removing contents of $Directory, excluding $($ExcludeNames -join ', ')"

    Get-ChildItem $Directory | Where-Object { $_.Name -notin $ExcludeNames } | ForEach-Object {
        $item = $_.FullName

        Write-Host "Removing ${item}"
        if ($_.PSIsContainer) {
            Remove-Item -Path $_.FullName -Recurse -Force
        }
        else {
            Remove-Item -Path $_.FullName -Force
        }
    }
}