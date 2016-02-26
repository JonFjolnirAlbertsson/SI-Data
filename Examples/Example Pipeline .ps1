Get-NAVServerInstance
Get-NAVServerInstance | where-Object Version -like "7.1*”
Get-NAVServerInstance | where-Object  {$_.Version -like "7.1*”} | Sync-NAVTenant
Get-NAVServerInstance | where-Object  {$_.Version -like "7.1*”} | where-Object {$_.State –eq 'Running'} | Sync-NAVTenant
Get-NAVServerInstance | where-Object  {$_.Version -like "7.1*” -And $_.State –eq 'Running'} | Sync-NAVTenant

Get-NAVServerInstance | where-Object  {$_.Version -like "8.0*”} | where-Object {$_.State –eq 'Running'} 