# Author: Andre Torres (https://github.com/andretorresbr/ghadd/)

function Sync-ADObjectToGroup {
<#
    .SYNOPSIS
        Synchronizes a target Active Directory group with the users or computers from one or more specified OUs.

    .DESCRIPTION
        This function ensures that a destination group contains exactly the objects found within
        one or more source Organizational Units (OUs), including their sub-OUs.
        Objects in the group that are not in any of the source OUs are removed, and objects from the
        source OUs not in the group are added.

    .PARAMETER SourceOU
        One or more OUs to search recursively.

    .PARAMETER DestinationGroup
        Target AD group to synchronize.

    .PARAMETER ObjectType
        User or Computer.

    .PARAMETER ExcludedObject
        SamAccountName(s) to exclude.

    .PARAMETER LogFile
        Path to the transcript log file.
#>

    param (
        [Parameter(Mandatory = $true)]
        [string[]]$SourceOU,

        [Parameter(Mandatory = $true)]
        [string]$DestinationGroup,

        [Parameter(Mandatory = $true)]
        [ValidateSet("User", "Computer")]
        [string]$ObjectType,

        [string[]]$ExcludedObject = $null,

        [Parameter(Mandatory = $true)]
        [string]$LogFile
    )

    Start-Transcript -Path $LogFile -Append

    try {
        $group = Get-ADGroup -Identity $DestinationGroup -ErrorAction Stop
    }
    catch {
        Write-Error "Destination group '$DestinationGroup' not found."
        Stop-Transcript
        return
    }

    $allDesiredObjects = @()

    foreach ($ouPath in $SourceOU) {
        Write-Host "Searching '$ouPath'..."

        try {
            Get-ADOrganizationalUnit -Identity $ouPath -ErrorAction Stop | Out-Null

            if ($ObjectType -eq "Computer") {
                $objects = Get-ADComputer `
                    -SearchBase $ouPath `
                    -SearchScope Subtree `
                    -Filter * `
                    -Properties SamAccountName, DistinguishedName
            }
            else {
                $objects = Get-ADUser `
                    -SearchBase $ouPath `
                    -SearchScope Subtree `
                    -Filter * `
                    -Properties SamAccountName, DistinguishedName
            }

            $allDesiredObjects += $objects
        }
        catch {
            Write-Warning "Failed to search OU '$ouPath'. Skipping."
        }
    }

    if (-not $allDesiredObjects) {
        Write-Warning "No objects found in source OUs."
    }

    try {
        $currentMembers = Get-ADGroupMember -Identity $group.Name -Recursive |
            Where-Object { $_.objectClass -in @("user", "computer") } |
            ForEach-Object {
                Get-ADObject -Identity $_.DistinguishedName -Properties SamAccountName, DistinguishedName
            }
    }
    catch {
        Write-Warning "Unable to retrieve current group members."
        $currentMembers = @()
    }

    $desiredSamAccounts = $allDesiredObjects.SamAccountName | Where-Object { $_ -notin $ExcludedObject }
    $currentSamAccounts = $currentMembers.SamAccountName | Where-Object { $_ -notin $ExcludedObject }

    $membersToRemove = $currentSamAccounts | Where-Object { $_ -notin $desiredSamAccounts }
    $membersToAdd    = $desiredSamAccounts | Where-Object { $_ -notin $currentSamAccounts }

    if ($membersToRemove) {
        Write-Host "Removing members: $($membersToRemove -join ', ')" -ForegroundColor Red

        foreach ($member in $membersToRemove) {
            try {
                $dn = ($currentMembers | Where-Object { $_.SamAccountName -eq $member }).DistinguishedName
                Remove-ADGroupMember -Identity $group.Name -Members $dn -Confirm:$false -ErrorAction Stop
                Write-Host "Removed $member" -ForegroundColor Red
            }
            catch {
                Write-Warning "Failed to remove $member"
            }
        }
    }
    else {
        Write-Host "No members to remove." -ForegroundColor Green
    }

    if ($membersToAdd) {
        Write-Host "Adding members: $($membersToAdd -join ', ')" -ForegroundColor Green

        foreach ($member in $membersToAdd) {
            try {
                $dn = ($allDesiredObjects | Where-Object { $_.SamAccountName -eq $member }).DistinguishedName
                Add-ADGroupMember -Identity $group.Name -Members $dn -ErrorAction Stop
                Write-Host "Added $member" -ForegroundColor Green
            }
            catch {
                Write-Warning "Failed to add $member"
            }
        }
    }
    else {
        Write-Host "No members to add." -ForegroundColor Green
    }

    Write-Host "Synchronization completed successfully."
    Stop-Transcript
}
