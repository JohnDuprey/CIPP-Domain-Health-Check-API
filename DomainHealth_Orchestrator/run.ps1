param($Context)

try {
    $Context = $Context | ConvertTo-Json | ConvertFrom-Json
    Write-Information '============================= BEGIN ORCHESTRATOR ============================='
    try {
        $Batch = Invoke-ActivityFunction -FunctionName 'DomainHealth_GetQueue' -Input 'LetsGo' -ErrorAction Stop
        Write-Information 'Got queued jobs'
    }
    catch { 
        Write-Information "QUEUE EXCEPTION: $($_.Exception.Message)"
        $Batch = $null
    }
    if ($Batch -and ($Batch | Measure-Object).Count -gt 0) {
        Write-Information '================================== BEGIN QUEUE ===================================='
        $ParallelTasks = foreach ($Item in $Batch) {
            if ($null -ne $Item -and (Test-Path "Cache_DomainHealthQueue\$Item")) {
                Write-Information "Processing: $Item"
                try {
                    Invoke-DurableActivity -FunctionName 'Durable_DomainHealthCheck' -Input $Item -NoWait -ErrorAction Stop
                }
                catch {
                    Write-Information "EXCEPTION: $($_.Exception.Message)"
                }
            }
        }
        try {
            Wait-ActivityFunction -Task $ParallelTasks
        }
        catch {}
        Write-Information '================================== END QUEUE ===================================='
    }
}
catch {
    Write-Information "ORCHESTRATOR EXCEPTION: $($_.Exception.Message)"
}

If (Test-Path 'Cache_DomainHealthQueue\CurrentlyRunning.txt') {
    try {
        Remove-Item 'Cache_DomainHealthQueue\CurrentlyRunning.txt' -Force | Out-Null
        Write-Information 'Cleanup lock file'
    }
    catch { Write-Information "EXCEPTION: $($_.Exception.Message)" }
}
Write-Information '================================== END ORCHESTRATOR =================================='