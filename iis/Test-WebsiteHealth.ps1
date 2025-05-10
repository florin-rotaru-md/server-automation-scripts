function Test-WebsiteHealth {
    <#
        .SYNOPSIS
        Polls a URL until it returns HTTP 200 or a maximum number of attempts is reached.
        .PARAMETER Url
            Absolute or relative URL to check (e.g. http://localhost:8081/.well-known/live).
        .PARAMETER Headers
            Optional HTTP headers to include in the request.
        .PARAMETER Attempts
            How many times to try (default = 33).
        .PARAMETER TimeoutSec
            Per-request timeout in seconds (default = 1).
        .PARAMETER PauseSec
            Delay between attempts in seconds (default = 3).
        .OUTPUTS
            Returns $true on success; throws on failure (so you can catch or let it abort the script).
    #>
    param (
        [Parameter(Mandatory)][string]$Url,
        [hashtable]$Headers = @{},
        [int]$Attempts   = 33,
        [int]$TimeoutSec = 1,
        [int]$PauseSec   = 3
    )

    Write-Host "Health check: $Url  (Attempts: $Attempts, Timeout/try: ${TimeoutSec}s)" -ForegroundColor Cyan
    Write-Host "Header: $($Headers | ConvertTo-Json -Depth 3)"

    for ($i = 1; $i -le $Attempts; $i++) {
        try {
            # If Headers is empty, Invoke-WebRequest will be called without it
            $response = if ($Headers.Count -gt 0) {
                Invoke-WebRequest -Uri $Url -Headers $Headers -TimeoutSec $TimeoutSec -UseBasicParsing
            } else {
                Invoke-WebRequest -Uri $Url -TimeoutSec $TimeoutSec -UseBasicParsing
            }

            if ($response.StatusCode -eq 200) {
                Write-Host "200 OK on attempt ${i}" -ForegroundColor Green
                return $true
            } else {
                Write-Host "Attempt ${i} -> HTTP $($response.StatusCode) - retrying" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Attempt ${i} -> no response - retrying" -ForegroundColor DarkYellow
        }
        Start-Sleep -Seconds $PauseSec
    }

    throw "Health check FAILED after $Attempts attempts at $Url."
}