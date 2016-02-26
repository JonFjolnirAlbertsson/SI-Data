#Load NAV remote admin from the product DVD
Import-Module "C:\Users\jal\Documents\Microsoft\Navision 2015\NAV2015CU4\DVD\WindowsPowerShellScripts\Cloud\NAVRemoteAdministration\NAVRemoteAdministration.psm1"

#Before continuing lets just stop and check what the NAVRemoteAdministration module contains:
get-command -module NAVRemoteAdministration
#What we will use first, is New-NAVAdminSession but also notice functions like Copy-FileToRemoteMachine, Get-NAVServerUserRemotely, New-NAVServerInstanceRemotely and Start-ServiceRemotely. We're sure you can imagine how useful these can be. But first we need to create a session object that we can use to connect: Make sure that the VM you refer to exists and is running, and that service and machine names are the same:

$PsSession = New-NAVAdminSession -RemoteMachineAddress "JALDev" -AzureServiceName "JALNAV2015Dev" -VMAdminUserName "jal" -VMAdminPassword "Ennco.357"

$AzureImageName = "9a03679de0e64e0e94fb8d7fd3c72ff1__Dynamics-NAV-2015-RTM-201502NB.02-127GB"
$pwd = "1378Nesbru"
$un = "si-data"
New-AzureVMConfig -Name "VMJALNAV2015DEV" -InstanceSize "Small" -Image $AzureImageName | Add-AzureProvisioningConfig -Windows -AdminUserName $un -Password $pwd | New-AzureVM -ServiceName "VMJALNAV2015DEV" -Location "West Europe"
