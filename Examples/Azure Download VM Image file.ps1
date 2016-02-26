Import-AzurePublishSettingsFile "C:\Users\jal\Documents\SI-Data\Azure\Visual Studio Premium med MSDN-Prøv gratis-3-12-2015-credentials.publishsettings"

#$AzureSubsription = "Prøv gratis"
$AzureSubsription = "Visual Studio Premium med MSDN"
$VMDiskName = “SQLNAVUpgrade”
$VMName = "SQL2014Upgr"
#$sourceVHD = "https://portalvhds4tpknmdhq9nyc.blob.core.windows.net/vhds/sidata-compello-sidata-compello-2015-03-23.vhd"
#$sourceVHD = "https://portalvhds4tpknmdhq9nyc.blob.core.windows.net/vhds/SQLNAVUpgrade-SQLNAVUpgrade-2015-03-25.vhd" # OS Disk
$sourceVHD = "https://portalvhds4tpknmdhq9nyc.blob.core.windows.net/vhds/hmdhiwyl.3af201503261733210185.vhd"
$destinationVHD = "E:\VM\" + $VMName + "OSDisk.vhd"

Set-AzureSubscription -SubscriptionName $AzureSubsription -CurrentStorageAccountName (Get-AzureStorageAccount).Label -PassThru  
#Get-AzureSubscription
#Get-AzureVMImage | where {(gm –InputObject $_ -Name DataDiskConfigurations) -ne $null} | Select -Property Label, ImageName 

#portalvhdsjsc25kv9dkvx5
$myStoreAccount = Get-AzureStorageAccount
$myStoreKey = (Get-AzureStorageKey –StorageAccountName $myStoreAccount.Label).Primary 

#Download file
#Save-AzureVhd -Source $sourceVHD -LocalFilePath $destinationVHD -NumberOfThreads 5
Save-AzureVhd -Source $sourceVHD -LocalFilePath $destinationVHD -NumberOfThreads 5 -StorageKey $myStoreKey

#Upload file
#Add-AzureVhd -LocalFilePath $sourceVHD -Destination $destinationVHD -NumberOfUploaderThreads 5
