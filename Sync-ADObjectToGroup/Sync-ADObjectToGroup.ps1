# Author: Andre Torres (https://github.com/andretorresbr/ghadd/)

function Sync-ADObjectToGroup {
<#
    .SYNOPSIS
        Synchronizes a target Active Directory group with the users or computers from one or more specified OUs.

    .DESCRIPTION
        This function ensures that a destination group contains exactly the objects found within
        one or more source Organizational Units (OUs), including their sub-OUs. Objects in the group that are not in any of the
        source OUs are removed, and objects from the source OUs not in the group are added.
        It has an optional parameter to exclude specific objects from being synchronized.

    .PARAMETER SourceOU
        The distinguished name or path of the Organizational Unit (OU) or an array of OUs to search for objects.
        The search is performed recursively on all sub-OUs.

    .PARAMETER DestinationGroup
        The name of the Active Directory group to be synchronized.

    .PARAMETER ObjectType
        Specifies the type of objects to synchronize. Valid values are 'User' or 'Computer'.

    .PARAMETER ExcludedObject
        An optional parameter to specify one or more objects (by their name) to be excluded from being
        added or removed from the group. This can be a single string or an array of strings.

    .PARAMETER LogFile
        The full path to the log file where all command output will be written. This is a mandatory parameter.
		
    .EXAMPLE
        Sync-ADObjectToGroup -SourceOU "OU=Tier0,DC=corp,DC=local" -DestinationGroup "T0 Servers" -ObjectType Computer

        This command synchronizes the 'T0 Servers' group to contain exactly the computer objects from the 'Tier0' OU and its sub-OUs.

    .EXAMPLE
        Sync-ADObjectToGroup -SourceOU @("OU=Tier0,DC=corp,DC=local", "OU=Domain Controllers,DC=corp,DC=local") -DestinationGroup "T0 Servers" -ObjectType Computer -LogFile "C:\Tools\Scripts\Sync-T0_Servers_log.txt"

        This command synchronizes the 'T0 Servers' group with computer objects found in both the 'Tier0' and 'Tier1' OUs.

    .EXAMPLE
        Sync-ADObjectToGroup -SourceOU "OU=Usuarios,OU=Tier0,DC=corp,DC=local" -DestinationGroup "T0 Users" -ObjectType User -ExcludedObject @("breaktheglass_da","btg_da") -LogFile "C:\Tools\Scripts\Sync-T0_Users_log.txt"

        This command synchronizes the 'T0 Users' group with user objects from the 'Usuarios/Tier0' OU, excluding the users with the name 'breaktheglass_da' and 'btg_da'.
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
	
	# Define the log file path
	Start-Transcript -Path $LogFile -Append
    
    # Check if the destination group exists
    try {
        $group = Get-ADGroup -Identity $DestinationGroup -ErrorAction Stop
    }
    catch {
        Write-Error "The specified destination group '$DestinationGroup' was not found."
        Stop-Transcript
        return
    }

    # Initialize an array to hold all desired objects from all OUs
    $allDesiredObjects = @()
    
    # Find desired objects from all specified OUs and store them in a single collection
    foreach ($ouPath in $SourceOU) {
        Write-Host "Searching for objects in '$ouPath'..."

        try {
            Get-ADOrganizationalUnit -Identity $ouPath -ErrorAction Stop | Out-Null

            if ($ObjectType -eq "Computer") {
                # IMPORTANT: Using Get-ADComputer avoids adding gMSA/sMSA objects
                $objectsInOU = Get-ADComputer `
                    -SearchBase $ouPath `
                    -SearchScope Subtree `
                    -Filter * `
                    -Properties SamAccountName, DistinguishedName
            }
            else {
                $objectsInOU = Get-ADUser `
                    -SearchBase $ouPath `
                    -SearchScope Subtree `
                    -Filter * `
                    -Properties SamAccountName, DistinguishedName
            }

            $allDesiredObjects += $objectsInOU
        }
        catch {
            Write-Error "The specified source OU '$ouPath' was not found or could not be searched. Skipping."
        }
    }
    
    # Check if any objects were found in the specified OUs
    if (-not $allDesiredObjects) {
        Write-Warning "No objects found in the specified source OUs. The destination group will be emptied of synchronized members."
    }

    # Get current members of the destination group
    try {
        $currentMembers = Get-ADGroupMember -Identity $group.Name -Recursive |
            Where-Object { $_.objectClass -in @("user", "computer") } |
            ForEach-Object {
                Get-ADObject -Identity $_.DistinguishedName -Properties SamAccountName, DistinguishedName
            }
    }
    catch {
        Write-Warning "Could not retrieve current members of the group. The group may be empty."
        $currentMembers = @()
    }

    # Get a list of SamAccountNames of desired objects, excluding the ones to be skipped
    $desiredSamAccounts = $allDesiredObjects.SamAccountName | Where-Object { $_ -notin $ExcludedObject }
    
    # Get a list of SamAccountNames of current members, excluding the ones to be skipped
    $currentSamAccounts = $currentMembers.SamAccountName | Where-Object { $_ -notin $ExcludedObject }

    # Find members to remove (in group but not in any of the OUs)
    $membersToRemove = $currentSamAccounts | Where-Object { $_ -notin $desiredSamAccounts }

    # Find members to add (in OU but not in group)
    $membersToAdd = $desiredSamAccounts | Where-Object { $_ -notin $currentSamAccounts }

    # Process members to remove
    if ($membersToRemove) {
        Write-Host "Found members to remove from the group: $($membersToRemove -join ', ')..." -ForegroundColor Red
        foreach ($member in $membersToRemove) {
            try {
                $memberDN = ($currentMembers | Where-Object { $_.SamAccountName -eq $member }).DistinguishedName
                Remove-ADGroupMember -Identity $group.Name -Members $memberDN -Confirm:$false -ErrorAction Stop
                Write-Host "Successfully removed $($member) from group $($DestinationGroup)." -ForegroundColor Red
            }
            catch {
                Write-Warning "Could not remove $($member) from the group."
            }
        }
    }
    else {
        Write-Host "No members need to be removed from group $($DestinationGroup)." -ForegroundColor Green
    }
    
    # Process members to add
    if ($membersToAdd) {
        Write-Host "Found members to add to the group: $($membersToAdd -join ', ')..." -ForegroundColor Green
        foreach ($member in $membersToAdd) {
            try {
                $memberDN = ($allDesiredObjects | Where-Object { $_.SamAccountName -eq $member }).DistinguishedName
                Add-ADGroupMember -Identity $group.Name -Members $memberDN -ErrorAction Stop
                Write-Host "Successfully added $($member) to group $($DestinationGroup)." -ForegroundColor Green
            }
            catch {
                Write-Warning "Could not add $($member) to the group $($DestinationGroup). It may already be a member or the object no longer exists."
            }
        }
    }
    else {
        Write-Host "No members need to be added to group $($DestinationGroup)." -ForegroundColor Green
    }

    Write-Host "Synchronization script execution completed."
	Stop-Transcript
}
