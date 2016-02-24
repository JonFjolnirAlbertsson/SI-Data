$NAVVersion = 2016
$Licensefile    = 'C:\NAVUpgrade\License\SI-Data 06082015.flf'
$NAVRootFolder = "C:\NAV Setup\NAV$NAVVersion"
$TmpLocation = "$NAVRootFolder\Temp\"
$ISODir = "$NAVRootFolder\ISO"
$NAVInstallConfigFile = "C:\NAV Setup\NAV2016\FullInstallNAV2016.xml"

if (-not (Test-Path $ISODir)) {New-Item -Path $ISODir -ItemType directory | Out-null}
if (-not (Test-Path $TmpLocation)) {New-Item -Path $TmpLocation -ItemType directory | Out-null}

$Download = Get-NAVCumulativeUpdateFile -CountryCodes NO -versions $NAVVersion -DownloadFolder $ISODir

$NAVISOFile = New-NAVCumulativeUpdateISOFile -CumulativeUpdateFullPath $Download.filename -TmpLocation $TmpLocation -IsoDirectory $ISODir 

#$ZippedDVDfile  = 'C:\_Installs\481951_NLB_i386_zip.exe'
$ZippedDVDfile  = $Download.filename

#Get-ChildItem -path (Join-Path $PSScriptRoot '..\PSFunctions\*.ps1') | foreach { . $_.FullName}

$VersionInfo = Get-NAVCumulativeUpdateDownloadVersionInfo -SourcePath $ZippedDVDfile
$DVDDestination = "$NAVRootFolder\" + $VersionInfo.Build + "\DVD\"

if (-not (Test-Path $DVDDestination)) {New-Item -Path $DVDDestination -ItemType directory | Out-null}

$InstallationPath = Unzip-NAVCumulativeUpdateDownload -SourcePath $ZippedDVDfile -DestinationPath $DVDDestination

$InstallationResult = Install-NAV -DVDFolder $InstallationPath -Configfile $NAVInstallConfigFile  

break

import-module (Join-Path $InstallationResult.TargetPath "\RoleTailored Client\Microsoft.Dynamics.Nav.Model.Tools.psd1")
import-module (Join-Path $InstallationResult.TargetPathX64 "\Service\NAVAdminTool.ps1")

Import-NAVServerLicense -ServerInstance $InstallationResult.ServerInstance -LicenseFile $Licensefile

Break
$WorkingFolder  = '$NAVRootFolder\WorkingFolder'
Export-NAVApplicationObject `
    -DatabaseServer ([Net.DNS]::GetHostName()) `
    -DatabaseName $Databasename `
    -Path (join-path $WorkingFolder ($VersionInfo.Build + '.txt')) `
    -LogPath (join-path $WorkingFolder 'Export\Log') `
    -ExportTxtSkipUnlicensed `
    -Force    


break

#$UnInstallPath = "C:\NAV Setup\NAV2016_NO_CU1\DVD"
UnInstall-NAV -DVDFolder $InstallationPath