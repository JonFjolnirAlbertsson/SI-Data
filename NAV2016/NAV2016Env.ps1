#Prepare PowerShell
Set-ExecutionPolicy RemoteSigned -Force
$NAVVersion = "90"
$NAVVersionFolder = "NAV2016"
Import-module "C:\Program Files\Microsoft Dynamics NAV\$NAVVersion\Service\Microsoft.Dynamics.Nav.Management.dll"   
Import-Module "C:\Program Files\Microsoft Dynamics NAV\$NAVVersion\Service\NavAdminTool.ps1"
Import-Module "${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\$NAVVersion\RoleTailored Client\Microsoft.Dynamics.Nav.Model.Tools.psd1" -force -Verbose
#And any other modules we might use frequently (for ex. Azure module - requires having installed this in advance)
Import-module Azure
Import-Module ActiveDirectory

function Prompt { "$NAVVersionFolder $(Get-Location)>" }

Set-Location "C:\Users\$env:Username\OneDrive for Business\Files\NAV\Script\$NAVVersionFolder\"

#here we can (for ex.) add different coloring for different version, to avoid any confusion about what NAV version we’re working with
$host.UI.RawUI.BackgroundColor = “DarkBlue”; $Host.UI.RawUI.ForegroundColor = “Green”

#the below will clear the screen
Clear-Host

# Welcome message
Write-Host "Welcome to NAV $NAVVersionFolder Powershell: " $env:Username
Write-Host "Dynamics NAV version $NAVVersionFolder module imported"

#This script has to be run manually (F5 or the Run action).
