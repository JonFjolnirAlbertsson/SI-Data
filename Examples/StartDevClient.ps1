function Start-NAVWindowsDevClient
{
    [cmdletbinding()]
    param(
        [string]$DevEnvironment = ""
        )
    $Databasename = $DevEnvironment
    if(([string]::Equals($DevEnvironment, "1")) -or ($DevEnvironment -eq "SIData2Upgrade"))
    {
      $Databasename = "NAV50_SIData2Upgrade"
    }     
    $Program = "C:\Program Files (x86)\Microsoft Dynamics NAV\71\RoleTailored Client\finsql.exe"
    if ([string]::IsNullOrEmpty($DevEnvironment)) 
    {
       $Databasename = "Demo Database NAV (7-1)"              
    }

    $ProgramArgumentList = "SERVERNAME=jalw8, DATABASE=$Databasename, NTAUTHENTICATION=1, id=C:\temp\$Databasename.zup"
   
    Write-Verbose "Starting $Program $ProgramArgumentList..."
    Start-Process $Program -ArgumentList $ProgramArgumentList
}

#Get-NAVServerConfiguration -ServerInstance DynamicsNAV71
$ServiceInstance = "NAV71ParmaPlast"
Get-NAVServerConfiguration -ServerInstance $ServiceInstance 
Start-NAVWindowsDevClient -Verbose
Start-NAVWindowsDevClient -DevEnvironment "NAV50_SIData2Upgrade" -Verbose
Start-NAVWindowsDevClient -DevEnvironment 1
Start-NAVWindowsDevClient -DevEnvironment SIData2Upgrade
Start-NAVWindowsDevClient -DevEnvironment NAV71_ParmaPlast 

