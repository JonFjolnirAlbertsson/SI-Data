Import-Module "C:\Users\jal\Documents\NAV\Script\StartingISE_NAV80.ps1"
#Import-Module "C:\Users\jal\Documents\Microsoft downloads\Navision 2015\NO.1538386.DVD\WindowsPowerShellScripts\NAVCertificateAdministration\NAVCertificateAdministration.psm1"
Import-Module "C:\Users\jal\Documents\NAV\Script\New-SelfSignedCertificateEx.ps1"

New-SelfSignedCertificateEx –Subject CN=JALW8.si-data.no –IsCA $true –Exportable –StoreLocation LocalMachine –StoreName My