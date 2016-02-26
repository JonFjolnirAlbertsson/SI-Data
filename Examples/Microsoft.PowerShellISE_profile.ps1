#Prepare PowerShell
Set-ExecutionPolicy RemoteSigned -Force

import-module "C:\Program Files\Microsoft Dynamics NAV\80\Service\Microsoft.Dynamics.Nav.Management.dll"   
Import-Module "C:\Program Files\Microsoft Dynamics NAV\80\Service\NavAdminTool.ps1"
Import-Module "${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\80\RoleTailored Client\Microsoft.Dynamics.Nav.Model.Tools.psd1" -force
#And any other modules we might use frequently (for ex. Azure module - requires having installed this in advance)
Import-module Azure
mport-Module ActiveDirectory

Set-Location C:\Users\jal\Documents\NAV\Script\NAV2015\

#here we can (for ex.) add different coloring for different version, to avoid any confusion about what NAV version we’re working with
$host.UI.RawUI.BackgroundColor = “DarkBlue”; $Host.UI.RawUI.ForegroundColor = “Yellow”

#the below will clear the screen
Clear-Host

# Welcome message
Write-Host "Welcome to NAV 2015 Powershell: " + $env:Username
Write-Host "Dynamics NAV version 2015 module imported"
