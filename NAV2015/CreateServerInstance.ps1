Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\CreateNAVServerInstance.ps1"
Import-Module "C:\Users\jal\OneDrive for Business\Files\NAV\Script\Function\CreateNAVUser.ps1"

$dbName = "NAV2015CU8_SIData"
$DBServer = "SQL02"
$NavServiceInstance = "NAV2015_SIData_SQL"
$FirstPort = 7860

CreateNAVServerInstance -DataBase $dbName -DBServer $DBServer -FirstPortNumber $FirstPort -NavServiceInstance $NavServiceInstance -PaWord 1378Nesbru -User si-data\sql
#CreateNAVServerInstance -DataBase $dbName -DBServer $DBServer -FirstPortNumber $FirstPort -NavServiceInstance $NavServiceInstance