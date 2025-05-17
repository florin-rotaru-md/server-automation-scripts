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
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$Url,
        [hashtable]$Headers = @{},
        [int]$Attempts   = 33,
        [int]$TimeoutSec = 1,
        [int]$PauseSec   = 3
    )

    $ProgressPreference = 'SilentlyContinue'

    Write-Host "Health check: $Url  (Timeout / Attempt: ${TimeoutSec}s)" -ForegroundColor Cyan
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
                Write-Host "Health check OK" -ForegroundColor Green
                return
            } else {
                Write-Host "Attempt $($i.ToString("000")) / ${Attempts} -> HTTP $($response.StatusCode) - retrying" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "Attempt $($i.ToString("000")) / ${Attempts} -> no response - retrying" -ForegroundColor DarkYellow
        }
        Start-Sleep -Seconds $PauseSec
    }

    throw "Health check FAILED after $Attempts attempts at $Url."
}