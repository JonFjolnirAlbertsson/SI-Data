Import-AzurePublishSettingsFile "C:\Users\jal\Documents\SI-Data\Azure\Visual Studio Premium med MSDN-Prøv gratis-3-12-2015-credentials.publishsettings"

$AzureSubsriptionNew = "Prøv gratis"
$AzureSubsription = "Visual Studio Premium med MSDN"
$VMDiskName = “SQLNAVUpgrade”
$ServiceName = "SQLNAVUpgrade"
$VMName = "SQL2014Upgr"
#$VMName = "SQLNAVUpgrade"
#$sourceVHD = "https://portalvhds4tpknmdhq9nyc.blob.core.windows.net/vhds/sidata-compello-sidata-compello-2015-03-23.vhd"
$sourceVHD = "https://portalvhds4tpknmdhq9nyc.blob.core.windows.net/vhds/hmdhiwyl.3af201503261733210185.vhd" # OS Disk
$destinationVHD = "E:\VM\" + $VMName + "OSDisk.vhd"

Select-AzureSubscription -SubscriptionName $AzureSubsription

#$workingDir = (Get-Location).Path
$workingDir = "E:\VM\"

$sourceVm = Get-AzureVM –ServiceName $serviceName –Name $vmName

$vmConfigurationPath = $workingDir + "\exportedVM.xml"

$sourceVm | Export-AzureVM -Path $vmConfigurationPath

$sourceOSDisk = $sourceVm.VM.OSVirtualHardDisk

$sourceDataDisks = $sourceVm.VM. DataVirtualHardDisks

$sourceStorageName = $sourceOSDisk.MediaLink.Host -split "\." | select -First 1

$sourceStorageAccount = Get-AzureStorageAccount –StorageAccountName $sourceStorageName

$sourceStorageKey = (Get-AzureStorageKey -StorageAccountName $sourceStorageName).Primary

Stop-AzureVM –ServiceName $serviceName –Name $vmName -Force

Select-AzureSubscription -SubscriptionName $AzureSubsriptionNew
$location = $sourceStorageAccount.Location

$destStorageAccount = Get-AzureStorageAccount | ? {$_.Location -eq $location} | select -first 1

if ($destStorageAccount -eq $null)
{
    $destStorageName = "NEW_STORAGE_NAME"
    New-AzureStorageAccount -StorageAccountName $destStorageName -Location $location
    $destStorageAccount = Get-AzureStorageAccount -StorageAccountName $destStorageName
}

$destStorageName = $destStorageAccount.StorageAccountName
$destStorageKey = (Get-AzureStorageKey -StorageAccountName $destStorageName).Primary
$sourceContext = New-AzureStorageContext –StorageAccountName $sourceStorageName -StorageAccountKey $sourceStorageKey 

$destContext = New-AzureStorageContext –StorageAccountName $destStorageName -StorageAccountKey $destStorageKey
if ((Get-AzureStorageContainer -Context $destContext -Name vhds -ErrorAction SilentlyContinue) -eq $null)
{
    New-AzureStorageContainer -Context $destContext -Name vhds
}

$allDisks = @($sourceOSDisk) + $sourceDataDisks
$destDataDisks = @()

foreach($disk in $allDisks)
{
    $blobName = $disk.MediaLink.Segments[2]
    $targetBlob = Start-CopyAzureStorageBlob -SrcContainer vhds -SrcBlob $blobName -DestContainer vhds -DestBlob $blobName -Context $sourceContext -DestContext $destContext -Force

    Write-Host "Copying blob $blobName"

    $copyState = $targetBlob | Get-AzureStorageBlobCopyState
    while ($copyState.Status -ne "Success")
    {
        $percent = ($copyState.BytesCopied / $copyState.TotalBytes) * 100
        Write-Host "Completed $('{0:N2}' -f $percent)%"
        sleep -Seconds 5
        $copyState = $targetBlob | Get-AzureStorageBlobCopyState
    }

    If ($disk -eq $sourceOSDisk)
    {
        $destOSDisk = $targetBlob
    }
    Else
    {
        $destDataDisks += $targetBlob
    }
}

Add-AzureDisk -OS $sourceOSDisk.OS -DiskName $sourceOSDisk.DiskName -MediaLocation $destOSDisk.ICloudBlob.Uri
foreach($currenDataDisk in $destDataDisks)
{
    $diskName = ($sourceDataDisks | ? {$_.MediaLink.Segments[2] -eq $currenDataDisk.Name}).DiskName
    Add-AzureDisk -DiskName $diskName -MediaLocation $currenDataDisk.ICloudBlob.Uri
}

Get-AzureSubscription -Current | Set-AzureSubscription -CurrentStorageAccountName $destStorageName
$vmConfig = Import-AzureVM -Path $vmConfigurationPath
New-AzureVM -ServiceName $destServiceName -Location $location -VMs $vmConfig -WaitForBoot

Get-AzureRemoteDesktopFile -ServiceName $destServiceName -Name $vmConfig.RoleName -LocalPath ($workingDir+"\newVM.rdp")