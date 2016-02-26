Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\SQLSetServiceInstanceUserPermission.ps1"
Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\CreateNAVServerInstance.ps1"
Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\CreateNAVUser.ps1"

$dbName = "NAV2013R2_ParmaPlast"
$DBServer = "JALW8"
$NavServiceInstance = "NAV80ParmaPlast"
$FirstPort = 7110
$ADUser = "SI-Data\JAL"

# NAV 2013 R2
SetNAVServiceUserPermission -DBName $dbName -ADUser "NT-MYNDIGHET\NETTVERKSTJENESTE"
CreateNAVServerInstance -DataBase $dbName -DBServer $DBServer -FirstPortNumber $FirstPort -NavServiceInstance $NavServiceInstance
CreateNAVUser -User $ADUser -NavServiceInstance $NavServiceInstance

#Sync-NAVTenant -ServerInstance $NavServiceInstance