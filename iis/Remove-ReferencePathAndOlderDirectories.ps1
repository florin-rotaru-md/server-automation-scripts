function Remove-ReferencePathAndOlderDirectories {
    <#
        .SYNOPSIS
        Removes a reference path and all directories older than the reference path.
        .DESCRIPTION
        This function deletes a specified reference path and all directories within a specified path that are older than the reference path.
        .PARAMETER Path
        The path to check for directories to remove.
        .PARAMETER ReferencePath
        The reference path whose creation date is used to determine which directories to remove.
        .EXAMPLE
        Remove-ReferencePathAndOlderDirectories -Path "C:\MyDirectories" -ReferencePath "C:\MyDirectories\Reference"
        This command removes the reference path and all directories in "C:\MyDirectories" that are older than the reference path.
    #>
    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$ReferencePath
    )

    # Ensure the reference path exists
    if (-not (Test-Path -Path $ReferencePath -PathType Container)) {
        throw "ReferencePath '$ReferencePath' does not exist or is not a directory."
    }

    # Get creation date of reference path
    $referenceDate = (Get-Item $ReferencePath).CreationTime

    # Get all directories in Path
    $directories = Get-ChildItem -Path $Path -Directory

    foreach ($dir in $directories) {
        # Skip the reference path itself
        if ($dir.FullName -eq $ReferencePath) { continue }

        # Check if directory is older than reference date
        if ($dir.CreationTime -lt $referenceDate) {
            Write-Host "Removing directory: $($dir.FullName)"
            Remove-Item -Path $dir.FullName -Recurse -Force
        }
    }

    # Finally, delete the reference path itself
    Write-Host "Removing reference path: $ReferencePath"
    Remove-Item -Path $ReferencePath -Recurse -Force
}