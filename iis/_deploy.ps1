. ".\Deploy-DotNetWebsite.ps1"

Deploy-DotNetWebsite `
  -RepoUrl "https://github.com/florin-rotaru-md/Statics.git" `
  -RepoBranch "develop" `
  -RepoToken "ghp_***" `
  -ProjectPath "Apps/Events/Events.Server/Events.Server.csproj" `
  -HostName "api.waa.ro" 
