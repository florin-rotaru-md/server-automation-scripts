$testUrl = "https://api.waa.ro/.well-known/live"
$testHeaders = @{"Host" = "api.waa.ro:443" } 
Invoke-WebRequest -Uri $testUrl -Headers $testHeaders -TimeoutSec 7 -UseBasicParsing
