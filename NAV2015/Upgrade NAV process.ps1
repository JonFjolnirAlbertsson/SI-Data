Import-Module "C:\Users\jal\Documents\NAV\Script\SQL Restore from file.ps1"
Import-Module "C:\Users\jal\Documents\NAV\Script\SQL change compatibility level.ps1"
Import-Module "C:\Users\jal\Documents\NAV\Script\SQL Enable Broker.ps1"
Import-Module "C:\Users\jal\Documents\NAV\Script\SQL Set Service instance user permission.ps1"
Import-Module "C:\Users\jal\Documents\NAV\Script\New-NAVServerInstance.ps1"
Import-Module "C:\Users\jal\Documents\NAV\Script\CreateNAVUser.ps1"

$dbName = "NAV2009_OSO_UpgradeToProd"
$DBServer = "JALW8"
#$BackupPath = "D:\SQL\Backup\OSO\"
$BackupPath = "C:\SQL\Backup\OSO\"
$NavServiceInstance = "NAV80OSOUpgrToProd"
$FirstPort = 8050
$LogPath = "C:\NavUpgrade\OSO\Logs\"
$CompileLog = $LogPath + "compile"
$ImportLog = $LogPath + "import"
$ConversionLog = $LogPath + "Conversion"
#$NAV2015APPObjects2Import = "C:\NavUpgrade\OSO\NAV2015CU1\All-Objects-2015CU1-included upgrade.fob"
$NAV2015APPObjects2Import = "C:\NavUpgrade\OSO\NAV2015CU1\OSO-AllObjects.fob"
$NAV2015UpgradeAPPObjects2Import = "C:\NavUpgrade\OSO\NAV2015CU1\Upgrade601800.NO.fob"
#$NAV2015OSOUpgradeAPPObjects2Import = "C:\NavUpgrade\OSO\NAV2015CU1\Upgrade\Hotfix Sales Header.fob"

# Restore DB from Customer
$dbName = "NAV2009SP1_OSO_BeforeProd"
$BackupFileName = "NAV2009SP1_OSO_BeforeUpg.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
RestoreDBFromFile -backupFile $BackupFilePath -dbNewname $dbName

# Step 1
$BackupFileName = "NAV2009SP1_OSO_Step1.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default
#Step 2
$BackupFileName = "NAV2009SP1_OSO_Step2.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default

# Before convert DB from 2009 to 2013 
ChangeDBCompatibilityLevel -DBName $dbName

# After converting to NAV 2013
$BackupFileName = "NAV2009SP1_OSO_NAV2013.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default

#Convert Database to NAV 2015 CU6
Invoke-NAVDatabaseConversion -DatabaseName $dbName -DatabaseServer $DBServer -LogPath $ConversionLog

# Compile system tables. Synchronize Schema option to Later.
$Filter = 'ID=2000000004..2000000130'
Compile-NAVApplicationObject -DatabaseName $dbName -Filter $Filter -LogPath $ImportLog -Recompile -SynchronizeSchemaChanges No

# NAV 2015
SetNAVServiceUserPermission -DBName $dbName
EnableBroker -DBName $dbName
CreateNAVServerInstance -DataBase $dbName -DBServer $DBServer -FirstPortNumber $FirstPort -NavServiceInstance $NavServiceInstance -PaWord 1378Nesbru -User si-data\sql

# Synchronize all tables from the Tools menu by selecting Sync. Schema for All Tables, then With Validation.
Sync-NAVTenant -ServerInstance $NavServiceInstance -Mode Sync

$BackupFileName = "NAV2009SP1_OSO_NAV2015_Step1.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default

# If NAV 2015 dataupgrade fails and you need to go back to the state before upgrade
<#
$BackupFileName = "NAV2009SP1_OSO_NAV2015_Step1.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
#$dbName = "NAV2013_OSO_Upgrade"
#$NavServiceInstance = "NAV2013_OSO_Upgrade"
#$FirstPort = 8055
RestoreDBFromFile -backupFile $BackupFilePath -dbNewname $dbName
SetNAVServiceUserPermission -DBName $dbName
#Remove-NAVServerInstance -ServerInstance $NavServiceInstance
#CreateNAVServerInstance -DataBase $dbName -DBServer $DBServer -FirstPortNumber $FirstPort -NavServiceInstance $NavServiceInstance -PaWord 1378Nesbru -User si-data\sql
#CreateNAVUser -NavServiceInstance $NavServiceInstance -User si-data\sql
#EnableBroker -DBName $dbName
#>

