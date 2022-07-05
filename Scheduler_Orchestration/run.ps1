param($Context)

$File = '.\orchestrator.txt'

New-Item 'Cache_Scheduler\CurrentlyRunning.txt' -ItemType File -ErrorAction SilentlyContinue
'=== Orchestrator Start ===' | Out-File -Append $File

$Request = [PSCustomObject]@{
  Context = $Context
}

if ($null -ne $Request) {
  'Start cleanup' | Out-File -Append $File
  $Request | ConvertTo-Json | Out-File -Append $File
  $Cleanup = Invoke-DurableActivity -FunctionName 'Scheduler_StorageCleanup' -Input $Request -NoWait
  $Cleanup | ConvertTo-Json | Out-File -Append $File
  $Output = Wait-ActivityFunction -Task $Cleanup
  $Output | Out-File -Append $File
}

try {
  'Remove lock file' | Out-File -Append $File
  Remove-Item 'Cache_Scheduler\CurrentlyRunning.txt' -Force -Confirm:$false
}
catch {
  "Error removing lock file: $($_.Exception.Message)" | Out-File -Append $File
}

'=== END Orchestrator ===' | Out-File -Append $File 


#Log-request  -API "Scheduler" -tenant $tenant -message "Scheduler Ran." -sev Debug