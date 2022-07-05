using namespace System.Net
param($Request, $TriggerMetadata)

$file = 'cleanup.txt'
'=== Durable Cleanup ===' | Out-File $file
$Request | ConvertTo-Json | Out-File -Append $file
$TriggerMetadata | ConvertTo-Json | Out-File -Append $file

@"
"@


# Use connection string
$context = New-AzStorageContext -ConnectionString $ENV:AzureWebJobsStorage

try {
    # Clean Blobs
    Get-AzStorageBlob -Context $context -Container "$($ENV:Website_Content_Share)-largemessages" | Where-Object -Property LastModified -LT (Get-Date).addhours(-24) | Remove-AzStorageBlob

    # Cleanup Instances and History tables
    $InstancesTable = (Get-AzStorageTable -Context $context -Name '*instances').cloudTable
    $HistoryTable = (Get-AzStorageTable -Context $context -Name '*history').cloudTable

    try {
        #Get-AzTableRow -table $InstancesTable | Where-Object -Property RunTimeStatus -NE 'Running' | Remove-AzTableRow -Table $InstancesTable -ErrorAction Stop
    }
    catch {
        "Instance Cleanup: $($_.Exception)" | Out-File -Append $file 
    }

    $History = Get-AzTableRow -table $HistoryTable | Where-Object -Property _TimeStamp -LT (Get-Date).addhours(-24) 
    $History | ConvertTo-Json | Out-File -Append $File
    $History | Remove-AzTableRow -Table $HistoryTable

    # Delete web jobs host logs history
    #Get-AzStorageTable -Context $context -Name 'AzureWebJobsHostLogs*' | Remove-AzStorageTable -Force

}
catch {
    $_.exception | Out-File -Append $file
}

'=== END Durable Cleanup ===' | Out-File -Append $file
Write-Output 'Completed successfully'