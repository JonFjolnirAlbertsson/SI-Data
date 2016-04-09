if (!(test-path $profile.AllUsersCurrentHost)) {
    new-item -type file -path $profile.AllUsersCurrentHost -force
} Else {
    write-warning 'Profile already existed. Code added at the end.'

    Add-Content -Value '' -Path $profile.AllUsersCurrentHost
    Add-Content -Value '' -Path $profile.AllUsersCurrentHost
    Add-Content -Value '### Added Cloud.Ready.Software-part ###' -Path $profile.AllUsersCurrentHost
    Add-Content -Value '' -Path $profile.AllUsersCurrentHost
}


$code = '
function prompt{
    $Currentlocation = (Get-Location).Path
    if ($Currentlocation.Length -le 15) {
        "$($Currentlocation)>>"
    } else {
        #$Currentlocation.Substring(0,3) + ".." + $Currentlocation.Substring($Currentlocation.lastIndexOf(''\''),$Currentlocation.Length - $Currentlocation.lastIndexOf(''\'')) + ">>"        
        "$($Currentlocation)
PS >"
    }   
}

$code =
{

$file = $psise.CurrentPowerShellTab.Files.Add()

$Text = ''''
foreach($Item in (Get-History -Count $MaximumHistoryCount)){
    $Text += "$($item.CommandLine.TrimStart()) `n"
}

$file.Editor.Text = $Text
                                 
}
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(''Copy History to new file'',$code,$null)

$code =
{
 Import-Module "${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\71\RoleTailored Client\Microsoft.Dynamics.Nav.Model.Tools.psd1" -WarningAction SilentlyContinue | out-null
 Import-Module "$env:ProgramFiles\Microsoft Dynamics NAV\71\Service\NavAdminTool.ps1" -WarningAction SilentlyContinue | Out-Null
}
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(''Load NAV 2013 R2 CmdLets'',$code,$null)


$code =
{
 Import-Module "${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\80\RoleTailored Client\Microsoft.Dynamics.Nav.Model.Tools.psd1" -WarningAction SilentlyContinue | out-null
 Import-Module "$env:ProgramFiles\Microsoft Dynamics NAV\80\Service\NavAdminTool.ps1" -WarningAction SilentlyContinue | Out-Null
}
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(''Load NAV 2015 CmdLets'',$code,$null)

$code =
{
 Import-Module "${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\90\RoleTailored Client\Microsoft.Dynamics.Nav.Model.Tools.psd1" -WarningAction SilentlyContinue | out-null
 Import-Module "$env:ProgramFiles\Microsoft Dynamics NAV\90\Service\NavAdminTool.ps1" -WarningAction SilentlyContinue | Out-Null
 Import-Module "${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\90\RoleTailored Client\Microsoft.Dynamics.Nav.Apps.Tools.psd1" -WarningAction SilentlyContinue | Out-Null

 Clear-Host
 Write-Host ''get-Command -Module ''Microsoft.Dynamics.Nav.*'''' -ForeGroundColor Yellow
 get-Command -Module ''Microsoft.Dynamics.Nav.*''
}
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(''Load NAV 2016 CmdLets'',$code,$null)

$code =
{
   Import-Module "${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\90\RoleTailored Client\Microsoft.Dynamics.Nav.Model.Tools.psd1" -WarningAction SilentlyContinue | out-null
   Import-Module "$env:ProgramFiles\Microsoft Dynamics NAV\90\Service\NavAdminTool.ps1" -WarningAction SilentlyContinue | Out-Null
   Import-Module "${env:ProgramFiles(x86)}\Microsoft Dynamics NAV\90\RoleTailored Client\Microsoft.Dynamics.Nav.Apps.Tools.psd1" -WarningAction SilentlyContinue | Out-Null
   Write-Host ''get-Command -Module ''Microsoft.Dynamics.Nav.*'''' -ForeGroundColor Yellow
   get-Command -Module ''Microsoft.Dynamics.Nav.*''

   Import-module (Join-Path ''C:\GitHub\Cloud.Ready.Software.PowerShell\PSModules'' ''LoadModules.ps1'')  
   Import-module (Join-Path ''C:\GitHub\SI-Data'' ''LoadModules.ps1'')    
}
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(''Start ISE Steroids'',$code,$null)

$code =
{
  Start ''C:\GitHub\Cloud.Ready.Software.PowerShell\PSModules''
}
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(''Open CRS scripts folder'',$code,$null)

$code =
{
  Import-module (Join-Path ''C:\GitHub\Cloud.Ready.Software.PowerShell\PSModules'' ''LoadModules.ps1'')  
}
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(''Force Import Cloud Ready Software Modules'',$code,$null)

$code =
{
  Import-module (Join-Path ''C:\GitHub\SI-Data'' ''LoadModules.ps1'')  
}
$psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(''Force Import SI-Data Modules'',$code,$null)

'

Add-Content -Value $code -Path $profile.AllUsersCurrentHost

psEdit $profile.AllUsersCurrentHost
