# Comparing and merging

Import-Module "C:\Users\jal\Documents\NAV\Script\StartingISE.ps1"
$CompanyFolderName = "Øveraasen"
$CompanySourceFileName = "*.TXT"
$CompanyDestinationFileName = "merged-ready2Import.txt"



# Set the right folder path based on company folder and files name
$CompanySource = "C:\Merge\" + $CompanyFolderName + "\Merged\" + $CompanySourceFileName
$CompanyDestination = "c:\Merge\" + $CompanyFolderName + "\" + $CompanyDestinationFileName

Join-NAVApplicationObjectFile -Source $CompanySource -Destination $CompanyDestination -Force
