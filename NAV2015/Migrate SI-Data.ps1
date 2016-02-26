$dbName = "NAV2015CU8_SIData"
$DBServer = "JALW8"
$BackupPath = "F:\SQL\Backup\SI-Data\"
#$NavServiceInstance = "NAV80SIData"
$NavServiceInstance = "NAV80SIDataUpgrade"
$FirstPort = 7810
$CompanyFolderName = "SI-Data NAV 2015"
$RootFolderPath = "C:\NAVUpgrade\"
$LogPath = $RootFolderPath + $CompanyFolderName + "\Logs\"
$CompileLog = $LogPath + "compile"
$ImportLog = $LogPath + "import"
$ConversionLog = $LogPath + "Conversion"
$NAV2015APPObjects2Import = "C:\NAVUpgrade\SI-Data NAV 2015\Merged\all-merged-objects.txt"

$Merged = $RootFolderPath + $CompanyFolderName + "\Merged\"
$JoinSource = "C:\NAVUpgrade\SI-Data NAV 2015\Merged\ToBeJoined\"
$JoinDestination = $Merged + "all-merged-objects.txt"

Join-NAVApplicationObjectFile -Source $JoinSource -Destination $JoinDestination -Force

Import-NAVApplicationObject $NAV2015APPObjects2Import -DatabaseName $dbName -ImportAction Overwrite -SynchronizeSchemaChanges No -LogPath $ImportLog 

$Filter = 'Compiled=0'
Compile-NAVApplicationObject -DatabaseName $dbName -Filter $Filter -LogPath $ImportLog -Recompile -SynchronizeSchemaChanges No

Sync-NAVTenant -ServerInstance $NavServiceInstance -Mode Sync
