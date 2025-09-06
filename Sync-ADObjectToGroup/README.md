# Sync-ADObjectToGroup.ps1

## Exemplos de chamadas:
- (**Exemplo #1**) Sincroniza todos os computadores existentes debaixo da estrutura das OUs Tier0 e Domain Controllers com o grupo T0 Servers
  - `Sync-ADObjectToGroup -SourceOU ("OU=Tier0,DC=corp,DC=local", "OU=Domain Controllers,DC=corp,DC=local") -DestinationGroup "T0 Servers" -ObjectType Computer -LogFile "C:\Tools\Scripts\Sync-T0_Servers_log.txt"`

- (**Exemplo #2**) Sincroniza todos os usuários existentes debaixo da estrutura da OU Tier0/Usuarios com o grupo T0 Users, com a exceção dos usuários breaktheglass_da e btg_da
  - `Sync-ADObjectToGroup -SourceOU "OU=Usuarios,OU=Tier0,DC=corp,DC=local" -DestinationGroup "T0 Users" -ObjectType User -ExcludedObject @("breaktheglass_da","btg_da") -LogFile "C:\Tools\Scripts\Sync-T0_Users_log.txt"`

- (**Exemplo #3**) Sincroniza todos os computadores existentes debaixo da estrutura da OU Tier1 com o grupo T1 Servers
  - `Sync-ADObjectToGroup -SourceOU "OU=Tier1,DC=corp,DC=local" -DestinationGroup "T1 Servers" -ObjectType Computer -LogFile "C:\Tools\Scripts\Sync-T1_Servers_log.txt"`

- (**Exemplo #4**) Sincroniza todos os usuários existentes debaixo da estrutura da OU Tier1/Usuarios com o grupo T1 Users
  - `Sync-ADObjectToGroup -SourceOU "OU=Usuarios,OU=Tier1,DC=corp,DC=local" -DestinationGroup "T1 Users" -ObjectType User -LogFile "C:\Tools\Scripts\Sync-T1_Users_log.txt"`

- (**Exemplo #5**) Sincroniza todos os computadores existentes debaixo da estrutura da OU Tier2 com o grupo T2 Estacoes
  - `Sync-ADObjectToGroup -SourceOU "OU=Tier2,DC=corp,DC=local" -DestinationGroup "T2 Estacoes" -ObjectType Computer -LogFile "C:\Tools\Scripts\Sync-T2_Estacoes_log.txt"`

- (**Exemplo #6**) Sincroniza todos os usuários existentes debaixo da estrutura da OU Tier2/Usuarios com o grupo T2 Users
  - `Sync-ADObjectToGroup -SourceOU "OU=Usuarios,OU=Tier2,DC=corp,DC=local" -DestinationGroup "T2 Users" -ObjectType User -LogFile "C:\Tools\Scripts\Sync-T2_Users_log.txt"`

## Agendamento dos scripts (a cada 1 hora):

### Estratégia A: agendamento único, em um script que invoca os outros
- Utiliza o script [Invoke-SyncADObjectToGroup.ps1](Invoke-SyncADObjectToGroup.ps1): sincroniza todos os computadores ou usuários existentes debaixo da estrutura de uma ou mais OUs e sincroniza com um grupo do AD
```powershell
# This script creates a scheduled task to run the AD Group Synchronization script every hour.
# It uses the ScheduledTask module, which is available on Windows Server 2012 and newer.

# --- Task Configuration Variables ---
$TaskName = "Synchronize T0, T1 and T2 Users and Computers to groups related"
$TaskDescription = "Synchronize T0, T1 and T2 Users and Computers to groups related"
$ScriptPath = "C:\Tools\Scripts\Invoke-SyncADObjectToGroup.ps1" # <--- IMPORTANT: Update this path if your script is in a different location

# --- Action to be performed by the task ---
# This action runs PowerShell with the necessary arguments to execute your script.
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command ""& { $ScriptPath }"""

# --- Trigger for the task ---
# This creates a weekly trigger that runs every day of the week and repeats every hour indefinitely.
$TaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 60)

# --- Principal (User Account) for the task ---
# This sets the task to run with System privileges, whether a user is logged on or not.
$TaskPrincipal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\System" -LogonType ServiceAccount -RunLevel Highest

# --- Register the scheduled task ---
try {
    Write-Host "Registering scheduled task '$TaskName'..."
    Register-ScheduledTask -Action $TaskAction -Trigger $TaskTrigger -Principal $TaskPrincipal -TaskName $TaskName -Description $TaskDescription -Force
    Write-Host "Scheduled task '$TaskName' successfully registered." -ForegroundColor Green
}
catch {
    Write-Error "Failed to register the scheduled task. Ensure you are running PowerShell with Administrator privileges."
}
```

### Estratégia B: agendamento múltiplo, um para cada sincronismo
- **Exemplo #1**
```powershell
# This script creates a scheduled task to run the AD Group Synchronization script every hour.
# It uses the ScheduledTask module, which is available on Windows Server 2012 and newer.

# --- Task Configuration Variables ---
$TaskName = "Synchronize T0 Servers Group"
$TaskDescription = "Synchronizes the 'T0 Servers' group with computers from specified OUs."
$ScriptPath = "C:\Tools\Scripts\Sync-ADObjectToGroup.ps1" # <--- IMPORTANT: Update this path if your script is in a different location

# --- Action to be performed by the task ---
# This action runs PowerShell with the necessary arguments to execute your script.
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command ""& { . `"$ScriptPath`"; Sync-ADObjectToGroup -SourceOU @('OU=Tier0,DC=corp,DC=local', 'OU=Domain Controllers,DC=corp,DC=local') -DestinationGroup 'T0 Servers' -ObjectType Computer -LogFile 'C:\Tools\Scripts\Sync-T0_Servers_log.txt' }"""

# --- Trigger for the task ---
# This creates a weekly trigger that runs every day of the week and repeats every hour indefinitely.
$TaskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 60)

# --- Principal (User Account) for the task ---
# This sets the task to run with System privileges, whether a user is logged on or not.
$TaskPrincipal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\System" -LogonType ServiceAccount -RunLevel Highest

# --- Register the scheduled task ---
try {
    Write-Host "Registering scheduled task '$TaskName'..."
    Register-ScheduledTask -Action $TaskAction -Trigger $TaskTrigger -Principal $TaskPrincipal -TaskName $TaskName -Description $TaskDescription -Force
    Write-Host "Scheduled task '$TaskName' successfully registered." -ForegroundColor Green
}
catch {
    Write-Error "Failed to register the scheduled task. Ensure you are running PowerShell with Administrator privileges."
}
```
- **Exemplo #2**
  - Idêntico ao Exemplo #1, a diferença está apenas nas seguintes variáveis:
```powershell
$TaskName = "Synchronize T0 Users Group"
$TaskDescription = "Synchronizes the 'T0 Users' group with users from specified OUs."
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command ""& { . `"$ScriptPath`"; Sync-ADObjectToGroup -SourceOU 'OU=Usuarios,OU=Tier0,DC=corp,DC=local' -DestinationGroup 'T0 Users' -ObjectType User -ExcludedObject @('breaktheglass_da','btg_da') -LogFile 'C:\Tools\Scripts\Sync-T0_Users_log.txt' }"""
```

- **Exemplo #3**
  - Idêntico ao Exemplo #1, a diferença está apenas nas seguintes variáveis:
```powershell
$TaskName = "Synchronize T1 Server Group"
$TaskDescription = "Synchronizes the 'T1 Servers' group with users from specified OUs."
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command ""& { . `"$ScriptPath`"; Sync-ADObjectToGroup -SourceOU 'OU=Tier1,DC=corp,DC=local' -DestinationGroup 'T1 Servers' -ObjectType Computer -LogFile 'C:\Tools\Scripts\Sync-T1_Servers_log.txt' }"""
```

- **Exemplo #4**
  - Idêntico ao Exemplo #1, a diferença está apenas nas seguintes variáveis:
```powershell
$TaskName = "Synchronize T1 Users Group"
$TaskDescription = "Synchronizes the 'T1 Users' group with users from specified OUs."
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command ""& { . `"$ScriptPath`"; Sync-ADObjectToGroup -SourceOU 'OU=Usuarios,OU=Tier1,DC=corp,DC=local' -DestinationGroup 'T1 Users' -ObjectType User -LogFile 'C:\Tools\Scripts\Sync-T1_Users_log.txt' }"""
```

- **Exemplo #5**
  - Idêntico ao Exemplo #1, a diferença está apenas nas seguintes variáveis:
```powershell
$TaskName = "Synchronize T2 Estacoes Group"
$TaskDescription = "Synchronizes the 'T2 Estacoes' group with users from specified OUs."
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command ""& { . `"$ScriptPath`"; Sync-ADObjectToGroup -SourceOU 'OU=Tier2,DC=corp,DC=local' -DestinationGroup 'T2 Estacoes' -ObjectType Computer -LogFile 'C:\Tools\Scripts\Sync-T2_Estacoes_log.txt' }"""
```

- **Exemplo #6**
  - Idêntico ao Exemplo #1, a diferença está apenas nas seguintes variáveis:
```powershell
$TaskName = "Synchronize T21 Users Group"
$TaskDescription = "Synchronizes the 'T2 Users' group with users from specified OUs."
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command ""& { . `"$ScriptPath`"; Sync-ADObjectToGroup -SourceOU 'OU=Usuarios,OU=Tier2,DC=corp,DC=local' -DestinationGroup 'T2 Users' -ObjectType User -LogFile 'C:\Tools\Scripts\Sync-T2_Users_log.txt' }"""
```
