# Author: Andre Torres (https://github.com/andretorresbr/ghadd/)

# Loads Sync-ADObjectToGroup script
$path = $PSScriptRoot + "\Sync-ADObjectToGroup.ps1"
Import-Module $path


### Tier 0 syncs ###

# Syncs all existing computers under OUs Tier0 and Domain Controllers with group T0 Servers
Sync-ADObjectToGroup -SourceOU ("OU=Tier0,DC=corp,DC=local", "OU=Domain Controllers,DC=corp,DC=local") -DestinationGroup "T0 Servers" -ObjectType Computer -LogFile "C:\Tools\Scripts\Sync-T0_Servers_log.txt"

# Syncs all existing users under OU Tier0/Usuarios with group T0 Users, except users breaktheglass_da and btg_da
Sync-ADObjectToGroup -SourceOU "OU=Usuarios,OU=Tier0,DC=corp,DC=local" -DestinationGroup "T0 Users" -ObjectType User -ExcludedObject @("breaktheglass_da","btg_da") -LogFile "C:\Tools\Scripts\Sync-T0_Users_log.txt"
####################


### Tier 1 syncs ###

# Syncs all existing computers under OUs Tier1 and Domain Controllers with group T1 Servers
Sync-ADObjectToGroup -SourceOU "OU=Tier1,DC=corp,DC=local" -DestinationGroup "T1 Servers" -ObjectType Computer -LogFile "C:\Tools\Scripts\Sync-T1_Servers_log.txt"

# Syncs all existing users under OU Tier1/Usuarios with group T1 Users
Sync-ADObjectToGroup -SourceOU "OU=Usuarios,OU=Tier1,DC=corp,DC=local" -DestinationGroup "T1 Users" -ObjectType User -LogFile "C:\Tools\Scripts\Sync-T1_Users_log.txt"
####################


### Tier 2 syncs ###

# Syncs all existing computers under OUs Tier2 and Domain Controllers with group T2 Estacoes
Sync-ADObjectToGroup -SourceOU "OU=Tier2,DC=corp,DC=local" -DestinationGroup "T2 Estacoes" -ObjectType Computer -LogFile "C:\Tools\Scripts\Sync-T2_Estacoes_log.txt"

# Syncs all existing users under OU Tier2/Usuarios with group T2 Users
Sync-ADObjectToGroup -SourceOU "OU=Usuarios,OU=Tier2,DC=corp,DC=local" -DestinationGroup "T2 Users" -ObjectType User -LogFile "C:\Tools\Scripts\Sync-T2_Users_log.txt"
####################
