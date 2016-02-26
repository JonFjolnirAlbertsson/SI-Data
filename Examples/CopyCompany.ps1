$ClientPort = 7210
$ServiceInstanceName = 'NAV71PP'
$SoapPort = $ClientPort + 1
$ODataPort = $SoapPort + 1
$MgtPort = $ODataPort + 1
$DatabaseName = 'ParmaPlast_Nav2013'
$DatabaseServer = 'JALW8'
$DatabaseInstance = ''
$CompanyName = 'Parma Plast AS Import1'

#Get-NAVServerInstance NAV71PP | Copy-NAVCompany -DestinationCompanyName 'Parma Plast AS Import1' -SourceCompanyName 'KOPI 2014-01-08 Parmaplast'
Remove-NAVCompany -ServerInstance $ServiceInstanceName -CompanyName $CompanyName
