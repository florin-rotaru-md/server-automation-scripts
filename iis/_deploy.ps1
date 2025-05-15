. ".\Deploy-DotNetWebsite.ps1"

Deploy-DotNetWebsite `
  -RepoUrl "https://github.com/florin-rotaru-md/Statics.git" `
  -RepoBranch "master" `
  -RepoToken "ghp_***" `
  -ProjectPath "Apps/Waa/Waa.Server/Waa.Server.csproj" `
  -HostName "api.waa.ro" `
  -GreenHttpPort 8001 `
  -BlueHttpPort 8002 `
  -WacsValidationMethod "cloudflare-dns" `
  -WacsArgsCloudflarecredentials "C:\Program Files\Win-Acme\Tokens\clooudflare-global-api-key.txt" `
  -WacsArgsEmailAddress "rotaru.i.florin@outlook.com" `

