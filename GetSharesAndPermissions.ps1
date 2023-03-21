# PowerShell script to list shares and permissions

# Load the required module
if (-not (Get-Module -Name "SmbShare")) {
    Import-Module SmbShare
}

# Function to retrieve share permissions
function Get-SharePermissions {
    param (
        [Parameter(Mandatory = $true)][string]$ShareName
    )

    $share = Get-SmbShare -Name $ShareName
    $shareSecurity = $share | Get-SmbShareAccess

    $permissions = @()

    foreach ($entry in $shareSecurity) {
        $user = $entry.AccountName
        $accessRights = $entry.AccessRight

        $permissions += New-Object PSObject -Property @{
            Username = $user
            Permissions = $accessRights
        }
    }

    return $permissions
}

# Retrieve the list of shares
$shares = Get-SmbShare | Where-Object { $_.Name -ne "IPC$" }

# Get the server name
$serverName = (Get-WmiObject -Class Win32_ComputerSystem).Name

# Create CSV file to store the output
$outputFile = "$serverName-SharesAndPermissions.csv"

# Header for the CSV file
"ShareName,Path,Username,Permissions" | Set-Content $outputFile

# Output shares and permissions and write them to the CSV file
foreach ($share in $shares) {
    $permissions = Get-SharePermissions -ShareName $share.Name
    foreach ($permission in $permissions) {
        $csvLine = "$($share.Name),$($share.Path),$($permission.Username),$($permission.Permissions)"
        Add-Content -Path $outputFile -Value $csvLine
    }
}

Write-Host "Shares and permissions have been exported to the file '$outputFile'."
