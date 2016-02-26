$SQLServer = "JALW8"
#$DatabaseName = "Bilutstyr2013R2"
#$DatabaseName = "NAV2009SP1_OSO_BeforeUpg"
#$BackupFilePath = "E:\SQL\Backup\Bilutstyr\$DatabaseName.bak"
#$BackupFilePath = "C:\SQL\Backup\OSO\$DatabaseName.bak"

$DatabaseName = "NAV2009SP1_OSO_Upgrade"
$BackupPath = "E:\SQL\Backup\OSO\"
$BackupFileName = "NAV2009SP1_OSO_NAV2013.bak"
$BackupFilePath = $BackupPath + $BackupFileName 


Backup-SqlDatabase -ServerInstance $SQLServer -Database $DatabaseName -BackupAction Database -BackupFile $BackupFilePath -CompressionOption Default
