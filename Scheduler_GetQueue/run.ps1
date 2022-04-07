param($name)

$Tenants = Get-ChildItem 'Cache_Scheduler\*.json'

$object = foreach ($Tenant in $tenants) {
    $TypeFile = Get-Content "$($tenant)" | ConvertFrom-Json
    [pscustomobject]@{ 
        Tenant   = $Typefile.Tenant
        Tag      = 'SingleTenant'
        TenantID = $TypeFile.tenantId
        Type     = $Typefile.Type
    }
}


$object