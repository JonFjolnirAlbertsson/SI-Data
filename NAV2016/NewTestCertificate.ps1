$RootPath = "C:\Users\$env:Username\OneDrive for Business\Files"
$MakeCertExcFolder = "C:\Program Files (x86)\Windows Kits\8.1\bin\x64\"
$CertificateFolder = "C:\Users\jal\OneDrive for Business\Files\Certificate\DynamicsNAV90"
$RootScriptPath = "$RootPath\NAV\Script\$NAVVersionFolder"
Import-module "$RootScriptPath\NAVCertificateAdministration\NAVCertificateAdministration.psm1"

$NAVServiceIdenty = "si-data\sql"

New-NavSelfSignedCertificate -MakeCertExePath $MakeCertExcFolder -NavServiceIdentity $NAVServiceIdenty -OutputFolder $CertificateFolder -SkipImport $False