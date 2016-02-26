Import-Module "C:\Users\jal\Documents\NAV\Script\SQL Restore from file.ps1"

$BackupPath = "C:\SQL\Backup\Navision Demo\"
$BackupFileName = "Demo Database NAV (8-0) CU6.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
$dbName = "Demo Database NAV (8-0) CU6"
$NavServiceInstance = "DynamicsNAV80CU6"
$DBServer = "JALW8"
$FirstPort = 8050

# If NAV 2015 dataupgrade fails and you need to go back to the state before upgrade
RestoreDBFromFile -backupFile $BackupFilePath -dbNewname $dbName
RenameLogicalFileName -DBName $dbName
SetNAVServiceUserPermission -DBName $dbName
EnableBroker -DBName $dbName

CreateNAVServerInstance -DataBase $dbName -DBServer $DBServer -FirstPortNumber $FirstPort -NavServiceInstance $NavServiceInstance -PaWord Ennco.353 -User si-data\jal