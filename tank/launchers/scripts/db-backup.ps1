Import-Module SQLPS -DisableNameChecking
sleep 1

$now = Get-Date -format yyyy-MM-dd-hh-mm
$dbName = 'Site'
$backupDir = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup'
$bckFileDir = Join-Path $backupDir $now
New-Item -Path $bckFileDir -ItemType Directory
$bckfile = Join-Path $bckFileDir "$dbName.bak"
$zipFile = Join-Path $backupDir "$now.zip"
Write-Host "Creating backup"
Backup-SqlDatabase -Database $dbName -BackupFile $bckfile  -ServerInstance '.'
Add-Type -Assembly "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($bckFileDir, $zipFile)

Write-Host "Uploading to S3"
Write-S3Object -File $zipFile -BucketName 'site-dbbackup' -Key "$now.zip"

Remove-Item $bckFileDir -Force -Recurse
Remove-Item $zipFile