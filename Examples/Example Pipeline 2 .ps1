import-module 'C:\Program Files\Microsoft Dynamics NAV\71\Service\Microsoft.Dynamics.Nav.Management.dll'
Get-NAVServerInstance 
Get-NAVServerInstance | Format-Table
Get-NAVServerInstance | Format-Table -AutoSize
Get-NAVServerInstance | Select-Object ServerInstance, State
Get-NavServerInstance | Get-Member
Get-NAVServerInstance | Select-Object ServerInstance, State | Format-List
Get-NAVServerInstance | Select-Object ServerInstance, State, Version | Format-Table


Get-NAVServerInstance | where-Object  {$_.Version -like "8.0*”} | Select-Object ServerInstance, State, Version | Format-Table