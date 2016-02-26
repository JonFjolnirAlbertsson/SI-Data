Invoke-SQLCmd -Query "sp_databases" -Database master -ServerInstance JALW8 | Out-GridView
Get-ChildItem | select Name, Size, SpaceAvailable, DataSpaceUsage, IndexSpaceUsage | Format-Table
$AdvWks = Get-Item NAV2009SP1_OSO_Test2 
$AdvWks | Get-Member -MemberType Property 

$Server="JALW8"            

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | out-null
$SMOserver = New-Object ('Microsoft.SqlServer.Management.Smo.Server') -argumentlist $Server
$SMOserver.Databases | select Name, Size, DataSpaceUsage, IndexSpaceUsage, SpaceAvailable | Format-Table


Invoke-Sqlcmd -Query "SELECT * FROM HumanResources.Department;" –Database “AdventureWorks2012”
