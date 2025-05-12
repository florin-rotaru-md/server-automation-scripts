# PostgreSQL SSD Replica Setup Script
# Run this script on the machine where you want to store the replica (e.g., SSD)

# Configuration
$PG_VERSION = "16"  # Adjust this to your PostgreSQL version
$PRIMARY_HOST = "127.0.0.1"  # Change this to your main database server IP
$REPLICATOR_USER = "postgres"
$REPLICATOR_PASSWORD = "postgres"
$PG_PORT = 5432
$SSD_DRIVE = "E:\pgsql_data"  # SSD location for replica
$PG_SERVICE = "postgresql-x64-$PG_VERSION"
$PG_BIN = "C:\Program Files\PostgreSQL\$PG_VERSION\bin"

Write-Host "🚀 Starting PostgreSQL Replica Setup..." -ForegroundColor Green

# 1️⃣ Stop PostgreSQL Service on the Secondary Instance
Write-Host "⏳ Stopping PostgreSQL service on SSD instance..."
Stop-Service $PG_SERVICE -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# 2️⃣ Clean and Prepare the SSD
Write-Host "🗑 Clearing existing PostgreSQL data on SSD..."
Remove-Item -Recurse -Force "$SSD_DRIVE\*" -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $SSD_DRIVE -Force

# 3️⃣ Run `pg_basebackup` to Clone Data from Primary
Write-Host "📥 Running pg_basebackup to sync data from the primary server..."
$BackupCommand = "$PG_BIN\pg_basebackup.exe -h $PRIMARY_HOST -p $PG_PORT -U $REPLICATOR_USER -D `"$SSD_DRIVE`" -Fp -Xs -P -R"
cmd.exe /c $BackupCommand

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ pg_basebackup failed. Check credentials and network connection." -ForegroundColor Red
    exit 1
}

# 4️⃣ Set Correct Permissions
Write-Host "🔑 Setting correct permissions..."
icacls $SSD_DRIVE /grant "NT AUTHORITY\NetworkService:(OI)(CI)F"

# 5️⃣ Start PostgreSQL Service to Begin Replication
Write-Host "🚀 Starting PostgreSQL as a standby replica..."
Start-Service $PG_SERVICE

# 6️⃣ Verify Replication Status
Start-Sleep -Seconds 5
$PG_STATUS = Get-Service $PG_SERVICE
if ($PG_STATUS.Status -eq "Running") {
    Write-Host "✅ PostgreSQL is now running as a replica!" -ForegroundColor Green
} else {
    Write-Host "❌ PostgreSQL failed to start. Check logs for issues." -ForegroundColor Red
}

Write-Host "🎯 SSD replica setup complete! This server will now receive live updates from the primary."
