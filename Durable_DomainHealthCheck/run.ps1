param($QueuedRequest)

Write-Information 'PowerShell HTTP trigger function processed a request.'
#Write-Information ($Context | ConvertTo-Json)

if (Test-Path "Cache_DomainHealthQueue\$QueuedRequest") {
  $Cache = Get-Content "Cache_DomainHealthQueue\$QueuedRequest" | ConvertFrom-Json
  Remove-Item "Cache_DomainHealthQueue\$QueuedRequest" -Force

  $Query = $Cache.Query

  # Test connection to DNS resolver
  $Config = Get-Content .\Config\DnsConfig.json | ConvertFrom-Json
  if ($Config.Resolver -eq 'Google') { $DnsHost = 'dns.google' }
  elseif ($Config.Resolver -eq 'CloudFlare') { $DnsHost = 'cloudflare-dns.com' }

  $Retries = 0 
  do {
    $Connection = Test-Connection -TargetName $DnsHost -TcpPort 443
    Start-Sleep -Milliseconds 200
    $Retries++
  }
  while (!$Connection -or $Retries -ge 4)
  
  try {
    Import-Module .\DNSHelper.psm1
    if ($Query.Action) {
      if ($Query.Domain -match '^(((?!-))(xn--|_{1,1})?[a-z0-9-]{0,61}[a-z0-9]{1,1}\.)*(xn--)?([a-z0-9][a-z0-9\-]{0,60}|[a-z0-9-]{1,30}\.[a-z]{2,})$') {
        switch ($Query.Action) {
          'ReadSpfRecord' {
            $SpfQuery = @{
              Domain = $Query.Domain
            }

            if ($Query.ExpectedInclude) {
              $SpfQuery.ExpectedInclude = $Query.ExpectedInclude
            }

            if ($Query.Record) {
              $SpfQuery.Record = $Query.Record
            }

            $Body = Read-SpfRecord @SpfQuery
          }
          'ReadDmarcPolicy' {
            $Body = Read-DmarcPolicy -Domain $Query.Domain
          }
          'ReadDkimRecord' {
            $DkimQuery = @{
              Domain = $Query.Domain
            }
            if ($Query.Selector) {
              $DkimQuery.Selectors = ($Query.Selector).trim() -split '\s*,\s*'
            }
            $Body = Read-DkimRecord @DkimQuery
          }
          'ReadMXRecord' {
            $Body = Read-MXRecord -Domain $Query.Domain
          }
          'TestDNSSEC' {
            $Body = Test-DNSSEC -Domain $Query.Domain
          }
          'ReadWhoisRecord' {
            $Body = Read-WhoisRecord -Query $Query.Domain
          }
          'ReadNSRecord' {
            $Body = Read-NSRecord -Domain $Query.Domain
          }
          'TestHttpsCertificate' {
            $HttpsQuery = @{
              Domain = $Query.Domain
            }
            if ($Query.Subdomains) {
              $HttpsQuery.Subdomains = ($Query.Subdomains).trim() -split '\s*,\s*'
            }
            else {
              $HttpsQuery.Subdomains = 'www'
            }

            $Body = Test-HttpsCertificate @HttpsQuery
          }
          'TestMtaSts' {
            $HttpsQuery = @{
              Domain = $Query.Domain
            }
            $Body = Test-MtaSts @HttpsQuery
          }
        }
      }
      else {
        $body = [pscustomobject]@{'Results' = "Domain: $($Query.Domain) is invalid" }
      }
    }
  }
  catch {
    $errMessage = $_.Exception.Message
    $Body = [pscustomobject]@{'Results' = "$errMessage" }
  }
  New-Item 'Cache_DomainHealth' -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
  $Body | ConvertTo-Json -Depth 10 | Out-File "Cache_DomainHealth\$($QueuedRequest)"
}
