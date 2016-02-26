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

$sourceVHD = "https://portalvhds4tpknmdhq9nyc.blob.core.windows.net/vhds/hmdhiwyl.3af201503261733210185.vhd"
$destinationVHD = "E:\VM\" + $VMName + "OSDisk.vhd"


#Download file
Save-AzureVhd -Source $sourceVHD -LocalFilePath $destinationVHD -NumberOfThreads 5