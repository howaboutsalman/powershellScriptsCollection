function GetHostInfo {
    if (-not $hostname) {
        $hostname = $env:COMPUTERNAME
    }
    $SavePath = "$env:HOMEDRIVE\$env:HOMEPATH\Desktop"
    $dataPath = "$SavePath\$hostname"
    $psversion = $PSVersionTable.PSVersion.Major
    if ($psversion -ge 5) {
        # Use the CIM cmdlet (available in PowerShell version 3.0 and later)
        $osInfo = (Get-CimInstance -ClassName Win32_OperatingSystem).ProductType
    } else {
        # Use alternative method to get OS version, like WMI
        $osInfo = (Get-WmiObject -Class Win32_OperatingSystem).ProductType
    }
    try {
        Get-Item  $dataPath -ErrorAction Stop
    }
    catch {
        New-Item $dataPath -ItemType directory
    }

    $osInfo
    if ($osInfo -eq 2 -or $osInfo -eq 3) {
        try {
            Import-Module ServerManager
            Get-WindowsFeature | Select-Object -Property Name, Installed | Where-Object { $_.Installed -eq $true } | Export-Csv -Path "$dataPath\features.csv"
        } catch {
            Write-Error "An error occurred while importing the ServerManager module or getting the windows features: $_"
        }
    } else {
        Write-Warning "This is not a Server operating system, ServerManager module and windows feature collection will not be available"
    }
    $osInfo
    Get-Process | Select-Object -Property Name, ProcessId | Export-Csv -Path "$dataPath\processes.csv"
    #get all Services
    get-service | Select-Object -Property Name, DisplayName, Status | Where-Object { $_.Status -eq "Running" } | Export-Csv -Path "$dataPath\services.csv"
    #get all of the installed Programms 
    Get-WmiObject -Class Win32_Product | select Name, Version  | Export-Csv -Path "$dataPath\Applications.csv"
    #get all of the installed Datenbanks 
    Get-WmiObject win32_service | ?{$_.Name -like '*sql*'} | select Name, DisplayName, @{Name="Path"; Expression={$_.PathName.split('"')[1]}} | Format-List
    systeminfo | Out-File -FilePath "$dataPath\datenbank.csv"
    w32tm /query /source | Out-File -FilePath "$dataPath\datenbank.csv"
    #win Updates
    reg query HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate | Out-File -FilePath "$dataPath\Windowsupdate.txt"
    $ScheduledTask = Get-ScheduledTask | Where-Object {($_.Taskpath -NotLike "*\Microsoft*") -and ($_.Taskname -NotMatch 'Run*|User*|Google*|Microsoft*|Opera*')} | ForEach { Export-ScheduledTask -TaskName $_.TaskName -TaskPath $_.TaskPath | Out-File (Join-Path "C:\_Tools\" "$($_.TaskName).xml") }
}

$currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
if (!$currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    # Get the path of the current script
    $scriptPath = $MyInvocation.MyCommand.Definition
    # Restart the script with admin rights
    Start-Process powershell.exe -Verb runAs -ArgumentList ("-File `"$scriptPath`"")
    exit
}

# rest of the script will run here only if user has admin rights. 
GetHostInfo