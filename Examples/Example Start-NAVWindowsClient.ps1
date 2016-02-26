function Start-NAVWindowsClient
{
    [cmdletbinding()]
    param(
        [string]$DevEnvironment="80",
        [string]$ServerName, 
        [int]$Port, 
        [String]$ServerInstance, 
        [String]$Companyname, 
        [string]$tenant='default'
        )


    if ([string]::IsNullOrEmpty($Companyname)) {
       $Companyname = (Get-NAVCompany -ServerInstance $ServerInstance -Tenant $tenant)[0].CompanyName
    }
    $ProgramArgumentList = "DynamicsNAV://$Servername" + ":$Port/$ServerInstance/$MainCompany/?tenant=$tenant"
 
    if($DevEnvironment -eq "71")
    {
      $Program = "C:\Program Files (x86)\Microsoft Dynamics NAV\71\RoleTailored Client\Microsoft.Dynamics.Nav.Client.exe"      
       
    }
    
    Write-Verbose "Starting $Program $ProgramArgumentList..."
    Start-Process $Program -ArgumentList $ProgramArgumentList
    
}

Import-Module "C:\Users\jal\Documents\NAV\Script\StartingISENAV71.ps1"
$ServerName = "JALW8"
#Parma Plast
$NavServiceInstance = "NAV71ParmaPlast"
#$Version = '7.1*'
$Version = '8.*'

##SI-Data
#$NavServiceInstance = "NAV71SI-DataUpgrade"
#$ClientPort = "7171"
#$CompanyName = "SI-Data A/S"

Get-NAVServerInstance -ServerInstance $NavServiceInstance |  where-Object {($_.Version -like $Version) -And ($_.State –eq 'Running')} | Set-NAVServerInstance -Stop -Verbose
 
Get-NAVServerInstance -ServerInstance $NavServiceInstance |  where-Object {$_.Version -like $Version -And $_.State –eq 'Stopped'} | Set-NAVServerInstance -Start -Verbose

$DevEnv = "71"
$ClientPort = "7151"
Start-NAVWindowsClient -DevEnvironment $DevEnv -ServerName $ServerName -Port $ClientPort  -ServerInstance $NavServiceInstance -Companyname $CompanyName


