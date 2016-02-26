<#
.SYNOPSIS
    This cmdlet facilitates the creation of self signed certificates used to secure the communication channel between a NAV Service and a NAV Web Server (Client).

.DESCRIPTION
    This cmdlet creates a self signed certificates used to secure the communication channel between to NAV.
    The process is described in detail on MSDN: http://msdn.microsoft.com/en-us/library/gg502478(v=nav.70).aspx
    This process is carried out as a sequence of actions:
        1. Creates a certificate
        2. Creates a certificate revocation list for the root certification authority
        3. Converts the certificate to an exportable format
        4. Imports the root CA certificate in the trusted publishers certificate store of the local machine
        5. Imports the test certificate in the personal folder of the local machine
.PARAMETER TestCertificateName
    The name you want to identify your test certificate. The name will be prefixed by "RootCA." for the root certificate.
    The default value is the machine host name.
.PARAMETER TestCertificateServerAddress
    The authority/entity which this certificate is issued for.
    The default value is the machine host name.
.PARAMETER TestCertificateRootCerticateAuthorityName
    The root certificate authority name. The name will identify the root certificate issuer
    The default value is the TestCertificate name prefixed with "RootCA."
.PARAMETER OutputFolder
    The path where the certificate files will be generated.
    The default value is the executing script path.
.PARAMETER MakeCertExePath
    The path to the MakeCert.exe tool.
    The default value is to expect the MakeCert.exe file to be in the same folder as the script.
.PARAMETER NavServiceIdentity
    Username for the identity running the NAV Service
    The default value is NetworkService
.PARAMETER SkipImport
    Skips the import certificates steps
