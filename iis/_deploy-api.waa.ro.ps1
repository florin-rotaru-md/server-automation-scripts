. ".\Deploy-DotNetWebsite.ps1"

Deploy-DotNetWebsite `
  -RepoUrl "https://github.com/florin-rotaru-md/Statics.git" `
  -RepoBranch "master" `
  -RepoToken "ghp_***" `
  -ProjectPath "Apps/Waa/Waa.Server/Waa.Server.csproj" `
  -HostName "api.waa.ro" `
  -GreenHttpPort 8001 `
  -BlueHttpPort 8002 `
  -CCSConfigFile "C:\config\ccs.json" `
  -WacsValidationMethod "cloudflare-dns" `
  -WacsArgsCloudflareTokenPath "C:\config\tokens\clooudflare-zone-dns-waa.ro.txt" `
  -WacsArgsEmailAddress "rotaru.i.florin@outlook.com" `
