# Sync-SiloMembers.ps1

## Exemplos de chamadas:
- (**Exemplo #1**) Sincroniza todos os usuários do grupo T0 Admins com o silo T0-Silo
  - `Sync-SiloMembers -siloName "T0-Silo" -adminGroup "T0 Admins" -LogFile "C:\Tools\Scripts\Sync-T0_Silo_log.txt"`

- (**Exemplo #2**) Sincroniza todos os usuários do grupo T1 Admins com o silo T1-Silo
  - `Sync-SiloMembers -siloName "T1-Silo" -adminGroup "T1 Admins" -LogFile "C:\Tools\Scripts\Sync-T1_Silo_log.txt"`

## Agendamento dos scripts (a cada 1 hora):

### Estratégia A: agendamento único, em um script que invoca os outros
- Utiliza o script [Invoke-SyncSiloMembers.ps1](Invoke-SyncSiloMembers.ps1): sincroniza todos os grupos com os silos
```powershell
# This script creates a scheduled task to run the Silo Synchronization script every hour.
# It uses the ScheduledTask module, which is available on Windows Server 2012 and newer.

# --- Task Configuration Variables ---
$TaskName = "Synchronize silos T0-Silo and T1-Silo with related groups"
$TaskDescription = "Synchronize silos T0-Silo and T1-Silo with related groups"
$ScriptPath = "C:\Tools\Scripts\Invoke-SyncSiloMembers.ps1" # <--- IMPORTANT: Update this path if your script is in a different location

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
# This script creates a scheduled task to run the Silo Synchronization script every hour.
# It uses the ScheduledTask module, which is available on Windows Server 2012 and newer.

# --- Task Configuration Variables ---
$TaskName = "Synchronize silo T0-Silo with T0 Admins group"
$TaskDescription = "Synchronize silo T0-Silo with T0 Admins group."
$ScriptPath = "C:\Tools\Scripts\Sync-SiloMembers.ps1" # <--- IMPORTANT: Update this path if your script is in a different location

# --- Action to be performed by the task ---
# This action runs PowerShell with the necessary arguments to execute your script.
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command ""& { . `"$ScriptPath`"; Sync-SiloMembers -siloName 'T0-Silo' -adminGroup 'T0 Admins' -LogFile 'C:\Tools\Scripts\Sync-T0_Silo_log.txt' }"""

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
$TaskName = "Synchronize silo T1-Silo with T1 Admins group"
$TaskDescription = "Synchronize silo T1-Silo with T1 Admins group."
$TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command ""& { . `"$ScriptPath`"; Sync-SiloMembers -siloName 'T1-Silo' -adminGroup 'T1 Admins' -LogFile 'C:\Tools\Scripts\Sync-T1_Silo_log.txt' }"""
```
