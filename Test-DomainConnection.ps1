function Test-DomainConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ClientName,
        [Parameter(Mandatory = $true)]
        [string[]]$DCs
    )

    $ports = @(53, 88, 389, 445, 464, 636, 3268, 3269)
    $failures = @()

    foreach ($DC in $DCs) {
        Write-Host "Testing connection to $DC..." -ForegroundColor Yellow
        foreach ($port in $ports) {
            $result = Test-NetConnection -ComputerName $DC -Port $port -InformationLevel Quiet
            if (!$result) {
                $failures += "$DC : $port"
            }
        }
        if ($failures.Count -eq 0) {
            Write-Host "Connection to $DC succeeded." -ForegroundColor Green
        } else {
            Write-Host "Connection to $DC failed on port(s): $($failures -join ',')." -ForegroundColor Red
            $failures.Clear()
        }
    }

    Write-Host "Testing connection from $ClientName to domain controllers..." -ForegroundColor Yellow
    foreach ($port in $ports) {
        $results = Test-NetConnection -ComputerName $DCs -Port $port -InformationLevel Quiet
        if (!$results) {
            $failures += $port
        }
    }
    if ($failures.Count -eq 0) {
        Write-Host "Connection from $ClientName to domain controllers succeeded." -ForegroundColor Green
    } else {
        Write-Host "Connection from $ClientName to domain controllers failed on port(s): $($failures -join ',')." -ForegroundColor Red
    }
}