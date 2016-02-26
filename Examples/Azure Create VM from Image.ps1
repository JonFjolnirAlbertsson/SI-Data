
#Get-AzurePublishSettingsFile #After saving your file once, just skip this point and remember where you save it, you don't need to save it every time. But keep the file safe as it contains connection details.

Import-AzurePublishSettingsFile "C:\Users\jal\OneDrive for Business\Files\Azure\Visual Studio Premium med MSDN-10-12-2015-credentials.publishsettings"

#Check again - this time it should work:
#Get-AzureVM 

#Get-AzureVMImage | Select ImageName

#Virtual Machine file
#Get-AzureSubscription

#$AzureSubsription = "Prøv gratis"
$AzureSubsription = "Visual Studio Premium med MSDN"
$ServiceName = "SQL2014NAV2015"
$VMNameNewName = "SQL2014NAV2015"
$VMImageName = “SQLNAV2015Upgrade”

#Get-AzureVMImage | where {(gm –InputObject $_ -Name DataDiskConfigurations) -ne $null} | Select -Property Label, ImageName 
Set-AzureSubscription -SubscriptionName $AzureSubsription -CurrentStorageAccountName (Get-AzureStorageAccount).Label -PassThru  
#Set-AzureSubscription -SubscriptionName $AzureSubsription -CurrentStorageAccountName portalvhds4tpknmdhq9nyc

#"Prøv gratis"
#Set-AzureSubscription -SubscriptionName $AzureSubsription -CurrentStorageAccountName portalvhdsjsc25kv9dkvx5

#Create VM from Specialized image
New-AzureQuickVM –Windows –ServiceName $ServiceName   –Name $VMNameNewName –InstanceSize "A8" –ImageName $VMImageName -WaitForBoot 
