param($Context)

$File = '.\test-log.txt'
try {
  New-Item 'Cache_Scheduler' -ItemType Directory -ErrorAction SilentlyContinue
  New-Item 'Cache_Scheduler\CurrentlyRunning.txt' -ItemType File -Force

  $Batch = (Invoke-DurableActivity -FunctionName 'Scheduler_GetQueue' -Input 'LetsGo')
  $ParallelTasks = foreach ($Item in $Batch) {
    Invoke-DurableActivity -FunctionName "Scheduler_$($item['Type'])" -Input $item -NoWait
  }

  $Outputs = Wait-ActivityFunction -Task $ParallelTasks
  Write-Host $Outputs
  Remove-Item 'Cache_Scheduler\CurrentlyRunning.txt' -Force
  'Scheduler: Ran' | Out-File -Append $File 
}
catch {
  "Scheduler: Exception - $($_.Exception.Message)" | Out-File -Append $File
}
#Log-request  -API "Scheduler" -tenant $tenant -message "Scheduler Ran." -sev Debug