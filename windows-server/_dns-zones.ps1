$zones = @(
    "buyout.ro",
    "cek.ro",
    "educa.ro",
    "educate.ro",
    "dropit.ro",
#    "waa.ro",
    "statics.ro"
)

$ipAddress = "82.76.211.67"
$nameServer = "ns.statics.ro"

$nsZone = $nameServer.Replace("ns.", "")

# SOA config
$soaRefresh = 3600      # 1 hour
$soaRetry = 480         # 8 minutes
$soaExpire = 1382400    # 16 days
$soaMinimumTTL = 3600   # 1 hour
# $recordTTL = 86400      # 1 day

foreach ($zone in $zones) {
    Write-Host "Configuring zone: $zone" -ForegroundColor Cyan

    $zoneExists = Get-DnsServerZone -Name $zone -ErrorAction SilentlyContinue

    if ($zoneExists) {
        Remove-DnsServerZone -Name $zone -Force
    }

    Add-DnsServerPrimaryZone -Name $zone -ZoneFile "$zone.dns" -DynamicUpdate None

    # Disable scavenging (opțional)
    # Set-DnsServerZoneAging -Name $zone -AgingEnabled $false

    # SOA
    $soaRecord = Get-DnsServerResourceRecord -ZoneName $zone -RRType "SOA" -ErrorAction SilentlyContinue
    $newSoaRecord = [ciminstance]::new($soaRecord)
    $newSoaRecord.RecordData.SerialNumber = (Get-Date -Format "yyyyMMdd01").ToString()
    if ($zone -eq $nsZone) {
        $newSoaRecord.RecordData.PrimaryServer = $ipAddress
    }
    else {
        $newSoaRecord.RecordData.PrimaryServer = $nameServer
    }
    $newSoaRecord.RecordData.RefreshInterval = [TimeSpan]::FromSeconds($soaRefresh)
    $newSoaRecord.RecordData.RetryDelay = [TimeSpan]::FromSeconds($soaRetry)
    $newSoaRecord.RecordData.ExpireLimit = [TimeSpan]::FromSeconds($soaExpire)
    $newSoaRecord.RecordData.MinimumTimeToLive = [TimeSpan]::FromSeconds($soaMinimumTTL)
    
    Set-DnsServerResourceRecord -ZoneName $zone -OldInputObject $soaRecord -NewInputObject $newSoaRecord -PassThru

    if ($zone -eq $nsZone) {
        Add-DnsServerResourceRecordA -Name "ns" -ZoneName $zone -IPv4Address $ipAddress
    }

    $nsRecord = Get-DnsServerResourceRecord -ZoneName $zone -RRType "NS" -ErrorAction SilentlyContinue
    $newNsRecord = [ciminstance]::new($nsRecord)
    $newNsRecord.RecordData.NameServer = $nameServer

    Set-DnsServerResourceRecord -ZoneName $zone -OldInputObject $nsRecord -NewInputObject $newNsRecord -PassThru

    # A record for domain (@)
    Add-DnsServerResourceRecordA -Name "@" -ZoneName $zone -IPv4Address $ipAddress
    
    # A record for *
    Add-DnsServerResourceRecordA -Name "*" -ZoneName $zone -IPv4Address $ipAddress
        
    # www CNAME → @
    Add-DnsServerResourceRecordCName -Name "www" -ZoneName $zone -HostNameAlias "$zone."
}

Write-Host "DNS zone configuration complete."