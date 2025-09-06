# Author: Andre Torres (https://github.com/andretorresbr/ghadd/)

# Loads Sync-ADObjectToGroup script
$path = $PSScriptRoot + "\Sync-SiloMembers.ps1"
Import-Module $path


### Tier 0 Silo ###
# Syncs all existing users on T0 Admins group to T0 Silo
Sync-SiloMembers -siloName "T0-Silo" -adminGroup "T0 Admins" -LogFile "C:\Tools\Scripts\Sync-T0_Silo_log.txt"
####################


### Tier 1 syncs ###
# Syncs all existing users on T1 Admins group to T1 Silo
Sync-SiloMembers -siloName "T1-Silo" -adminGroup "T1 Admins" -LogFile "C:\Tools\Scripts\Sync-T1_Silo_log.txt"
####################