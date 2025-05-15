. ".\Deploy-DotNetWebsite.ps1"

Deploy-DotNetWebsite `
  -RepoUrl "https://github.com/florin-rotaru-md/Statics.git" `
  -RepoBranch "develop" `
  -RepoToken "ghp_***" `
  -ProjectPath "Apps/Waa/Waa.Server/Waa.Server.csproj" `
  -HostName "dev.waa.ro" `
  -GreenHttpPort 8001 `
  -BlueHttpPort 8002 `
  -WacsValidationMethod "cloudflare-dns" `
  -WacsArgsCloudflareTokenPath "C:\Program Files\Win-Acme\Tokens\clooudflare-zone-dns-waa.ro.txt" `
  -WacsArgsEmailAddress "rotaru.i.florin@outlook.com" `

