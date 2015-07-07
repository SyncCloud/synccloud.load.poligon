<powershell>
$ErrorActionPreference = "Stop"
Add-Type -Assembly "System.IO.Compression.FileSystem"

#Installing Monitor agent
$s3DbFileKey = Get-S3Object -BucketName site-dbbackup | Select-Object -Property key -first 1 | Select -ExpandProperty 'Key'
$dbBackupDir = 'Z:\'
$dbZip = Join-Path $dbBackupDir $s3DbFileKey
Read-S3Object -BucketName 'site-dbbackup' -Key $s3DbFileKey -File $dbZip
[System.IO.Compression.ZipFile]::ExtractToDirectory($dbZip, $dbBackupDir)
Remove-Item $dbZip
$bakFile = Join-Path $dbBackupDir "Site.bak"

#Configure SQL Server
Import-Module SQLPS -DisableNameChecking

# Connect to the instance using SMO
$s = new-object ('Microsoft.SqlServer.Management.Smo.Server') '.'
[string]$nm = $s.Name
[string]$mode = $s.Settings.LoginMode

write-output "Instance Name: $nm"
write-output "Login Mode: $mode"

#Change to Mixed Mode
$s.Settings.LoginMode = [Microsoft.SqlServer.Management.SMO.ServerLoginMode]::Mixed
$user = $s.Logins['sa']
$user.PasswordPolicyEnforced = 0
$user.Alter()
$user.ChangePassword("111222")
$user.Enable()
$user.Alter()
$user.Refresh()

#Make the changes
$s.Alter()

Restart-Service -Name mssqlserver -f

$dbName = 'SiteTest'
# Get the default file and log locations
# (If DefaultFile and DefaultLog are empty, use the MasterDBPath and MasterDBLogPath values)
$fileloc = $s.Settings.DefaultFile
$logloc = $s.Settings.DefaultLog
if ($fileloc.Length -eq 0) {
    $fileloc = $s.Information.MasterDBPath
}
if ($logloc.Length -eq 0) {
    $logloc = $s.Information.MasterDBLogPath
}
 

# Build the physical file names for the database copy
$dbfile = $fileloc + '\'+ $dbname + '_Data.mdf'
$logfile = $logloc + '\'+ $dbname + '_Log.ldf'

# Use the backup file name to create the backup device
$bdi = new-object ('Microsoft.SqlServer.Management.Smo.BackupDeviceItem') ($bakFile, 'File')
 
# Create the new restore object, set the database name and add the backup device
$rs = new-object('Microsoft.SqlServer.Management.Smo.Restore')
$rs.Database = $dbName
$rs.Devices.Add($bdi)
 
# Get the file list info from the backup file
$fl = $rs.ReadFileList($s)
foreach ($fil in $fl) {
    $rsfile = new-object('Microsoft.SqlServer.Management.Smo.RelocateFile')
    $rsfile.LogicalFileName = $fil.LogicalName
    if ($fil.Type -eq 'D'){
        $rsfile.PhysicalFileName = $dbfile
    }
    else {
        $rsfile.PhysicalFileName = $logfile
    }
    $rs.RelocateFiles.Add($rsfile)
}
    
Write-Host "Restoring $dbName from backup"
$rs.SqlRestore($s)
Write-Host "Removing backup file"
Remove-Item $bakFile

#Drop passwords
$s.Databases[$dbName].ExecuteNonQuery(@"
DECLARE @pass nvarchar(max), @salt nvarchar(max);

select @pass=Password, @salt=PasswordSalt
    from aspnet_Membership m
        join Employers e on UserId=ID_User
    where ID_Employee=25

update aspnet_Membership
    set [Password]=@pass,
        PasswordSalt=@salt
"@)

</powershell>