# PostgreSQL Failover Automation Script
# Run this script as Administrator on the new machine

# Configuration
$PG_VERSION = "16"  # Adjust to your PostgreSQL version
$SSD_DRIVE = "E:\pgsql_data"  # Location of SSD PostgreSQL data
$PG_DATA = "C:\Program Files\PostgreSQL\$PG_VERSION\data"
$PG_SERVICE = "postgresql-x64-$PG_VERSION"

Write-Host "🚀 Starting PostgreSQL Failover Process..." -ForegroundColor Green

# 1️⃣ Stop PostgreSQL Service
Write-Host "⏳ Stopping PostgreSQL service..."
Stop-Service $PG_SERVICE -Force
Start-Sleep -Seconds 3

# 2️⃣ Copy Data from SSD to Local Machine
Write-Host "📂 Copying PostgreSQL data from SSD..."
Remove-Item -Recurse -Force $PG_DATA  # Remove existing data directory (if needed)
Copy-Item -Path "$SSD_DRIVE\*" -Destination $PG_DATA -Recurse -Force

# 3️⃣ Fix Permissions (Ensure Postgres Service Can Access the Data)
Write-Host "🔑 Fixing permissions..."
icacls $PG_DATA /grant "NT AUTHORITY\NetworkService:(OI)(CI)F"

# 4️⃣ Promote the Replica to Primary
Write-Host "📌 Promoting replica to primary..."
Remove-Item "$PG_DATA\standby.signal" -ErrorAction SilentlyContinue
New-Item -Path "$PG_DATA\recovery.signal" -ItemType File -Force

# 5️⃣ Start PostgreSQL Service
Write-Host "🚀 Starting PostgreSQL..."
Start-Service $PG_SERVICE
Start-Sleep -Seconds 5

# 6️⃣ Verify PostgreSQL Status
$PG_STATUS = Get-Service $PG_SERVICE
if ($PG_STATUS.Status -eq "Running") {
    Write-Host "✅ PostgreSQL is now running as the primary instance!" -ForegroundColor Green
} else {
    Write-Host "❌ PostgreSQL failed to start. Check logs for issues." -ForegroundColor Red
}

Write-Host "🎯 Failover Complete! Update your applications to use the new database server."
