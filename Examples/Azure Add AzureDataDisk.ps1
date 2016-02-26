
Import-AzurePublishSettingsFile "C:\Users\jal\Documents\SI-Data\Azure\Visual Studio Premium med MSDN-Prøv gratis-3-12-2015-credentials.publishsettings"

#$AzureSubsription = "Prøv gratis"
$AzureSubsription = "Visual Studio Premium med MSDN"
$ServiceName = "SQLNAVUpgrade"
$VMName = "SQLNAVUpgrade"

#Get-AzureVMImage | where {(gm –InputObject $_ -Name DataDiskConfigurations) -ne $null} | Select -Property Label, ImageName 
Set-AzureSubscription -SubscriptionName $AzureSubsription -CurrentStorageAccountName (Get-AzureStorageAccount).Label -PassThru  
 
Get-AzureVM -Name $VMName -ServiceName $ServiceName | Add-AzureDataDisk -CreateNew -DiskSizeInGB 1000 -DiskLabel 'datadisk1' -LUN 3 | Add-AzureDataDisk -CreateNew -DiskSizeInGB 1000 -DiskLabel 'translogs1' -LUN 4 | Update-AzureVM
