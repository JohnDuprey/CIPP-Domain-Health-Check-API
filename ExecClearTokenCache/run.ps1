using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$APIName = $TriggerMetadata.FunctionName
Log-Request -user $request.headers.'x-ms-client-principal' -API $APINAME -message 'Accessed this API' -Sev 'Debug'

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

if (Test-Path 'Cache_Scheduler\_ClearTokenCache.json') {
    $Scheduler = Get-Content 'Cache_Scheduler\_ClearTokenCache.json' | ConvertFrom-Json
    $body = [pscustomobject]@{'Results' = "Clear token cache running. Status: $($Scheduler.tenant)" }
}
else { 
    $ResourceGroup = $ENV:Website_Resource_Group
    $Subscription = ($ENV:WEBSITE_OWNER_NAME).split('+') | Select-Object -First 1
    if ($env:MSI_SECRET) {
        Disable-AzContextAutosave -Scope Process | Out-Null
        $AzSession = Connect-AzAccount -Identity -Subscription $Subscription
    }
    $KV = Get-AzKeyVault -SubscriptionId $Subscription -ResourceGroupName $ResourceGroup

    $Guid = New-Guid
    Write-Host 'TESTING: Updating keyvault values'
    Set-AzKeyVaultSecret -VaultName $kv.vaultname -Name 'RefreshToken' -SecretValue (ConvertTo-SecureString -String "This is a test $Guid" -AsPlainText -Force)
    Set-AzKeyVaultSecret -VaultName $kv.vaultname -Name 'ExchangeRefreshToken' -SecretValue (ConvertTo-SecureString -String "This is a test $Guid" -AsPlainText -Force)

    [PSCustomObject]@{
        tenant = 'Phase1'
        Type   = 'ClearTokenCache'
    } | ConvertTo-Json -Compress | Out-File 'Cache_Scheduler\_ClearTokenCache.json' -Force

    $body = [pscustomobject]@{'Results' = 'Clear token cache queued' }
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })