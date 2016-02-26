#Restoring database from .bak file
#$restoreFile = 'C:\SQL\Backup\Navision Demo\Demo Database NAV (6-0-NO-SP1) (6.0.30609).bak'
#$restoreFile = 'C:\SQL\Backup\Navision Demo\Demo Database NAV (6-0).bak'
#$restoreFile = 'C:\SQL\Backup\Navision Demo\Demo Database NAV (7-0).bak'
#$restoreFile = 'C:\SQL\Backup\Navision Demo\Demo Database NAV (8-0) CU1.bak'
#$restoreFile = 'C:\SQL\Backup\OSO\NAV2009SP1_OSO.bak'
#$restoreFile = 'C:\SQL\Backup\OSO\NAV2009SP12015_03_23.bak'
$restoreFile = "C:\SQL\Backup\OSO\NAV2009SP1_OSO_BeforeUpg.bak"

#$NewDBName = 'NAV2009R2_OSO'
#$NewDBName = 'NAV2013CU18_UpgradeDB'
#$NewDBName = 'Demo Database NAV (8-0)'
#$NewDBName = 'NAV2015CU1_OSO_Upgrade'
#$NewDBName = 'NAV2009SP1_OSO'
$NewDBName = 'NAV2009SP1_OSO_Upgrade'
#$NewDBName = 'Demo Database NAV (6-0-NO-SP1)'

#Paths for MSSQL 12
$destPath = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA'
$dataFile = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\' + $NewDBName +'.mdf'
$logFile = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\' + $NewDBName +'.ldf'

#New-NavDatabase C:\SQL\Backup\ParmaPlast_Nav2013.bak –DatabaseName NewDatabase1 –Verbose | fl
#New-NavDatabase $restoreFile –DatabaseName $NewDBName -DataFilesDestinationPath $dataFile -LogFilesDestinationPath $logFile –Verbose | fl
#If there are more than one data file in the backup use this
New-NavDatabase $restoreFile –DatabaseName $NewDBName -DataFilesDestinationPath $destPath -LogFilesDestinationPath $destPath -Timeout 6000 –Verbose | fl

#Remember to rename Locical Name of the Database files in Studio Manager. They will get the name from the .bak file.