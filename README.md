# Server Automation Scripts

A collection of PowerShell scripts to quickly configure Windows Server 2022 for hosting modern web applications.

## 🎯 What It Does

The main script:

- Installs 
  - DNS Server and IIS with common features
  - Git SCM
  - Handle
  - Win-Acme
  - .NET 8 SDK
  - .NET 8 Hosting Bundle
  - Visual Studio Code
  - Notepad++
  - PostgreSQL 17
  - pgAdmin 4

## ⚡ Quick Start

> Run this command in PowerShell (as Administrator):

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/florin-rotaru-md/server-automation-scripts/main/{script}.ps1') }"
