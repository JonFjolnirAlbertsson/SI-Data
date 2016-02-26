Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\RestoreDBFromFile.ps1"
Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\SQL Rename Logical file.ps1"
Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\SQL change compatibility level.ps1"
Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\SQL Enable Broker.ps1"
Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\SQLSetServiceInstanceUserPermission.ps1"
Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\CreateNAVServerInstance.ps1"
Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\CreateNAVUser.ps1"

$dbName = "NAV2015_SIDataUpgradedAug"
$DBServer = "JALW8"
$BackupPath = "F:\SQL\Backup\SI-Data\UpgradeProcess\"
$NavServiceInstance = "NAV80SIDataUpgradeAug"
$FirstPort = 7830
$CompanyFolderName = "SI-Data NAV 2015"
$RootFolder = "C:\NAVUpgrade\$CompanyFolderName"
$LogPath = "$RootFolder\Logs\"
$LicensFile = "C:\Users\jal\OneDrive for Business\Files\SI-Data\License\SI-Data 06082015.flf"
$CompileLog = $LogPath + "compile"
$ImportLog = $LogPath + "import"
$ConversionLog = $LogPath + "Conversion"

$NAV2015APPObjects2Import = "$RootFolder\SI-Data NAV2015CU8 All Objects.fob"
$NAV2015UpgradeAPPObjects2Import = "$RootFolder\NAV 2015 CU8\Upgrade601800.NO.fob"
$NAV2015UpgradeAPPObjects2ChangedImport = "$RootFolder\NAV 2015 CU8\COD104049 NAV 2015CU8.fob"

$NAV2015ApplicationDataBackup = "C:\NAVUpgrade\SI-Data NAV 2015\NAV 2015 CU8\Data\si-data.navdata"

# Restore DB from Customer
$BackupFileName = "SI-Data2bUpgraded.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
RestoreDBFromFile -backupFile $BackupFilePath -dbNewname $dbName

#Import-NAVServerLicense -LicenseFile $LicensFile -ServerInstance $NavServiceInstance

# Step 1
$BackupFileName = $dbName + "_Step1.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default
#Step 2
$BackupFileName = $dbName + "_Step2.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default
#Step 3
$BackupFileName = $dbName + "_Step3.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default
#Step 4
$BackupFileName = $dbName + "_Step4.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default
#Step 5
$BackupFileName = $dbName + "_Step5.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default
#Step 6
$BackupFileName = $dbName + "_Step6.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default

# Before convert DB from 2009 to 2013 
ChangeDBCompatibilityLevel -DBName $dbName

# After converting to NAV 2013
$BackupFileName = $dbName + "_NAV2013.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default

#Convert Database to NAV 2015 CU8
Invoke-NAVDatabaseConversion -DatabaseName $dbName -DatabaseServer $DBServer -LogPath $ConversionLog

#Delete all objects excepts tables
Delete-NAVApplicationObject -DatabaseName $dbName -Filter 'Type=Codeunit|Page|Report|Query|XMLport|MenuSuite' 

# Compile system tables. Synchronize Schema option to Later.
$Filter = 'ID=2000000004..2000000130'
Compile-NAVApplicationObject -DatabaseName $dbName -Filter $Filter -LogPath $ImportLog -Recompile -SynchronizeSchemaChanges No

# NAV 2015
SetNAVServiceUserPermission -DBName $dbName -ADUser "NT-MYNDIGHET\NETTVERKSTJENESTE"
#EnableBroker -DBName $dbName
#CreateNAVServerInstance -DataBase $dbName -DBServer $DBServer -FirstPortNumber $FirstPort -NavServiceInstance $NavServiceInstance -PaWord 1378Nesbru -User si-data\sql
CreateNAVServerInstance -DataBase $dbName -DBServer $DBServer -FirstPortNumber $FirstPort -NavServiceInstance $NavServiceInstance

# Synchronize all tables from the Tools menu by selecting Sync. Schema for All Tables, then With Validation.
Sync-NAVTenant -ServerInstance $NavServiceInstance -Mode Sync

$BackupFileName = $dbName + "_Step8.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default

# Import Migrated NAV 2015 objects with SI-Data migrated objects. Synchronize Schema option to Later.
Import-NAVApplicationObject $NAV2015APPObjects2Import -DatabaseName $dbName -ImportAction Overwrite -SynchronizeSchemaChanges No -LogPath $ImportLog -Verbose
# Import Migrated NAV 2015 upgrade objects. Synchronize Schema option to Later.
Import-NAVApplicationObject $NAV2015UpgradeAPPObjects2Import -DatabaseName $dbName -ImportAction Overwrite -SynchronizeSchemaChanges No -LogPath $ImportLog -Verbose
# Import Migrated NAV 2015 upgrade objects. Synchronize Schema option to Later.
Import-NAVApplicationObject $NAV2015UpgradeAPPObjects2ChangedImport -DatabaseName $dbName -ImportAction Overwrite -SynchronizeSchemaChanges No -LogPath $ImportLog -Verbose