# Import Migrated NAV 2015 objects with OSO migrated objects. Synchronize Schema option to Later.
Import-NAVApplicationObject $NAV2015APPObjects2Import -DatabaseName $dbName -ImportAction Overwrite -SynchronizeSchemaChanges No -LogPath $ImportLog -Verbose
# Import Migrated NAV 2015 upgrade objects. Synchronize Schema option to Later.
Import-NAVApplicationObject $NAV2015UpgradeAPPObjects2Import -DatabaseName $dbName -ImportAction Overwrite -SynchronizeSchemaChanges No -LogPath $ImportLog -Verbose

# Compile all objects which have not been compiled. Synchronize Schema option to Later.
#yes, no, 1, 0
$Filter = 'Compiled=0'
Compile-NAVApplicationObject -DatabaseName $dbName -Filter $Filter -LogPath $ImportLog -Recompile -SynchronizeSchemaChanges No

# Force compile of these tables
$Filter = 'ID=2000000004..2000000130'
Compile-NAVApplicationObject -DatabaseName $dbName -DatabaseServer $DBServer -NavServerName $DBServer -Filter $Filter -NavServerInstance $NavServiceInstance -NavServerManagementPort $FirstPort -Recompile -SynchronizeSchemaChanges Force

#Compile these object with force, we expect loss of this data.
Compile-NAVApplicationObject -DatabaseName $dbName -DatabaseServer $DBServer -NavServerName $DBServer -Filter ID=50018 -NavServerInstance $NavServiceInstance -NavServerManagementPort $FirstPort -Recompile -SynchronizeSchemaChanges Force
Compile-NAVApplicationObject -DatabaseName $dbName -DatabaseServer $DBServer -NavServerName $DBServer -Filter ID=7013450 -NavServerInstance $NavServiceInstance -NavServerManagementPort $FirstPort -Recompile -SynchronizeSchemaChanges Force
Compile-NAVApplicationObject -DatabaseName $dbName -DatabaseServer $DBServer -NavServerName $DBServer -Filter ID=7013451 -NavServerInstance $NavServiceInstance -NavServerManagementPort $FirstPort -Recompile -SynchronizeSchemaChanges Force
Compile-NAVApplicationObject -DatabaseName $dbName -DatabaseServer $DBServer -NavServerName $DBServer -Filter ID=7013453 -NavServerInstance $NavServiceInstance -NavServerManagementPort $FirstPort -Recompile -SynchronizeSchemaChanges Force
Compile-NAVApplicationObject -DatabaseName $dbName -DatabaseServer $DBServer -NavServerName $DBServer -Filter ID=36 -NavServerInstance $NavServiceInstance -NavServerManagementPort $FirstPort -Recompile -SynchronizeSchemaChanges Force
Compile-NAVApplicationObject -DatabaseName $dbName -DatabaseServer $DBServer -NavServerName $DBServer -Filter ID=27 -NavServerInstance $NavServiceInstance -NavServerManagementPort $FirstPort -Recompile -SynchronizeSchemaChanges Force

# Synchronize all tables from the Tools menu by selecting Sync. Schema for All Tables, then With Validation.
Sync-NAVTenant -ServerInstance $NavServiceInstance -Mode Sync
Sync-NAVTenant -ServerInstance $NavServiceInstance -Mode CheckOnly

$BackupFileName = "NAV2009SP1_OSO_NAV2015_Step2.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default

# Start Data upgrade NAV 2015
Start-NAVDataUpgrade -ServerInstance $NavServiceInstance -FunctionExecutionMode Parallel
#Start-NAVDataUpgrade -ServerInstance $NavServiceInstance -FunctionExecutionMode Serial
#Resume-NAVDataUpgrade -CodeunitId 104055 -CompanyName "FilteruniQ AS" -FunctionName StartUPgrade -ServerInstance $NavServiceInstance

Resume-NAVDataUpgrade -ServerInstance $NavServiceInstance

# Follow up the data upgrade process
Get-NAVDataUpgrade -ServerInstance $NavServiceInstance -Progress
Get-NAVDataUpgrade -ServerInstance $NavServiceInstance -Detailed | ogv
#Get-NAVDataUpgrade -ServerInstance $NavServiceInstance -Detailed | Out-File 
Get-NAVDataUpgrade -ServerInstance $NavServiceInstance -ErrorOnly | ogv

# Database backup with upgraded data
$BackupFileName = "NAV2015CU1_OSO.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default

# Database backup with upgraded data and Control Add-Ins
$BackupFileName = "NAV2015CU1_OSO_Finished.bak"
#$BackupFileName = "NAV2015CU1_Finished with OM.bak"
#$BackupFileName = "NAV2015CU1_Finished backup.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default

# Import users, role and company




