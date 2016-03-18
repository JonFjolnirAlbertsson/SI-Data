$NAVVersion = 2016
$Licensefile    = 'C:\GitHub\NAVUpgrade\License\SI-Data 06082015.flf'
$NAVRootFolder = "C:\NAV Setup\NAV$NAVVersion"
$TmpLocation = "$NAVRootFolder\Temp\"
$ISODir = "$NAVRootFolder\ISO"
$NAVInstallConfigFile = "C:\NAV Setup\NAV2016\FullInstallNAV2016.xml"
$InstallLog = "$NAVRootFolder\Log\install.log"

if (-not (Test-Path $ISODir)) {New-Item -Path $ISODir -ItemType directory | Out-null}
if (-not (Test-Path $TmpLocation)) {New-Item -Path $TmpLocation -ItemType directory | Out-null}
if (-not (Test-Path $UnInstallLog)) {New-Item -Path $UnInstallLog -ItemType directory | Out-null}

$Download = Get-NAVCumulativeUpdateFile -CountryCodes NO -versions $NAVVersion -DownloadFolder $TmpLocation

#We only need to run this if we want ISO file
#$NAVISOFile = New-NAVCumulativeUpdateISOFile -CumulativeUpdateFullPath $Download.filename -TmpLocation $TmpLocation -IsoDirectory $ISODir 

$ZippedDVDfile  = 'C:\NAV Setup\NAV2016\Temp\489822_NOR_i386_zip.exe'
$ZippedDVDfile  = $Download.filename

#Get-ChildItem -path (Join-Path $PSScriptRoot '..\PSFunctions\*.ps1') | foreach { . $_.FullName}

$VersionInfo = Get-NAVCumulativeUpdateDownloadVersionInfo -SourcePath $ZippedDVDfile
$DVDDestination = "$NAVRootFolder\" + $VersionInfo.Product + $NAVVersion + $VersionInfo.Country +$Download.CUNo  + '_' + $VersionInfo.Build + "\DVD\"

if (-not (Test-Path $DVDDestination)) {New-Item -Path $DVDDestination -ItemType directory | Out-null}

$InstallationPath = Unzip-NAVCumulativeUpdateDownload -SourcePath $ZippedDVDfile -DestinationPath $DVDDestination

$InstallationResult = Install-NAV -DVDFolder $InstallationPath -Configfile $NAVInstallConfigFile -Log $InstallLog

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

#$UnInstallPath =$InstallationPath
$UnInstallPath = "C:\NAV Setup\NAV2016\NAV2016_NO_CU1\DVD\"
UnInstall-NAV -DVDFolder $UnInstallPath -Log $UnInstallLog