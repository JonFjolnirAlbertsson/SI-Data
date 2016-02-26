$ServerName = "JALW8"
#$NavServiceInstance = "NAV71ParmaPlast"
$NavServiceInstance = "NAV71ParmaPlast"
#$Version = '7.1*'
$Version = '8.0*'


if(([string]::Equals($Version, "7.1")) -or ($Version -eq "71")-or ($Version -eq "7.1*"))
{
    Import-Module "C:\Users\jal\Documents\NAV\Script\StartingISENAV71.ps1"  
}
if(([string]::Equals($Version, "8.0")) -or ($Version -eq "80")-or ($Version -like '8.0*'))
{
    Import-Module "C:\Users\jal\Documents\NAV\Script\StartingISENAV80.ps1" 
}    

#Get-NAVServerInstance -ServerInstance $NavServiceInstance |  where-Object {($_.Version -like $Version) -And ($_.State –eq 'Running')} | Set-NAVServerInstance -Stop -Verbose
#Get-NAVServerInstance -ServerInstance $NavServiceInstance |  where-Object {$_.Version -like $Version -And $_.State –eq 'Stopped'} | Set-NAVServerInstance -Start -Verbose

Get-NAVServerInstance |  where-Object {($_.Version -like $Version) -And ($_.State –eq 'Running')} | Set-NAVServerInstance -Stop -Verbose 
Get-NAVServerInstance |  where-Object {$_.Version -like $Version -And $_.State –eq 'Stopped'} | Set-NAVServerInstance -Start -Verbose


