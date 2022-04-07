using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$APIName = $TriggerMetadata.FunctionName
Log-Request -user $request.headers.'x-ms-client-principal' -API $APINAME -message 'Accessed this API' -Sev 'Debug'

$ResourceGroup = $ENV:Website_Resource_Group
$Subscription = ($ENV:WEBSITE_OWNER_NAME).split('+') | Select-Object -First 1
if ($env:MSI_SECRET) {
    Disable-AzContextAutosave -Scope Process | Out-Null
    $AzSession = Connect-AzAccount -Identity -Subscription $Subscription
}
$KV = Get-AzKeyVault -SubscriptionId $Subscription -ResourceGroupName $ResourceGroup

Write-Host 'TESTING: Updating keyvault values'
Set-AzKeyVaultSecret -VaultName $kv.vaultname -Name 'RefreshToken' -SecretValue 'This is a test 2'
Set-AzKeyVaultSecret -VaultName $kv.vaultname -Name 'ExchangeRefreshToken' -SecretValue 'This is a test 2'

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

if (Test-Path 'Cache_Scheduler\_ClearTokenCache.json') {
    $Scheduler = Get-Content 'Cache_Scheduler\_ClearTokenCache.json' | ConvertFrom-Json
    $body = [pscustomobject]@{'Results' = "Clear token cache running. Status: $($Scheduler.tenant)" }
}
else { 
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