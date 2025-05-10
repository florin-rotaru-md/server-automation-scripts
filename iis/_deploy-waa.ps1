.\deploy.ps1 `
  -repoUrl "https://github.com/florin-rotaru-md/Statics.git" `
  -repoBranch "develop" `
  -repoToken "" `
  -projectPath "Apps/Events/Events.Server/Events.Server.csproj" `
  -site "api.waa.ro" `
  -httpBinding "http:*:80:api.waa.ro"
