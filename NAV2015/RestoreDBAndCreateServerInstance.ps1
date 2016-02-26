Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\RestoreDBFromFile.ps1"
Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\CreateNAVServerInstance.ps1"
Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\SQLSetServiceInstanceUserPermission.ps1"
Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\CreateNAVUser.ps1"

$dbName = "NAV2009_OSO"
$DBServer = "JALW8"
$BackupPath = "F:\SQL\Backup\OSO\"
$BackupFileName = "NAV2009SP1_OSO_BeforeUpg.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
$NavServiceInstance = "NAV80_Spilka"
$FirstPort = 7870
$ADUser = "si-data\jal"

RestoreDBFromFile -backupFile $BackupFilePath -dbNewname $dbName

#CreateNAVServerInstance -DataBase $dbName -DBServer $DBServer -FirstPortNumber $FirstPort -NavServiceInstance $NavServiceInstance -PaWord 1378Nesbru -User si-data\sql
SetNAVServiceUserPermission -servername $DBServer -DBName $dbName
CreateNAVServerInstance -DataBase $dbName -DBServer $DBServer -FirstPortNumber $FirstPort -NavServiceInstance $NavServiceInstance
CreateNAVUser -NavServiceInstance $NavServiceInstance -User $ADUser