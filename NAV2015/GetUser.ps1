$username = "Anne-Mari Wiig"
$username = "Heidi Van Spronsen"
$username = "Turid Anne Tangen"
$username = "A*"

$User = Get-WMIObject Win32_UserAccount | Where-Object {$_.FullName -like $username}
#$User = Get-WMIObject Win32_UserAccount | Where-Object {$_.FullName -eq $username -and $_.Domain -eq "SPILKAD"}
$User