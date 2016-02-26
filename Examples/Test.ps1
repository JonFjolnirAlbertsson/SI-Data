$ClientPort = 7210
$ServiceInstanceName = 'NAV71PP'
$SoapPort = $ClientPort + 1
$ODataPort = $SoapPort + 1
$MgtPort = $ODataPort + 1
$DatabaseName = 'ParmaPlast_Nav2013'
$DatabaseServer = 'JALW8'
$DatabaseInstance = ''
$Company = "Package import Test 1"
$path = "C:\Users\jal\Documents\Kunder\Parma Plast\Import\Data files\Ready2Import\Payment Terms.xlsx" 

Invoke-NAVCodeUnit -ServerInstance $ServiceInstanceName -CompanyName $Company -CodeunitId 50002 -MethodName ImportTest -Argument "c\temp\test.xml" -Force