# GoHacking Active Directory Defense (GHADD)
<p align="center">
  <img src="https://firebasestorage.googleapis.com/v0/b/gohacking-prod.appspot.com/o/cursos%2Flogo%2Fz3Orzet4fmUQEc9JnYYj?alt=media&token=41808912-2081-456b-91c5-cd7a29e8771e" alt="Main UI" width="300">
</p>
Repositório de arquivos públicos utilizados no curso GoHacking Active Directory Defense (https://gohacking.com.br/curso/gohacking-active-directory-defense)

## Sync-ADObjectToGroup.ps1

### Exemplos de chamadas:
- (**Exemplo #1**) Sincroniza todos os computadores existentes debaixo da estrutura das OUs Tier0 e Domain Controllers com o grupo T0 Servers
  - `Sync-ADObjectToGroup -SourceOU ("OU=Tier0,DC=corp,DC=local", "OU=Domain Controllers,DC=corp,DC=local") -DestinationGroup "T0 Servers" -ObjectType Computer`

- (**Exemplo #2**) Sincroniza todos os usuários existentes debaixo da estrutura da OU Tier0 com o grupo T0 Users, com a exceção dos usuários breaktheglass_da e btg_da
  - `Sync-ADObjectToGroup -SourceOU "OU=Usuarios,OU=Tier0,DC=corp,DC=local" -DestinationGroup "T0 Users" -ObjectType User -ExcludedObject @("breaktheglass_da","btg_da")`

### Agendamento do script (a cada 1 hora):
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
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command ""& { . `"$ScriptPath`"; Sync-ADObjectToGroup -SourceOU @('OU=Tier0,DC=corp,DC=local', 'OU=Domain Controllers,DC=corp,DC=local') -DestinationGroup 'T0 Servers' -ObjectType Computer }"""

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
  - Idêntico ao Exemplo #1, a diferença está apenas nas variáveis:
```powershell
$TaskName = "Synchronize T0 Users Group"
$TaskDescription = "Synchronizes the 'T0 Users' group with users from specified OUs."
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command ""& { . `"$ScriptPath`"; Sync-ADObjectToGroup -SourceOU 'OU=Usuarios,OU=Tier0,DC=corp,DC=local' -DestinationGroup 'T0 Users' -ObjectType User -ExcludedObject @('breaktheglass_da','btg_da') }"""
```
