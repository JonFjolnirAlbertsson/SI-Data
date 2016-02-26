
#http://azure.microsoft.com/en-us/downloads/

#Connect to Azure
import-module azure #see pre-requisites from above.

#Check if we are logged on to our Azure subscriuption - expect this to fail for now:
#Get-AzureVM

#Log in to your Azure subscription
#Add-AzureAccount

Import-AzurePublishSettingsFile "E:\VM\Visual Studio Premium med MSDN-Prøv gratis-3-12-2015-credentials.publishsettings"

$VMAdmin = "vmadmin"
$vmpassword = "1378Nesbru"
$AzureSubsription = "Prøv gratis"
#$AzureSubsription = "Visual Studio Premium med MSDN"

$ServiceName = "SQL2014NAV2015"
$VMNameNewName = "SQL2014NAV2015"
$OSDiskName = "SQL2014NAV2015osdisk"
$VMLocation = "West Europe"

$sourceVHD = "E:\VM\SQL2014NAV2015Upgrade-os-2015-03-27.vhd"
$destinationVHD = "https://portalvhdsjsc25kv9dkvx5.blob.core.windows.net/vhds/SQL2014NAV2015OSDisk.vhd"


Set-AzureSubscription -SubscriptionName $AzureSubsription -CurrentStorageAccountName (Get-AzureStorageAccount).Label -PassThru  

#select-azuresubscription $AzureSubsription

#Upload file
#Add-AzureVhd -LocalFilePath $sourceVHD -Destination $destinationVHD -NumberOfUploaderThreads 5

# Register as a plan old data disk 
#Add-AzureDisk -DiskName $OSDiskName -MediaLocation $destinationVHD -Label $OSDiskName -OS Windows # or Linux

New-AzureVMConfig -DiskName $OSDiskName -Name $VMNameNewName  -InstanceSize Small | Add-AzureDataDisk -CreateNew -DiskLabel "DataDisk1" -DiskSizeInGB 1000 -LUN 0 | Add-AzureDataDisk -CreateNew -DiskLabel "LogDisk1" -DiskSizeInGB 1000 -LUN 1 |New-AzureVM -ServiceName $ServiceName -Location $VMLocation
#Add-AzureDataDisk -CreateNew -DiskLabel DataDisk1 -DiskSizeInGB 1000 -LUN 0