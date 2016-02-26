$RemoteServer = "SQL02"
Get-Service -ComputerName $RemoteServer # shows you Windows services on [MyServerName]

Invoke-Command -ComputerName $RemoteServer `
   -ScriptBlock {Import-Module 'C:\Program Files\Microsoft Dynamics NAV\80\Service\Microsoft.Dynamics.Nav.Management.dll' `
   ; Get-NAVServerInstance | Format-Table -AutoSize}


   Import-Module 'C:\Program Files\Microsoft Dynamics NAV\80\Service\Microsoft.Dynamics.Nav.Management.dll'
  Get-NAVServerInstance | Format-Table -AutoSize


  Test-connection -ComputerName $RemoteServer
Test-wsman -ComputerName $RemoteServer

Enable-PSRemoting
