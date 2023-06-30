$server = "MAGDEEIPAEB01"
$ports = @(23080, 23009, 23000, 23443, 23787, 31000, 32000, 23099) #Ports Lists


foreach ($port in $ports) {
    $result = Test-NetConnection -ComputerName $server -Port $port -WarningAction SilentlyContinue

    if ($result.TcpTestSucceeded) {
        Write-Host "Connection to $server on port $port succeeded."
    } else {
        Write-Host "Connection to $server on port $port failed."
    }
}