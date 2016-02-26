$serviceName = "MicrosoftDynamicsNAVServer$Otrum"
$DisplayName = "Microsoft Dynamics NAV Server Otrum" 
$Desc = "Test service for local machine" 
 
if (Get-Service $serviceName -ErrorAction SilentlyContinue)
{
    $serviceToRemove = Get-WmiObject -Class Win32_Service -Filter "name='$serviceName'"
    $serviceToRemove.delete()
    "service removed"
}
else
{
    "service does not exists"
}
 
"installing service"
 
$secpasswd = ConvertTo-SecureString "1378Nesbru" -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ("si-data\sql", $secpasswd)
$binaryPath = "C:\Program Files (x86)\Microsoft Dynamics NAV\60\Service Otrum\Microsoft.Dynamics.Nav.Server.exe $Otrum"
New-Service -name $serviceName -binaryPathName $binaryPath -displayName $DisplayName -Description $Desc -startupType Automatic -credential $mycreds
 
"installation completed"

