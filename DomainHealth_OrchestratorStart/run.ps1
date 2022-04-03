param($Timer)

$CurrentlyRunning = Get-Item 'Cache_DomainHealthQueue\CurrentlyRunning.txt' -ErrorAction SilentlyContinue | Where-Object -Property LastWriteTime -GT (Get-Date).AddSeconds(-5)
if (!$CurrentlyRunning) {
    try {
        New-Item 'Cache_DomainHealthQueue\CurrentlyRunning.txt' -ErrorAction Stop | Out-Null
    }
    catch {}
    Start-NewOrchestration -FunctionName 'DomainHealth_Orchestrator'
}
