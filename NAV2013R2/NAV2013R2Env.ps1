import-module "C:\Program Files\Microsoft Dynamics NAV\71\Service\Microsoft.Dynamics.Nav.Management.dll"   
Set-Location C:\Users\jal\Documents\NAV\Script\NAV2013R2\

#here we can (for ex.) add different coloring for different version, to avoid any confusion about what NAV version we’re working with
$host.UI.RawUI.BackgroundColor = “DarkRed”; $Host.UI.RawUI.ForegroundColor = “Gray”

#the below will clear the screen
Clear-Host

# Welcome message
Write-Host "Welcome to NAV 2013R2 Powershell: " + $env:Username
Write-Host "Dynamics NAV version 2013 R2 module imported"
