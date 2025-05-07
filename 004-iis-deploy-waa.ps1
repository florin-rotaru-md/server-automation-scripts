.\004-iis-deploy.ps1 `
  -repoUrl "https://github.com/florin-rotaru-md/Statics.git" `
  -repoBranch "master" `
  -repoToken "" `
  -repoLocalRootPath "C:\deploy\repos" `
  -projectPath "Apps/Events/Events.Server/Events.Server.csproj" `
  -blueRootPath "C:\deploy\blue" `
  -greenRootPath "C:\inetpub\sites" `
  -siteName "api.waa.ro" `
  -httpBinding "api.waa.ro" `
