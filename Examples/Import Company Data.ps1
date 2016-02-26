$Folderpath = "C:\SQL\Backup\OSO\OSO Hotwater AS\"
$CompanyName = 'OSO Hotwater AS'

$NavServiceInstance = "NAV80OSOUpgrToProd"

#Export-NAVData -FilePath $FilePath -ServerInstance $NavServiceInstance -CompanyName $CompanyName -IncludeApplicationData 

$FilePath =  $FolderPath + $CompanyName + '.navdata'
Import-NAVData -FilePath $FilePath  -ServerInstance $NavServiceInstance -CompanyName $CompanyName  -IncludeApplicationData -IncludeGlobalData 
#Export-NAVData -FilePath $FilePath -ServerInstance $NavServiceInstance -CompanyName $CompanyName -IncludeApplication -IncludeApplicationData -IncludeGlobalData  