# Compile all objects which have not been compiled. Synchronize Schema option to Later.
#yes, no, 1, 0
$Filter = 'Compiled=0'
Compile-NAVApplicationObject -DatabaseName $dbName -Filter $Filter -LogPath $ImportLog -Recompile -SynchronizeSchemaChanges No

# Force compile of these tables
$Filter = 'ID=2000000004..2000000130'
Compile-NAVApplicationObject -DatabaseName $dbName -DatabaseServer $DBServer -NavServerName $DBServer -Filter $Filter -NavServerInstance $NavServiceInstance -NavServerManagementPort $FirstPort -Recompile -SynchronizeSchemaChanges Force

#Compile these object with force, we expect loss of this data.
$Filter = 'ID=27|39|123|125|470|471|700|10604'
Compile-NAVApplicationObject -DatabaseName $dbName -DatabaseServer $DBServer -NavServerName $DBServer -Filter $Filter -NavServerInstance $NavServiceInstance -NavServerManagementPort $FirstPort -Recompile -SynchronizeSchemaChanges Force

# Synchronize all tables from the Tools menu by selecting Sync. Schema for All Tables, then With Validation.
Sync-NAVTenant -ServerInstance $NavServiceInstance -Mode Sync
Sync-NAVTenant -ServerInstance $NavServiceInstance -Mode CheckOnly

$BackupFileName = $dbName + "_Step9.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default

# Start Data upgrade NAV 2015
Start-NAVDataUpgrade -ServerInstance $NavServiceInstance -FunctionExecutionMode Parallel
#Test purpose
Start-NAVDataUpgrade -ServerInstance $NavServiceInstance -FunctionExecutionMode Serial
#Resume-NAVDataUpgrade -CodeunitId 104055 -CompanyName "FilteruniQ AS" -FunctionName StartUPgrade -ServerInstance $NavServiceInstance


# Follow up the data upgrade process
Get-NAVDataUpgrade -ServerInstance $NavServiceInstance -Progress
Get-NAVDataUpgrade -ServerInstance $NavServiceInstance -Detailed | ogv
#Get-NAVDataUpgrade -ServerInstance $NavServiceInstance -Detailed | Out-File 
Get-NAVDataUpgrade -ServerInstance $NavServiceInstance -ErrorOnly | ogv

Resume-NAVDataUpgrade -ServerInstance $NavServiceInstance

# If NAV 2015 dataupgrade fails and you need to go back to the state before upgrade
<#
$BackupFileName = $dbName + "_Step9.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
RestoreDBFromFile -backupFile $BackupFilePath -dbNewname $dbName
#>

# Database backup with upgraded data
$BackupFileName = "NAV2015CU8_SIData.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default

# Database backup with upgraded data and Control Add-Ins
$BackupFileName = "NAV2015CU8_SIData_Finished.bak"
#$BackupFileName = "NAV2015CU1_Finished with OM.bak"
#$BackupFileName = "NAV2015CU1_Finished backup.bak"
$BackupFilePath = $BackupPath + $BackupFileName 
Backup-SqlDatabase -ServerInstance $DBServer -Database $dbName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default

# Import users, role and company
# Setup profiler for users.


#Export-NAVApplicationObject -DatabaseName $dbName -Path "C:\NAVUpgrade\SI-Data NAV 2015\NAV 2015 CU8\Data\si-data" -DatabaseServer $DBServer -LogPath "C:\NAVUpgrade\SI-Data NAV 2015\NAV 2015 CU8\Data\"
#Export-NAVData -CompanyName "SI-DATA København A/S" -FilePath $NAV2015ApplicationDataBackup -ServerInstance $NavServiceInstance -Description "SI-Data backup" -Force -IncludeApplication -IncludeApplicationData -IncludeGlobalData
Export-NAVData -AllCompanies -FilePath $NAV2015ApplicationDataBackup -ServerInstance $NavServiceInstance -Description "SI-Data backup" -Force -IncludeApplication -IncludeApplicationData -IncludeGlobalData

#Export-NAVData -AllCompaniesExport-NAVData -DatabaseName $dbName -FilePath $NAV2015ApplicationDataBackup -CompanyName "SI-DATA København A/S" -DatabaseServer $DBServer -IncludeApplication -IncludeApplicationData -IncludeGlobalData