# Export

$Export = "C:\Merge\Export\"
$ExportFile = "AllObjects.txt"
$Database = "Nav2009_Overaasen"
#$ObjectFilter = 'Type=Query;ID=700..799'
$ObjectFilter = ''


Import-Module "C:\Users\jal\Documents\NAV\Script\Export-NAVApplicationObjectFile.ps1"

Export-NAVApplicationObjectFile `
 -WorkingFolder $Export `
 -ExportFile $ExportFile `
 -Database $Database `
 -Filter $ObjectFilter

