#Connect to Azure
import-module azure #see pre-requisites from above.

#Check if we are logged on to our Azure subscriuption - expect this to fail for now:
Get-AzureVM

#Log in to your Azure subscription
Add-AzureAccount

Get-Azuresubscription 
#Remove-AzureSubscription "Prøv gratis"
#Select-AzureSubscription “Visual Studio Premium med MSDN”


Get-AzurePublishSettingsFile #After saving your file once, just skip this point and remember where you save it, you don't need to save it every time. But keep the file safe as it contains connection details.

Import-AzurePublishSettingsFile "C:\Users\jal\OneDrive for Business\Files\Azure\Visual Studio Premium med MSDN-10-12-2015-credentials.publishsettings"

#Check again - this time it should work:
Get-AzureVM 

Get-AzureVMImage | Select ImageName

#Start-AzureVM -Name "JALDev.cloudapp.net" -ServiceName "JALNAV2015Dev" -Verbose

#Virtual Machine file
#Get-AzureSubscription

#select-azuresubscription "Prøv gratis"
#select-azuresubscription "Visual Studio Premium med MSDN"
$VMAdmin = "vmadmin"
$vmpassword = "1378Nesbru"
#$AzureSubsription = "Prøv gratis"
$AzureSubsription = "Visual Studio Premium med MSDN"
#$storageAccountName = ""
$ServiceName = "SQLNAVUpgrade"
$VMName = "SQLNAVUpgrade"
$VMNameNewName = "SQLNAV2015Upgrade"
$VMImageName = “SQLNAV2015Upgrade”
$VMImageLabel = "SI-Data SQL 2014 NAV 2015 Upgrade"
$VMLocation = "West Europe"

#$sourceVHD = "https://portalvhds4tpknmdhq9nyc.blob.core.windows.net/vhds/sidata-compello-sidata-compello-2015-03-23.vhd"
#$destinationVHD = "E:\VM\NAV2015NOCU5.vhd"

select-azuresubscription $AzureSubsription
#select-azuresubscription "Visual Studio Premium med MSDN"

#Remove-AzureVMImage -ImageName $VMImageName

Stop-AzureVM –ServiceName $ServiceName –Name $VMName -StayProvisioned
#VM will be deleted after creation of Image
#Save-AzureVMImage –ServiceName $ServiceName –Name $VMName –OSState “Generalized” –ImageName $VMImageName –ImageLabel $VMImageLabel

#VM is runnable after creation of image
Save-AzureVMImage –ServiceName $ServiceName –Name $VMName -OSState Specialized –ImageName $VMImageName –ImageLabel $VMImageLabel

#Get-AzureVMImage | where {(gm –InputObject $_ -Name DataDiskConfigurations) -ne $null} | Select -Property Label, ImageName 

Set-AzureSubscription -SubscriptionName $AzureSubsription -CurrentStorageAccountName (Get-AzureStorageAccount).Label -PassThru  

#New-AzureQuickVM –Windows –Location $VMLocation  –ServiceName $ServiceName  –Name $VMNameNewName –InstanceSize "Medium" –ImageName $VMImageName –AdminUsername $VMAdmin –Password $vmpassword -WaitForBoot 

#Create VM from Specialized image
New-AzureQuickVM –Windows –ServiceName $VMNameNewName  –Name $VMNameNewName –InstanceSize "Medium" –ImageName $VMImageName -WaitForBoot 

#Download file
#Save-AzureVhd -Source $sourceVHD -LocalFilePath $destinationVHD -NumberOfThreads 5

#Upload file
#Add-AzureVhd -LocalFilePath $sourceVHD -Destination $destinationVHD -NumberOfUploaderThreads 5

# Register as a plan old data disk 
#Add-AzureDisk -DiskName 'myosdisk' -MediaLocation $destinationVHD -Label 'myosdisk' -OS Windows # or Linux

#New-AzureVMConfig -DiskName 'myosdisk' -Name 'myvm1' -InstanceSize Small | Add-AzureDataDisk -Import -DiskName 'mydatadisk' -LUN 0 | New-AzureVM -ServiceName 'mycloudsvc' -Location 'West Europe'
