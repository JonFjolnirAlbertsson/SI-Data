
#Get-AzurePublishSettingsFile #After saving your file once, just skip this point and remember where you save it, you don't need to save it every time. But keep the file safe as it contains connection details.

Import-AzurePublishSettingsFile "C:\Users\jal\OneDrive for Business\Files\Azure\Visual Studio Premium med MSDN-10-12-2015-credentials.publishsettings"

$vmpassword = "1378Nesbru"
#$AzureSubsription = "Prøv gratis"
$AzureSubsription = "Visual Studio Premium med MSDN"


$ServiceName = "SQLNAVUpgrade"
$VMName = "SQLNAVUpgrade"
$VMImageName = “SQL2014NAV2015Upgrade”
$VMImageLabel = "SI-Data SQL 2014 (3 Disks) NAV 2015 Upgrade"

<#
$ServiceName = "sidata-compello"
$VMName = "CompelloSQL"
$VMImageName = “CompelloSQLDev”
$VMImageLabel = "SI-Data Compello SQL 2014 NAV 2015 CU5"
#>

$VMLocation = "West Europe"

select-azuresubscription $AzureSubsription
#select-azuresubscription "Visual Studio Premium med MSDN"

#Remove-AzureVMImage -ImageName $VMImageName

Stop-AzureVM –ServiceName $ServiceName –Name $VMName -StayProvisioned
#VM will be deleted after creation of Image
#Save-AzureVMImage –ServiceName $ServiceName –Name $VMName –OSState “Generalized” –ImageName $VMImageName –ImageLabel $VMImageLabel

#VM is runnable after creation of image
Save-AzureVMImage –ServiceName $ServiceName –Name $VMName -OSState Specialized –ImageName $VMImageName –ImageLabel $VMImageLabel