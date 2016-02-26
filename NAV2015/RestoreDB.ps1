Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\RestoreDBFromFile.ps1"
$dbName = "NAV2015_Spilka"
$DBServer = "JALW8"
$BackupPath = "F:\SQL\Backup\Spilka\NAV2015_04112015\"
$BackupFileName = "NAV2015_04112015.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
RestoreDBFromFile -backupFile $BackupFilePath -dbNewname $dbName