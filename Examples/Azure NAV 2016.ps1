#Creating NAV 2016 Demo Server
Import-AzurePublishSettingsFile "C:\Users\jal\OneDrive for Business\Files\Azure\Visual Studio Premium med MSDN-10-12-2015-credentials.publishsettings"

Get-AzureVMImage |  select ImageFamily | Group-Object ImageFamily | Format-Table -AutoSize

$imageFamily = "Microsoft Dynamics NAV 2016 on Windows Server 2012 R2"
$VMImageName = Get-AzureVMImage | where { $_.ImageFamily -eq $imageFamily } | sort PublishedDate -Descending | select -ExpandProperty ImageName -First 1

$AzureSubsription = "Visual Studio Premium med MSDN"
$ServiceName = "SIDNAV2016Demo"
$VMNameNewName = "SIDNAV2016Demo"
$VMAdmin = "vmadmin"
$vmpassword = "1378Nesbru"
$VMLocation = "West Europe"
$InstanceSize = "Basic_A2"

Set-AzureSubscription -SubscriptionName $AzureSubsription -CurrentStorageAccountName (Get-AzureStorageAccount).Label -PassThru  
#Set-AzureSubscription -SubscriptionName $AzureSubsription -CurrentStorageAccountName portalvhds4tpknmdhq9nyc

#Create VM from image
New-AzureQuickVM –Windows –ServiceName $ServiceName –Name $VMNameNewName –InstanceSize $InstanceSize –ImageName $VMImageName -Location $VMLocation -AdminUsername $VMAdmin -Password $vmpassword -WaitForBoot

$source = "http://hotfixv4.microsoft.com/Dynamics%20NAV%202015/latest/NOKB3069272/41370/free/485114_NOR_i386_zip.exe"
$destination = "C:\Temp\NAV\485114_NOR_i386_zip.exe"
 
Invoke-WebRequest $source -OutFile $destination

$RemoteNavDvdLocation = "c:\temp"

$psSession = New-NAVAdminSession `
            -RemoteMachineAddress $VMNameNewName `
            -AzureServiceName  $ServiceName `
            -VMAdminUserName $VMAdmin `
            -VMAdminPassword $vmpassword
# Copy the NAV DVD to the remote machine through the remote PowerShell session (slower but doesn't have a dependency on Azure Storage)
Write-Verbose ("Copying the NAV DVD to the remote machine at " + (Get-Date).ToLongTimeString() + "...")
Copy-DirectoryToRemoteMachine -SourceDirectory $source -RemoteDirectory $RemoteNavDvdLocation -psSession $psSession
Write-Verbose ("Done copying the NAV DVD to the remote machine at " + (Get-Date).ToLongTimeString() + ".")
