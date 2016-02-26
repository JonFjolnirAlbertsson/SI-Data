#Select-AzureSubscription "my subscription" 
 
### Source VHD (West US) - authenticated container ###
$srcUri = "https://portalvhds4tpknmdhq9nyc.blob.core.windows.net/vhds/hmdhiwyl.3af201503261733210185.vhd"
Import-AzurePublishSettingsFile "C:\Users\jal\Documents\SI-Data\Azure\Visual Studio Premium med MSDN-Prøv gratis-3-12-2015-credentials.publishsettings"

$AzureSubsriptionNew = "Prøv gratis"
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
$srcStorageAccount  = Get-AzureStorageAccount
$srcStorageKey = (Get-AzureStorageKey –StorageAccountName $srcStorageAccount.Label).Primary 
$srcContainer = Get-AzureStorageContainer 
 
Set-AzureSubscription -SubscriptionName $AzureSubsriptionNew -CurrentStorageAccountName (Get-AzureStorageAccount).Label -PassThru
### Target Storage Account (West US) ###
$destStorageAccount = Get-AzureStorageAccount
$destStorageKey = (Get-AzureStorageKey –StorageAccountName $destStorageAccount.Label).Primary
 
### Create the source storage account context ### 
#$srcContext = New-AzureStorageContext  –StorageAccountName $srcStorageAccount -StorageAccountKey $srcStorageKey  
 
### Create the destination storage account context ### 
$destContext = New-AzureStorageContext  –StorageAccountName $destStorageAccount -StorageAccountKey $destStorageKey  
$destContainer = Get-AzureStorageContainer 

### Destination Container Name ### 
$containerName = "copiedvhds"
 
### Create the container on the destination ### 
#New-AzureStorageContainer -Name $containerName -Context $destContext 
 
### Start the asynchronous copy - specify the source authentication with -SrcContext ### 
$blob1 = Start-AzureStorageBlobCopy -srcUri $srcUri `
                                    -SrcContext $srcContext `
                                    -DestContainer $destContainer.Name `
                                    -DestBlob "testcopy1.vhd" `
                                    -DestContext $destContext

#$srcContainer | Get-AzureStorageBlob | ForEach-Object { Get-AzureStorageBlobCopyState -Blob $_.Name -Context $destContext -Container $destContainer.Name -WaitForComplete }

