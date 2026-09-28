# This script creates a scheduled task to run the BHCE ingestor every Sunday at 8pm
# It uses the ScheduledTask module, which is available on Windows Server 2012 and newer.

# --- Task Configuration Variables ---
$TaskName = "Ingest and load BHCE information"
$TaskDescription = "Runs BloodHound CE ingestor and loads it into BHCE"
$ScriptPath = "C:\Tools\Scripts\Invoke-BhceIngestor.ps1" # <--- IMPORTANT: Update this path if your script is in a different location
# --- Action to be performed by the task ---
$InnerCommand = "& '$ScriptPath' -SharpHoundPath 'C:\Tools\sharphound' -LogFile 'C:\Tools\sharphound\Invoke-BhceIngestor_log.txt' -ClearDatabase"
$TaskAction = New-ScheduledTaskAction -Execute "C:\Program Files\PowerShell\7\pwsh.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"$InnerCommand`""
# --- Trigger for the task ---
# This creates a weekly trigger that runs every Sunday 8pm.
$TaskTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 20:00
# --- Principal (User Account) for the task ---
# This sets the task to run with System privileges, whether a user is logged on or not.
$TaskPrincipal = New-ScheduledTaskPrincipal -UserId "corp\svc_coletorbhce$" -LogonType Password -RunLevel Highest

# --- Register the scheduled task ---
try {
    Write-Host "Registering scheduled task '$TaskName'..."
    Register-ScheduledTask -Action $TaskAction -Trigger $TaskTrigger -Principal $TaskPrincipal -TaskName $TaskName -Description $TaskDescription -Force
    Write-Host "Scheduled task '$TaskName' successfully registered." -ForegroundColor Green
}
catch {
    Write-Error "Failed to register the scheduled task. Ensure you are running PowerShell with Administrator privileges."
}
