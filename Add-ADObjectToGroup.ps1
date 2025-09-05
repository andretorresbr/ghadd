function Add-ADObjectToGroup {
<#
    .SYNOPSIS
        Adds users or computers from a specified Active Directory OU to a target group.

    .DESCRIPTION
        This function finds all user or computer objects within a source Organizational Unit (OU),
        including its sub-OUs, and adds them to a specified destination group.
        It has an optional parameter to exclude specific objects from being added.

    .PARAMETER SourceOU
        The distinguished name or path of the Organizational Unit (OU) to search for objects.
        The search is performed recursively on all sub-OUs.

    .PARAMETER DestinationGroup
        The name of the Active Directory group where the found objects will be added.

    .PARAMETER ObjectType
        Specifies the type of objects to search for. Valid values are 'User' or 'Computer'.

    .PARAMETER ExcludedObject
        An optional parameter to specify one or more objects (by their name) to be excluded from being
        added to the group. This can be a single string or an array of strings.

    .EXAMPLE
        Add-ADObjectToGroup -SourceOU "OU=Tier0,DC=corp,DC=local" -DestinationGroup "T0 Servers" -ObjectType Computer

        This command finds all computer objects in the 'Tier0' OU and its sub-OUs and adds them to the 'T0 Servers' group.

    .EXAMPLE
        Add-ADObjectToGroup -SourceOU "OU=Usuarios,OU=Tier0,DC=corp,DC=local" -DestinationGroup "T0 Users" -ObjectType User -ExcludedObject ("breaktheglass_da","btg_da")

        This command finds all user objects in the 'Usuarios/Tier0' OU and its sub-OUs. It then adds them to the 'T0 Users' group, but it skips the users with the name 'breaktheglass_da' and 'btg_da'.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceOU,
        [Parameter(Mandatory = $true)]
        [string]$DestinationGroup,
        [Parameter(Mandatory = $true)]
        [ValidateSet("User", "Computer")]
        [string]$ObjectType,
        [string[]]$ExcludedObject = $null
    )
    
    # Check if the source OU exists
    try {
        $ou = Get-ADOrganizationalUnit -Identity $SourceOU -ErrorAction Stop
    }
    catch {
        Write-Error "The specified source OU '$SourceOU' was not found."
        return
    }

    # Check if the destination group exists
    try {
        $group = Get-ADGroup -Identity $DestinationGroup -ErrorAction Stop
    }
    catch {
        Write-Error "The specified destination group '$DestinationGroup' was not found."
        return
    }

    # Set the filter based on the object type
    $filter = switch ($ObjectType) {
        "User" { "objectClass -eq 'user'" }
        "Computer" { "objectClass -eq 'computer'" }
    }

    # Find objects in the source OU and sub OUs
    try {
        $objectsToAdd = Get-ADObject -Filter $filter -SearchBase $ou.DistinguishedName -SearchScope Subtree -Properties SamAccountName, Name -ErrorAction Stop
    }
    catch {
        Write-Error "Could not retrieve objects from the source OU."
        return
    }
    
    # Process each object found
    foreach ($object in $objectsToAdd) {
        # Check if the object is in the exclusion list
        if (-not ($ExcludedObject -contains $object.SamAccountName)) {
            Write-Host "Adding $($object.SamAccountName) to group $($group.Name)..."
            try {
                Add-ADGroupMember -Identity $group.Name -Members $object.DistinguishedName -ErrorAction Stop
                Write-Host "Successfully added $($object.SamAccountName)." -ForegroundColor Green
            }
            catch {
                Write-Warning "Could not add $($object.SamAccountName) to the group. It may already be a member."
            }
        }
        else {
            Write-Host "Skipping $($object.SamAccountName) as it is on the exclusion list." -ForegroundColor Yellow
        }
    }

    Write-Host "Script execution completed."
}