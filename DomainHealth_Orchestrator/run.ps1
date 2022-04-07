param($Context)
$Context = $Context | ConvertTo-Json | ConvertFrom-Json
$Item = $Context.Input

#Write-Information "ORCH: $($Item.CacheFileName)"
Invoke-DurableActivity -FunctionName 'Durable_DomainHealthCheck' -Input $Item.CacheFileName -NoWait -ErrorAction Stop