#>
function New-NavSelfSignedCertificate
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false)]
        [string] $TestCertificateName = "TestCertificate",

        [parameter(Mandatory=$false)]
        [string] $TestCertificateServerAddress,

        [parameter(Mandatory=$false)]
        [string] $TestCertificateRootCerticateAuthorityName,

        [parameter(Mandatory=$false)]
        [string] $OutputFolder,

        [parameter(Mandatory=$false)]
        [string] $MakeCertExePath,

        [parameter(Mandatory=$false)]
        [string] $NavServiceIdentity = "NT AUTHORITY\Network Service",

        [parameter(Mandatory=$false)]
        [boolean] $SkipImport
    )
    PROCESS 
    {
        if (!(Test-IsRunningAsAdmin))
        {
            Write-Error "This cmdlet must be executed with elevated privileges. Make sure you run PowerShell as administrator."
            return
        }

        if (!$OutputFolder -or [System.String]::IsNullOrWhiteSpace($OutputFolder))
        {
            $OutputFolder = $(get-location).Path
        }
               
        if (!(Test-Path -PathType Container $OutputFolder))
        {
            $OutputFolder = (New-Item -ItemType Directory $OutputFolder).FullName
        }

        if (!$MakeCertExePath)
        {
            $MakeCertExePath = Join-Path $OutputFolder "makecert.exe"
        }

        if (!(Test-Path -PathType Leaf $MakeCertExePath))
        {
            $MakeCertExePath = Join-Path $MakeCertExePath "makecert.exe"

            if (!(Test-Path -PathType Leaf $MakeCertExePath))
            {
                $errorMessage = "Could not find the MakeCert.exe tool" + `
				"`n`tMicrosoft Windows SDK can be downloaded from: http://msdn.microsoft.com/en-us/dn369240.aspx" + `
                "`n`tWhen installed provide the -MakeCertExePath parameter with the full path to the Microsoft Windows SDK MakeCert.exe file."

                Write-Error $errorMessage
                return
            }
        }

        Write-Verbose "Creating self signed test certificate accompanying root certificate"
        #Determining the test certificate name
        $machineHostName = [System.Net.Dns]::GetHostByName([System.Net.Dns]::GetHostName()).HostName		
        if (!$TestCertificateName)
        {
            $TestCertificateName = $machineHostName
        }
		
        # Determine certificate filenames
        if (!$TestCertificateRootCerticateAuthorityName)
        {
            $TestCertificateRootCerticateAuthorityName = "RootCA.$($TestCertificateName)"
        }
       
        $RootCAPvkFile = "$($TestCertificateRootCerticateAuthorityName).pvk"	
        $RootCACerFile = "$($TestCertificateRootCerticateAuthorityName).cer"
        $RootCAClrFile = "$($TestCertificateRootCerticateAuthorityName).crl"
        $TestCertificateFile = "$($TestCertificateName).cer"

        $RootCAPvkFile = Join-Path $OutputFolder $RootCAPvkFile
        $RootCACerFile = Join-Path $OutputFolder $RootCACerFile
        $RootCAClrFile = Join-Path $OutputFolder $RootCAClrFile
        $TestCertificateFile = Join-Path $OutputFolder $TestCertificateFile

        $FilesToDelete = @($RootCAPvkFile,$RootCACerFile,$RootCAClrFile,$TestCertificateFile) | Where { Test-Path $_ } | select
        if ($FilesToDelete.Count -gt 0)
        {
            if (Confirm-YesNo "Overwrite?" "Do you want to overwrite existing certificate files?")
            {
                foreach ($FileToDelete in $FilesToDelete)
                {
                    Remove-Item $FileToDelete
                }
            }
            else
            {
                Write-Verbose "Aborting"
                return
            }
        }

        $RootCACertificateCN = "CN=$TestCertificateRootCerticateAuthorityName";
        # Create root CA certificate
        Write-Verbose "Creating a new root certificate authority certificate and you will be prompted for a password."
        Write-Verbose "If you provide a password you will be asked to provide it several times."

        $didSucceed = & $MakeCertExePath -n "$RootCACertificateCN" -r -pe -sv "$RootCAPvkFile" "$RootCACerFile"
        if ($didSucceed -eq "Succeeded")
        {
            Write-Verbose "Succeeded"
        }
        else
        {
            Write-Verbose "$didSucceed - aborting"
            return
        }

        # Create root CA certificate revocation list
        Write-Verbose "Creating revocation list"      	
        $didSucceed = & $MakeCertExePath -crl -n "$RootCACertificateCN" -r -sv "$RootCAPvkFile" "$RootCAClrFile"
        if ($didSucceed -eq "Succeeded")
        {
            Write-Verbose "Succeeded"
        }
        else
        {
            Write-Verbose "$didSucceed - aborting"
            return
        }
       
        # Create test certificate based on the root CA certificate
        if (!$TestCertificateServerAddress)
        {
            $TestCertificateServerAddress = $machineHostName
        }
		
        Write-Verbose "Creating test certitifcate."
        if ($SkipImport)
        {
            $didSucceed = & $MakeCertExePath -sk "$TestCertificateName" -iv "$RootCAPvkFile" -n "CN=$TestCertificateServerAddress" -ic "$RootCACerFile" -sky exchange -pe "$TestCertificateFile"
        }
        else
        {
            $didSucceed = & $MakeCertExePath -sk "$TestCertificateName" -iv "$RootCAPvkFile" -n "CN=$TestCertificateServerAddress" -ic "$RootCACerFile" -sr localmachine -ss my -sky exchange -pe "$TestCertificateFile"
        }

        if ($didSucceed -eq "Succeeded")
        {
            Write-Verbose "Succeeded"
        }
        else
        {
            Write-Verbose "$didSucceed - aborting"
            return
        }
        
        # Import root certificate and revocation list
        if (!$SkipImport)
        {
            Write-Verbose "Importing root certificate"
            & certutil.exe -enterprise -f -addstore Root $RootCACerFile
            Write-Verbose "Importing root certificate revocation list"
            & certutil.exe -enterprise -f -addstore Root $RootCAClrFile

            $testCertificate = Get-ChildItem Cert:\LocalMachine\My\$(Get-NavCertificateFileThumbprint -CertificateFilePath $TestCertificateFile -Verbose -ErrorAction Stop)
            if ($testCertificate.HasPrivateKey)
            {
                try
                {
                    Write-Verbose "Certificate has private key"
                    Write-Verbose "Changing certificate private key file permissions setting allow read acces for the NAV Service identity"
                    $privateKeyPath = (Join-Path (Join-Path $env:ProgramData "Microsoft\Crypto\RSA\MachineKeys") $testCertificate.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName)
                    Write-Verbose "Setting persmissions on $privateKeyPath"

                    $acl = Get-Acl $privateKeyPath -ErrorAction Stop
                    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($NavServiceIdentity, [System.Security.AccessControl.FileSystemRights]::Read, [System.Security.AccessControl.AccessControlType]::Allow)
                    $acl.AddAccessRule($accessRule)
                    Set-Acl -aclobject $acl $privateKeyPath -ErrorAction Stop
                }
                catch
                {
                    $errorMessage = "An error occured while importing the certificate." + `
                     "`nImport the certificates manually using the certificate management tool." + `
                     "`nImport the root certificate ($RootCaCertificateFilename) to the Local machine\Trusted Root Certification Authorities store." + `
                     "`nImport the root certitifcate revocation list ($RootCACertificateCrlFilename) to the Local machine\Trusted Root Certification Authorities store." + `
                     "`nImport the certificate to the Local machine\Personal store." + `
                     "`nEnsure the Mirosoft Dynamics NAV Server process identity has access to the certificate private key under $(Join-Path $env:ProgramData "Microsoft\Crypto\RSA\MachineKeys")"
                    throw New-Object -TypeName System.Management.Automation.PipelineStoppedException -ArgumentList $errorMessage $_.Exception
                }
            }
        }

        Write-Verbose "Completed"
        return $TestCertificateFile
    }
}

