using namespace System.Net
# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$CheckOrchestrator = $true

if ($request.query.GUID) {
    $RunningGUID = $request.query.GUID
    $CacheFileName = '{0}.json' -f $RunningGUID

    if (Test-Path "Cache_DomainHealth\$($CacheFileName)" ) {
        try {
            $JSONOutput = Get-Content "Cache_DomainHealth\$($CacheFileName)" -ErrorAction Stop | ConvertFrom-Json
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                    StatusCode = [HttpStatusCode]::OK
                    Body       = $JSONOutput
                })
        }
        catch {
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                    StatusCode = [HttpStatusCode]::InternalServerError
                    Body       = @{Results = 'Error' }
                })
        }

        try {
            Remove-Item "Cache_DomainHealth\$($CacheFileName)" -Force
        }
        catch {}
        $CheckOrchestrator = $false
    }   
    else {
        # Associate values to output bindings by calling 'Push-OutputBinding'.
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body       = @{ Waiting = $true }
            })
    }
}
else {
    $RunningGUID = New-Guid
    $CacheFileName = '{0}.json' -f $RunningGUID

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = @{ GUID = $RunningGUID }
        })
    $OrchQueue = [PSCustomObject]@{
        CacheFileName = $CacheFileName
        Query         = $Request.Query
    }

    $OrchQueue | ConvertTo-Json | Out-File "Cache_DomainHealthQueue\$($CacheFileName)"
}

if (!(Test-Path 'Cache_DomainHealthQueue\CurrentlyRunning.txt') -and $CheckOrchestrator) {
    try {
        New-Item 'Cache_DomainHealthQueue\CurrentlyRunning.txt' -ErrorAction Stop | Out-Null
        $InstanceId = Start-NewOrchestration -FunctionName 'DomainHealth_Orchestrator'
        Write-Information "ORCHESTRATOR INSTANCE: $InstanceId"
    }
    catch {}
}