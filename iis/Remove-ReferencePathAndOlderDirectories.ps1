function Remove-ReferencePathAndOlderDirectories {
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