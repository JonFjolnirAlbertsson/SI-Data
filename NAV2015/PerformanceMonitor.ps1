Import-Module 'C:\Program Files\Microsoft Dynamics NAV\80\Service\Microsoft.Dynamics.Nav.Management.dll'
Set-NAVServerConfiguration DynamicsNAV80 -KeyName EnableFullALFunctionTracing -KeyValue "true"
Set-NAVServerInstance DynamicsNAV80 -Restart

$datacollectorset = New-Object -COM Pla.DataCollectorSet
$TemplateFile = 'C:\temp\NAVAppProfiler.xml'

$xml = Get-Content $TemplateFile
 $DataCollectorName = 'Microsoft Dynamics NAV Server Performance Monitor'
 $datacollectorset.SetXml($xml)
 $datacollectorset.Commit("$DataCollectorName",$null, 0x0003) | Out-Null
 
 #After creating the data collector, it will take some seconds before it is ready to start it
 do
 {
   $datacollectorset.start($false)
   sleep(3)
   Write-Host "Starting trace ..."
 }
 while ($datacollectorset.Status -eq 0)
 $datacollectorset.Status

#To stop the trace:
$datacollectorset.Stop($false)
#To remove the data collector set:
$datacollectorset.Delete()