<powershell>
$appVersion = '1.6.1'
$connString = 'abaab'
$siteDir = 'C:\inetpub\wwwroot'
#Copy app package from S3 and deploy to IIS
Remove-Item -Recurse -Force "$siteDir\*"
$appZip = "$siteDir\app.zip"
Read-S3Object -BucketName 'synccloud-deployments' -Key "SyncCloud.Backend/$appVersion.zip" -File $appZip
[System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
[System.IO.Compression.ZipFile]::ExtractToDirectory($appZip, $siteDir)
Remove-Item $appZip

# Resetting IIS
$Command = "IISRESET"
Invoke-Expression -Command $Command

#Installing Monitor agent
$monitorDir = 'C:\services\WindowsStatsToGraphite'
$monitorZip = 'C:\services\WindowsStatsToGraphite.zip'
Read-S3Object -BucketName 'synccloud-deployments' -Key "WindowsStatsToGraphite.zip" -File $monitorZip
[System.IO.Compression.ZipFile]::ExtractToDirectory($monitorZip, $monitorDir)
sleep 2
Start-Process -NoNewWindow C:\services\WindowsStatsToGraphite\PerfCounters.exe 'one_sec.yandex_tank.backend'
Remove-Item $monitorZip

#Update connection string
$webConfig = Join-Path $siteDir 'Web.config'
$doc = New-Object System.Xml.XmlDocument
$doc.Load($webConfig)
$dbStringNode = $doc.SelectSingleNode("//configuration/connectionStrings/add[@name='DB_CONNECTION_STRING']")
$dbStringNode.setAttribute('connectionString', $connString)
$doc.Save($webConfig)
</powershell>