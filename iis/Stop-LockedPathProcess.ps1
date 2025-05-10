function Stop-LockedPathProcess {
    param([string]$path)
    <#
        .SYNOPSIS
            Stop processes that are locking a specified file or directory.
        .DESCRIPTION
            Uses Handle.exe to find and terminate processes locking a given file or directory.
        .PARAMETER path
            The path to the file or directory whose locking processes should be stopped.
        .EXAMPLE
            Stop-LockedPathProcess -path "C:\MyFolder\lockedfile.txt"
    #>

    $handlePath = "C:\Program Files\Handle\handle.exe"

    # Execute Handle.exe once to retrieve all locking processes
    $output = & $handlePath -accepteula $path 2>$null

    # Extract process IDs using optimized regex matching
    $processIds = $output | Select-String -Pattern "processId: (\d+)" | ForEach-Object { $_.Matches.Groups[1].Value } | Sort-Object -Unique

    if ($processIds.Count -gt 0) {
        Write-Host "Found $($processIds.Count) locking process(es) for $path"

        # Kill processes in parallel for better performance
        $processIds | ForEach-Object -Parallel {
            Write-Host "Terminating PID $_..."
            Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "No locking processes found for $path"
    }
}