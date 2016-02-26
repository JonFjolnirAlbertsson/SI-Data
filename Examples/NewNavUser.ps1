$ADuser = "si-data\sql"
$ADuserSQL = "si-data\jal"
#$ADuser = "si-data\jab123243"
#$NavServiceInstance = "NAV80OSOUpgrade"
$NavServiceInstance = "DynamicsNAV90"

Set-ExecutionPolicy RemoteSigned -Force
##Import-Module "C:\Program Files\Microsoft Dynamics NAV\71\Service\NavAdminTool.ps1"

Get-NAVServerInstance $NavServiceInstance | New-NAVServerUser -WindowsAccount $ADuser 
Get-NAVServerInstance $NavServiceInstance | New-NAVServerUserPermissionSet –WindowsAccount $ADuser -PermissionSetId SUPER -Verbose

Get-NAVServerInstance $NavServiceInstance | New-NAVServerUser -WindowsAccount $ADuserSQL
Get-NAVServerInstance $NavServiceInstance | New-NAVServerUserPermissionSet –WindowsAccount $ADuserSQL -PermissionSetId SUPER -Verbose

Get-NAVServerUser $NavServiceInstance
Get-NAVServerUserPermissionSet -ServerInstance $NavServiceInstance

#New-NAVServerUserPermissionSet $NavServiceName –WindowsAccount $ADuserJAL -PermissionSetId SUPER -Verbose