function Confirm-YesNo
{
    PARAM(
        [string]$title="Confirm",
        [string]$message="Are you sure?"
    )
    PROCESS
    {
	    $choiceYes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Answer Yes."
	    $choiceNo = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Answer No."
	    $options = [System.Management.Automation.Host.ChoiceDescription[]]($choiceYes, $choiceNo)
	    $result = $host.ui.PromptForChoice($title, $message, $options, 1)
		switch ($result)
    	{
			0 
		    {
	    	    Return $true
	        }
			1 
			{
    		    Return $false
			}
		}
	}
}

function Test-IsRunningAsAdmin
{
    PARAM 
    (
    )
    PROCESS
    {
        $currentPrincipal = new-object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
        return $currentPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator);
    }
}

Export-ModuleMember New-NavSelfSignedCertificate

# SIG # Begin signature block
# MIIa6AYJKoZIhvcNAQcCoIIa2TCCGtUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUSoSqEn/T5PgFWiQ/XreAVq6/
# 3mygghWCMIIEwzCCA6ugAwIBAgITMwAAAIpX6omjSeuL6AAAAAAAijANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTUxMDA3MTgxNDAy
# WhcNMTcwMTA3MTgxNDAyWjCBszELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjENMAsGA1UECxMETU9QUjEnMCUGA1UECxMebkNpcGhlciBEU0UgRVNO
# OkIxQjctRjY3Ri1GRUMyMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAy8XCCCFsLcM0
# BUnA5TXkIRx+hkXEljDvD+u/MlomeT/pmRbc+4l1oz3FZZoq2aEbKmvJJ56sZZe5
# TbIOgsQAg9iR4ienNO29HtQSlDRE6NoL6QUBS+pVz4pKt5g3Kr7n5w2NPfmn1syY
# AeqQpJmXvwSLX0RFW8hZy6dxQxFqYt/mJehuNbrSiCwDifFnRmEzm4M+s2WJt6dg
# Xo7R3ORQCTw/C+cchNZlzJfRyzG1Igx/7gcKDc1A5Uw5N2oGtlnd4i6QaRvXd5+b
# 3K4vKEBkoABk/a6gbrtJ+18OCdEEHMO+yJPvasooaDOco+3zv6ougZoD7lgM1DdG
# XyRu8bHQ7wIDAQABo4IBCTCCAQUwHQYDVR0OBBYEFD0WsZSu/4ozJ/VxseuzhKon
# OOhLMB8GA1UdIwQYMBaAFCM0+NlSRnAK7UD7dvuzK7DDNbMPMFQGA1UdHwRNMEsw
# SaBHoEWGQ2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3Rz
# L01pY3Jvc29mdFRpbWVTdGFtcFBDQS5jcmwwWAYIKwYBBQUHAQEETDBKMEgGCCsG
# AQUFBzAChjxodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jv
# c29mdFRpbWVTdGFtcFBDQS5jcnQwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZI
# hvcNAQEFBQADggEBAAHUesgSM5gcsDCw++6r3TlkG7E27ohjvqBPXqCHrZlfcXQ/
# NSXMHonyC6N7MeYOK45oOPiCDtm6IgH+9BK5gxpi0yP54KdSvJLdLaihEOfrR84W
# vQuTOmJKdVTUTq8w5xhXKraWjjI0cB3tYVa47N1Tw2ysXKgCQ3GYYWzmuE5wfIBU
# jKfmOOp6zcDvVkMPAw6JyDpwHZrHVB1jezHy5hahIts6CKsESpPMYeL8SjGmHfQG
# rW9jS8BNnBJE4KmGxgvr9/grRMt2m8XwFvAc8yh3rcDNI+eElMI1lyB96BXxq+Eh
# dBZHe2Kw2ssXaxCoqeBmPh9a1B/sH7UdLdxshJEwggTsMIID1KADAgECAhMzAAAB
# Cix5rtd5e6asAAEAAAEKMA0GCSqGSIb3DQEBBQUAMHkxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xIzAhBgNVBAMTGk1pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBMB4XDTE1MDYwNDE3NDI0NVoXDTE2MDkwNDE3NDI0NVowgYMxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDTALBgNVBAsTBE1PUFIx
# HjAcBgNVBAMTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAJL8bza74QO5KNZG0aJhuqVG+2MWPi75R9LH7O3HmbEm
# UXW92swPBhQRpGwZnsBfTVSJ5E1Q2I3NoWGldxOaHKftDXT3p1Z56Cj3U9KxemPg
# 9ZSXt+zZR/hsPfMliLO8CsUEp458hUh2HGFGqhnEemKLwcI1qvtYb8VjC5NJMIEb
# e99/fE+0R21feByvtveWE1LvudFNOeVz3khOPBSqlw05zItR4VzRO/COZ+owYKlN
# Wp1DvdsjusAP10sQnZxN8FGihKrknKc91qPvChhIqPqxTqWYDku/8BTzAMiwSNZb
# /jjXiREtBbpDAk8iAJYlrX01boRoqyAYOCj+HKIQsaUCAwEAAaOCAWAwggFcMBMG
# A1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBSJ/gox6ibN5m3HkZG5lIyiGGE3
# NDBRBgNVHREESjBIpEYwRDENMAsGA1UECxMETU9QUjEzMDEGA1UEBRMqMzE1OTUr
# MDQwNzkzNTAtMTZmYS00YzYwLWI2YmYtOWQyYjFjZDA1OTg0MB8GA1UdIwQYMBaA
# FMsR6MrStBZYAck3LjMWFrlMmgofMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9j
# cmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY0NvZFNpZ1BDQV8w
# OC0zMS0yMDEwLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljQ29kU2lnUENBXzA4LTMx
# LTIwMTAuY3J0MA0GCSqGSIb3DQEBBQUAA4IBAQCmqFOR3zsB/mFdBlrrZvAM2PfZ
# hNMAUQ4Q0aTRFyjnjDM4K9hDxgOLdeszkvSp4mf9AtulHU5DRV0bSePgTxbwfo/w
# iBHKgq2k+6apX/WXYMh7xL98m2ntH4LB8c2OeEti9dcNHNdTEtaWUu81vRmOoECT
# oQqlLRacwkZ0COvb9NilSTZUEhFVA7N7FvtH/vto/MBFXOI/Enkzou+Cxd5AGQfu
# FcUKm1kFQanQl56BngNb/ErjGi4FrFBHL4z6edgeIPgF+ylrGBT6cgS3C6eaZOwR
# XU9FSY0pGi370LYJU180lOAWxLnqczXoV+/h6xbDGMcGszvPYYTitkSJlKOGMIIF
# vDCCA6SgAwIBAgIKYTMmGgAAAAAAMTANBgkqhkiG9w0BAQUFADBfMRMwEQYKCZIm
# iZPyLGQBGRYDY29tMRkwFwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0MS0wKwYDVQQD
# EyRNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMTAwODMx
# MjIxOTMyWhcNMjAwODMxMjIyOTMyWjB5MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSMwIQYDVQQDExpNaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBD
# QTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJyWVwZMGS/HZpgICBC
# mXZTbD4b1m/My/Hqa/6XFhDg3zp0gxq3L6Ay7P/ewkJOI9VyANs1VwqJyq4gSfTw
# aKxNS42lvXlLcZtHB9r9Jd+ddYjPqnNEf9eB2/O98jakyVxF3K+tPeAoaJcap6Vy
# c1bxF5Tk/TWUcqDWdl8ed0WDhTgW0HNbBbpnUo2lsmkv2hkL/pJ0KeJ2L1TdFDBZ
# +NKNYv3LyV9GMVC5JxPkQDDPcikQKCLHN049oDI9kM2hOAaFXE5WgigqBTK3S9dP
# Y+fSLWLxRT3nrAgA9kahntFbjCZT6HqqSvJGzzc8OJ60d1ylF56NyxGPVjzBrAlf
# A9MCAwEAAaOCAV4wggFaMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFMsR6MrS
# tBZYAck3LjMWFrlMmgofMAsGA1UdDwQEAwIBhjASBgkrBgEEAYI3FQEEBQIDAQAB
# MCMGCSsGAQQBgjcVAgQWBBT90TFO0yaKleGYYDuoMW+mPLzYLTAZBgkrBgEEAYI3
# FAIEDB4KAFMAdQBiAEMAQTAfBgNVHSMEGDAWgBQOrIJgQFYnl+UlE/wq4QpTlVnk
# pDBQBgNVHR8ESTBHMEWgQ6BBhj9odHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtp
# L2NybC9wcm9kdWN0cy9taWNyb3NvZnRyb290Y2VydC5jcmwwVAYIKwYBBQUHAQEE
# SDBGMEQGCCsGAQUFBzAChjhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2Nl
# cnRzL01pY3Jvc29mdFJvb3RDZXJ0LmNydDANBgkqhkiG9w0BAQUFAAOCAgEAWTk+
# fyZGr+tvQLEytWrrDi9uqEn361917Uw7LddDrQv+y+ktMaMjzHxQmIAhXaw9L0y6
# oqhWnONwu7i0+Hm1SXL3PupBf8rhDBdpy6WcIC36C1DEVs0t40rSvHDnqA2iA6VW
# 4LiKS1fylUKc8fPv7uOGHzQ8uFaa8FMjhSqkghyT4pQHHfLiTviMocroE6WRTsgb
# 0o9ylSpxbZsa+BzwU9ZnzCL/XB3Nooy9J7J5Y1ZEolHN+emjWFbdmwJFRC9f9Nqu
# 1IIybvyklRPk62nnqaIsvsgrEA5ljpnb9aL6EiYJZTiU8XofSrvR4Vbo0HiWGFzJ
# NRZf3ZMdSY4tvq00RBzuEBUaAF3dNVshzpjHCe6FDoxPbQ4TTj18KUicctHzbMrB
# 7HCjV5JXfZSNoBtIA1r3z6NnCnSlNu0tLxfI5nI3EvRvsTxngvlSso0zFmUeDord
# EN5k9G/ORtTTF+l5xAS00/ss3x+KnqwK+xMnQK3k+eGpf0a7B2BHZWBATrBC7E7t
# s3Z52Ao0CW0cgDEf4g5U3eWh++VHEK1kmP9QFi58vwUheuKVQSdpw5OPlcmN2Jsh
# rg1cnPCiroZogwxqLbt2awAdlq3yFnv2FoMkuYjPaqhHMS+a3ONxPdcAfmJH0c6I
# ybgY+g5yjcGjPa8CQGr/aZuW4hCoELQ3UAjWwz0wggYHMIID76ADAgECAgphFmg0
# AAAAAAAcMA0GCSqGSIb3DQEBBQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAX
# BgoJkiaJk/IsZAEZFgltaWNyb3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290
# IENlcnRpZmljYXRlIEF1dGhvcml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0MDMx
# MzAzMDlaMHcxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAf
# BgNVBAMTGE1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAJ+hbLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP7tGn
# 0UytdDAgEesH1VSVFUmUG0KSrphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySHnfL0
# Zxws/HvniB3q506jocEjU8qN+kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUoRi4n
# rIZPVVIM5AMs+2qQkDBuh/NZMJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABKR2YR
# JylmqJfk0waBSqL5hKcRRxQJgp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSfrx54
# QTF3zJvfO4OToWECtR0Nsfz3m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGnMA8G
# A1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMPMAsG
# A1UdDwQEAwIBhjAQBgkrBgEEAYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQOrIJg
# QFYnl+UlE/wq4QpTlVnkpKFjpGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcG
# CgmSJomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3Qg
# Q2VydGlmaWNhdGUgQXV0aG9yaXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1UdHwRJ
# MEcwRaBDoEGGP2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1
# Y3RzL21pY3Jvc29mdHJvb3RjZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYB
# BQUHMAKGOGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9z
# b2Z0Um9vdENlcnQuY3J0MBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEB
# BQUAA4ICAQAQl4rDXANENt3ptK132855UU0BsS50cVttDBOrzr57j7gu1BKijG1i
# uFcCy04gE1CZ3XpA4le7r1iaHOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV3U+r
# kuTnjWrVgMHmlPIGL4UD6ZEqJCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5nGct
# xVEO6mJcPxaYiyA/4gcaMvnMMUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tOi3/F
# NSteo7/rvH0LQnvUU3Ih7jDKu3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbMUVbo
# nXCUbKw5TNT2eb+qGHpiKe+imyk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXjpKh0
# NbhOxXEjEiZ2CzxSjHFaRkMUvLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh0EPp
# K+m79EjMLNTYMoBMJipIJF9a6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLaxaj2J
# oXZhtG6hE6a/qkfwEm/9ijJssv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWwymO0
# eFQF1EEuUKyUsKV4q7OglnUa2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma7kng
# 9wFlb4kLfchpyOZu6qeXzjEp/w7FW1zYTRuh2Povnj8uVRZryROj/TGCBNAwggTM
# AgEBMIGQMHkxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xIzAh
# BgNVBAMTGk1pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBAhMzAAABCix5rtd5e6as
# AAEAAAEKMAkGBSsOAwIaBQCggekwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFM5k
# /Z1qe2d9oI3MZOUIAjHkVSF5MIGIBgorBgEEAYI3AgEMMXoweKBagFgATQBpAGMA
# cgBvAHMAbwBmAHQAIABEAHkAbgBhAG0AaQBjAHMAIABOAEEAVgAgAEMAbwBkAGUA
# cwBpAGcAbgAgAFMAdQBiAG0AaQBzAHMAcwBpAG8AbgAuoRqAGGh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbTANBgkqhkiG9w0BAQEFAASCAQB75VUQW/LJsd96JlZj3hFi
# 8dBYBRZVxY8sa8NsvRiZdo7SW8NuyO5qjP9F7hvofT+YmtVlk4DJdxyGEXrx8ci0
# JxiEKahDC6gQwvzodyp8YNgLQTh/P5Fk4SNian1SmCg+Qdn0wg3WbjxDyEHh3omQ
# vNtZ62S5z46ErMI9udZZnc9AbwCwrBh4NJ9rx8ypIst83NDHxq9FEuBC5cI/gzLB
# gntuPpz7UAEfcycBgbZNmREWPjptbLwowZbWX60QPpsrWQcDSrfSVBD+XIFShiau
# OPtr+hKc7kboCuT36XluzKNyhFGa9FM5TpMm4N7BKLb0VKW3Ujwoburjhtc7RoOo
# oYICKDCCAiQGCSqGSIb3DQEJBjGCAhUwggIRAgEBMIGOMHcxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFBDQQITMwAAAIpX6omjSeuL6AAAAAAAijAJBgUrDgMCGgUAoF0wGAYJ
# KoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTUxMDIzMTQz
# NDI2WjAjBgkqhkiG9w0BCQQxFgQU2x/DWM098vv8ebM6ZpTz6GGbhJYwDQYJKoZI
# hvcNAQEFBQAEggEAilpMfb6FIv+44AARMMoDHpRQs509uLkk/rEas7krNlR5mbaR
# qJGWJFy5nw4XFjeZpCxXDic4wz7186Rq7p0ijOhX6NoaZp8r7NTeqNDl4tWeUj3h
# MjhKiwFqL2qJFJ3WY1ytFn3u6BLjTeSnmAUI7XPxmpudJ7/1mSyFpNYQkljyTR/A
# LRor3HQab+q1RaF2k+bEcsLCh54b4SUW2ocosElxw4VekpqZ/cypmCZT74uE7gq4
# XRFjg6wmlBgUpSaYqJX3LqTNdfkHvQygxTr42i7woJlGhp4KpEVgW2+T503xcKxu
# UITkHWse9spLS87tKI1GlnawLvoaau7Sgc27iA==
# SIG # End signature block
