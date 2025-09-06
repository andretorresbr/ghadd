# Author: Andre Torres (https://github.com/andretorresbr/ghadd/)

function Sync-SiloMembers {
	<#
	.SYNOPSIS
	Synchronizes user members of an Active Directory group to an authentication policy silo.

	.DESCRIPTION
	This function performs a two-way synchronization:
	1. It removes users from the specified silo that are not members of the admin group.
	2. It adds users from the admin group to the silo and sets their authentication policy silo property.

	.PARAMETER siloName
	The name of the authentication policy silo to synchronize.

	.PARAMETER adminGroup
	The name of the Active Directory group whose user members should be synchronized to the silo.

	.PARAMETER LogFile
	The full path to the log file where all command output will be written. This is a mandatory parameter.

	.EXAMPLE
	Sync-SiloMembers -siloName "T0-Silo" -adminGroup "T0 Admins" -LogFile "C:\Tools\Scripts\Sync-T0_Silo_log.txt"
	Sync-SiloMembers -siloName "T1-Silo" -adminGroup "T1 Admins" -LogFile "C:\Tools\Scripts\Sync-T1_Silo_log.txt"

	This command synchronizes the members of the "T1 Admins" group to the "T1-Silo" authentication policy silo. It ensures that only members of the group are configured in the silo and that all group members have the silo set on their user account.

	#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true,
                   HelpMessage="The name of the authentication policy silo to synchronize.")]
        [string]$siloName,

        [Parameter(Mandatory=$true,
                   HelpMessage="The name of the Active Directory group whose members should be synchronized to the silo.")]
        [string]$adminGroup,
		[Parameter(Mandatory = $true)]
        [string]$LogFile
    )
	
	# Define the log file path
	Start-Transcript -Path $LogFile -Append

	# Get the 'T0-Silo' authentication policy silo and explicitly retrieve
	# its 'PermittedAccounts' property. This is a crucial step as the property
	# is not returned by default.
	$silo = Get-ADAuthenticationPolicySilo -Identity $siloName
	if (-not $silo) {
		Write-Host "Error: The `"$siloName`" authentication policy silo was not found. Exiting script." -ForegroundColor Red
		return
	}

	# Get a list of all user accounts that are members of the admin group.
	# The -Recursive parameter ensures that we include members from nested groups.
	# We then filter the output to only include 'user' objects.
	$adminGroupMembers = Get-ADGroupMember -Identity $adminGroup -Recursive | Where-Object { $_.ObjectClass -eq 'user' }
	if (-not $adminGroupMembers) {
		Write-Host "Warning: The `"$adminGroup`" group contains no user members. Exiting script." -ForegroundColor Yellow
		return
	}


	# ****************************************************************************************
	# Part 1: checks if Silo is consistent with group
	# ****************************************************************************************
	Write-Host "Checking if there are users configured on Silo `"$siloName`" that are not members of group `"$adminGroup`"..." -ForegroundColor Green

	# Get a list of all user accounts that are members of the admin group.
	# The -Recursive parameter ensures that we include members from nested groups.
	# We then filter the output to only include 'user' objects.
	$adminGroupMembers = Get-ADGroupMember -Identity $adminGroup -Recursive | Where-Object { $_.ObjectClass -eq 'user' }
	if (-not $adminGroupMembers) {
		Write-Host "Warning: The `"$adminGroup`" group contains no user members. Exiting script." -ForegroundColor Yellow
		return
	}

	# Create a simple list of distinguished names for easy and fast comparison.
	# This prevents repeated calls to Active Directory for each check.
	$adminDNs = $adminGroupMembers.DistinguishedName
	Write-Host "Found $($adminDNs.Count) user members in `"$adminGroup`" group."

	# Find users who are in the silo's Members list but NOT in the admin group.
	# We compare the DistinguishedName of each permitted account against our list of admin group members.
	$incorrectlyConfiguredUsers = $silo.Members | Where-Object { $adminDNs -notcontains $_ }

	# Check if there are any users to correct.
	if (-not $incorrectlyConfiguredUsers) {
		Write-Host "No incorrectly configured users found. Your silo is in compliance." -ForegroundColor Blue
	} else {
		Write-Host "Found $($incorrectlyConfiguredUsers.Count) users requiring correction." -ForegroundColor Yellow
		Write-Host "Performing clean-up..."

		# Loop through each incorrectly configured user and fix their settings.
		foreach ($userDN in $incorrectlyConfiguredUsers) {
			try {
				# Get the user object using the distinguished name.
				$user = Get-ADUser -Identity $userDN
				Write-Host "   -> Processing user: $($user.SamAccountName)"

				# Step 1: Unset the AuthenticationPolicySilo property on the user object.
				# This is done by setting the value to $null.
				Write-Host "   -> Unsetting silo on user account..."
				Set-ADUser -Identity $user -AuthenticationPolicySilo $null
				Write-Host "   -> Silo unset successfully."

				# Step 2: Remove the user from the silo's PermittedAccounts list.
				# This revokes their access to the silo's resources.
				Write-Host "   -> Revoking silo access..."
				Revoke-ADAuthenticationPolicySiloAccess -Identity $silo -Account $user -Confirm:$False
				Write-Host "   -> Access revoked successfully."
				Write-Host "" # Add a blank line for readability
			} catch {
				Write-Host "   -> Error processing user '$userDN': $_" -ForegroundColor Red
			}
		}
	}


	# ****************************************************************************************
	# Part 2: add users to Silo
	# ****************************************************************************************
	Write-Host "Checking if there are users members of group `"$adminGroup`" that are not configured on Silo `"$siloName`"..." -ForegroundColor Green

	# Loop through each user account found in the group.
	foreach ($account in $adminGroupMembers) {
		Write-Host "Processing user: $($account.SamAccountName)"

		# Check if the user's DistinguishedName is already in the Silo's PermittedAccounts list.
		# The .DistinguishedName property provides a unique string for comparison.
		if ($silo.Members -notcontains $account.DistinguishedName) {
			# The user is not yet a permitted account. Grant them access.
			Write-Host "   -> Granting Silo access for $($account.SamAccountName)..."
			Grant-ADAuthenticationPolicySiloAccess -Identity $silo -Account $account
			Write-Host "   -> Access granted successfully."
		} else {
			# The user is already a permitted account.
			Write-Host "   -> $($account.SamAccountName) is already a permitted account. Skipping access grant."
		}

		# Check if the user's account is already associated with the Silo.
		# This prevents the script from running the command unnecessarily.
		$userSilo = (Get-ADUser -Identity $account -Properties AuthenticationPolicySilo).AuthenticationPolicySilo
		if ($silo.DistinguishedName -eq $userSilo) {
			Write-Host "   -> $($account.SamAccountName) is already configured for Silo `"$siloName`". Skipping."
		} else {
			Write-Host "   -> Setting $($account.SamAccountName)'s AuthenticationPolicySilo property..."
			Set-ADUser -Identity $account -AuthenticationPolicySilo $silo
			Write-Host "   -> Property set successfully."
		}
		Write-Host "" # Add a blank line for readability between users
	}
	
	Stop-Transcript

}
