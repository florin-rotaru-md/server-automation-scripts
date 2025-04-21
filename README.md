# Server Automation Scripts

A collection of PowerShell scripts to quickly configure Windows Server 2022 for hosting modern web applications.

## 🎯 What It Does

The main script:

- Installs DNS Server and IIS with common features
- Installs .NET 8 Hosting Bundle
- Installs tools via Winget:
  - Visual Studio Code
  - Notepad++
  - PostgreSQL 17
  - pgAdmin 4

## ⚡ Quick Start

> Run this command in PowerShell (as Administrator):

```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/florin-rotaru-md/server-automation-scripts/main/001-setup.ps1') }"
