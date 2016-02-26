#Prepare PowerShell
#This script is used by the migrate script
Set-ExecutionPolicy RemoteSigned -Force
$NAVVersion = "90"
Import-Module "C:\Program Files\Microsoft Dynamics NAV\$NAVVersion\Service\NavAdminTool.ps1"

Import-Module "${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\$NAVVersion\RoleTailored Client\Microsoft.Dynamics.Nav.Model.Tools.psd1" -force
#Get-Help "NAV"
