<#
 .SYNOPSIS
   This cmdlet performs the configuration changes for the NAV Server, Web Server Instances and the Office 365 tenant
   in order to support Single Sign-on with Office 365.

 .DESCRIPTION
   This cmdlet performs the configuration changes for the NAV Server, Web Server Instances and the Office 365 tenant
   in order to support Single Sign-on with Office 365.
   This process is carried out as a sequence of actions:
   1. Updating the NAV user to be connected to an Office 365 user account
   2. Updating the NAV Server configuration
   3. Updating the Nav Web Server Instance Configuration
   4. Updating the Windows Azure Active Directory tenant by creating/changing a Server Principal for the NAV Web Client
   5. Updating the Windows Azure Active Directory tenant by creating/changing a Server Principal for the NAV Windows Client

 .PARAMETER NavServerInstance
   The name of the NAV server instance. If your NAV Windows Service is called 'MicrosoftDynamicsNavServer$DynamicsNAV', 
   then your NavServerInstance is 'DynamicsNAV'.
 .PARAMETER NavTenant 
   The tenant id if running multitenancy - otherwise just use default.
 .PARAMETER NavWebAdress
   Specifies the NAV Web Client URI.
 .PARAMETER NavWebServerInstanceName
   Specifies the name of the NAV Web Server instance.
 .PARAMETER NavUser
   Specifies the NAV User Account that needs to have a single sign on. This needs to be configured by hand for the other users.    
 .PARAMETER AuthenticationEmail
   Specifies the Office 365 user email address that needs to be connected to the NAV User account. 
 .PARAMETER AuthenticationEmailPassword
   Specifies the Office 365 user password, in a SecureString form.
 .PARAMETER NavServerCertificateThumbprint
   Specifies thumbprint of the certificate to be used in securing the communication NAV Server and a NAV Web Server.
 .PARAMETER SkipNavServerConfiguration
   Skips the configuration changes for the NAV Server and NAV User.
 .PARAMETER SkipWebServerConfiguration
   Skips the configuration changes for the NAV Web Server components and Windows Azure Active Directory tenant. 
 .PARAMETER SkipWinClientConfiguration
   Skips the configuration changes for the NAV Windows Client.
#>
function Set-NavSingleSignOnWithOffice365
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $NavServerInstance,

        [parameter(Mandatory=$false)]
        [string] $NavTenant="Default",                
     
        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $NavWebServerInstanceName,

        [parameter(Mandatory=$false)]
        [string] $NavWebAddress,

        [parameter(Mandatory=$false)]
        [string] $NavUser,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $AuthenticationEmail,

        [parameter(Mandatory=$false)]
        [ValidateNotNull()]
        [SecureString] $AuthenticationEmailPassword,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $NavServerCertificateThumbprint,

        [parameter(Mandatory=$false)]
        [switch] $SkipNavServerConfiguration,

        [parameter(Mandatory=$false)]
        [switch] $SkipWebServerConfiguration, 

        [parameter(Mandatory=$false)]
        [switch] $SkipWinClientConfiguration
    )
    PROCESS 
    {       
        if (!(Test-IsRunningAsAdmin))
        {
            Write-Error "This cmdlet must be executed with elevated privileges. Make sure you run PowerShell as administrator."
            return
        }

        ImportPrerequisites

        # Check switch dependent mandatory variables
        if (!$SkipNavServerConfiguration -and [string]::IsNullOrWhiteSpace($NavServerInstance))
        {
            Write-Error "The NavServerInstance parameter is required. Specify the -SkipNavServerConfiguration flag to skip Nav Server configuration"
            return
        }

        if (!$SkipWebServerConfiguration -and [string]::IsNullOrWhiteSpace($NavWebServerInstanceName))
        {
            Write-Error "The NavWebServerInstanceName parameter is required. Specify the -SkipWebServerConfiguration flag to skip Nav Web Server components configuration"
            return
        }
           
        if (!$SkipWebServerConfiguration)
        {
            # Get web server instance name and its derived variables
            $webServerInstance = Validate-NavWebServerInstance -WebServerInstance $NavWebServerInstanceName
            if (!$webServerInstance)
            {
            	Write-Error "Either you have not specified a web server instance name and there is more than one, or the instance that you specified could not be found."
            	return
            }    
            $NavWebsiteName = $webServerInstance.Website
        }

        if (!$SkipNavServerConfiguration)
        {
            # Validate that the provided NAV Server instance is up and running
            $navServerInstanceState = Get-NAVServerInstance -ServerInstance $NavServerInstance
            if (!$navServerInstanceState)
            {
            	Write-Error "A NAV Server instance with the specified name '$NavServerInstance' could not be found."
            	return
            }

            # Validate that the web server instance points to the provided NAV server instance
            $navServerConfiguration = Get-NavServerConfiguration -ServerInstance $NavServerInstance -ErrorAction Stop
            $serverInstance = ($navServerConfiguration | where { $_.GetAttribute("key") -eq "ServerInstance" }).Value
            if (!$SkipWebServerConfiguration -and ($serverInstance -ne $webServerInstance.ServerInstance))
            {
            	Write-Error "The Nav Web Server instance does not point to the right Nav Server."
            	return
            }

            if ($NavUser)
            {
              # Validate user has already been created            
              $navUserEntry = Get-NAVServerUser -ServerInstance $NavServerInstance -Tenant $NavTenant -ErrorAction Stop | where { $_.UserName -eq $NavUser }
              if (!$navUserEntry)
              {
                  Write-Error "The user $NavUser was not found."
                  return
              }
            }
            else
            {
              $warningMessage = "Configuring Single Sign On without connecting a Microsoft Dynamics NAV user account to an Office 365 account." + `
                "`n`tThis might cause the impossibility to sign in to Microsoft Dynamics NAV if no user has the Authentication Email set."
              Write-Warning $warningMessage
              timeout /t 10
            }

            # Validate certificate thumbprint
            $currentNavServerCertificateThumbprintElement = $navServerConfiguration | where { $_.GetAttribute("key") -eq "ServicesCertificateThumbprint" }
            $currentNavServerCertificateThumbprint = $currentNavServerCertificateThumbprintElement.Value
            if (!$NavServerCertificateThumbprint)
            {
                if ((!$currentNavServerCertificateThumbprintElement) -or ($currentNavServerCertificateThumbprint.Trim() -eq ""))
                {
                    Write-Error "No certificate thumbprint was provided and the Nav Server instance has not been preconfigured with a certificate thumbprint."
                    return
                }

                $NavServerCertificateThumbprint = $currentNavServerCertificateThumbprint
            }
            else
            {
                $NavServerCertificateThumbprint = $NavServerCertificateThumbprint.Replace(" ","");
            }
        } 

        # If the certificate thumbprint is not null, get the certificate dns name.
        # This is needed ONLY when we also need to set up the NAV Web Server configuration.
        if (!$SkipWebServerConfiguration)
        {
            if (!$NavServerCertificateThumbprint)
            {
                Write-Error "Please provide a valid certificate thumbprint when skipping the Microsoft Dynamics NAV service configuration."
                return
            }

            $navServerCertificateDnsName = Get-NavCertificateDnsName -CertificateThumbprint $NavServerCertificateThumbprint
            if ((!$navServerCertificateDnsName) -or ($navServerCertificateDnsName.Trim() -eq ""))
            {
                Write-Error "Could not obtain the server certificate dns name from the Microsoft Dynamics NAV service certificate thumbprint."
                return
            }
        }
        
        # The MSOL connection is validated, based on the credentials that the user entered.
        $office365Credentials = Connect-Office365 -Office365UserName $AuthenticationEmail -Office365Password $AuthenticationEmailPassword -ErrorAction Stop
        
        # Find AAD tenant domain
		$aadTenantDomain = (Get-MsolCompanyInformation).InitialDomain        
		Write-Verbose "AAD tenant domain:  $aadTenantDomain"
      
        try
        {          		  
            if (!$SkipNavServerConfiguration)
            {
                # Backup config file
                Write-Verbose "Backing up"
                $backupDirectory = Backup-NavServerConfiguration -NavServerInstance $NavServerInstance
                Write-Verbose "under Id $backupDirectory"


                # Updating Nav User with Authentication
                if ($navUserEntry)
                {
                  Write-Verbose "`n1. Updating the Nav user for authentication"  

                  if (!(Set-NavUserWithOffice365User `
                      -NavServerInstance $NavServerInstance `
                      -NavTenant $NavTenant `
                      -NavUser $navUserEntry.UserName `
                      -AuthenticationEmail $office365Credentials.UserName `
                      -ErrorAction Stop))
                  {
                      Write-Error "Could not find Nav User $NavUser"
                  }
                }

                # Get server URL and AppIdUri
                $serverUrlHost = [System.Net.Dns]::GetHostName()
                $serverUrl = "http://$($serverUrlHost)/DynamicsNavServer"
                $serverAppIdUri = $serverUrl

                # Updating NST configuration settings
                Write-Verbose "`n2. Updating the NAV Server configuration"  
                Set-NavServerForSingleSignOn -NavServerInstance $NavServerInstance -AadTenantDomain $aadTenantDomain -NavServerCertificateThumbprint $NavServerCertificateThumbprint -AppIdUri $serverAppIdUri -ErrorAction Stop
                $isServerRestartAttempted = $true
                Write-Verbose "Restarting the NAV Server"
                Set-NavServerInstance -ServerInstance $NavServerInstance -Restart -ErrorAction Stop

                # Register the server as a service principal in AAD
                Write-Verbose "`n3. Updating the Server Application Service Principal in the AAD tenant"
                Set-AadServicePrincipalForSingleSignOn -AppIdUri $serverAppIdUri -AppReplyAddresses @($serverUrl) -ServicePrincipalDisplayName "Microsoft.Dynamics.Nav.Server" -ErrorAction Stop
            }

            if (!$SkipWebServerConfiguration)
            {
                $backupDirectory = Backup-NavWebServerConfig -NavWebServerInstance $NavWebServerInstanceName -BackupDirectory $backupDirectory
                # Updating Nav Web Server instance configuration
                Write-Verbose "`n4. Updating the NAV Instance Web Configuration"  
                # Get the Web Client base address(es). If there is no address specified as input, the URI(s) from the IIS configuration should be applied in the AAD Service Principal
                $replyAddressList = [Array](Get-AadReplyAddressesFromNavWebServerInstanceAddresses -UserSpecifiedNavAddress $NavWebAddress -NavWebServerInstanceAddresses $webServerInstance.Uri)
                Write-Verbose "The endpoint(s) for your Microsoft Dynamics NAV Web Server instance are: $replyAddressList"
                # Get The App ID URI from the NAV Web Server instance name. It will be in the form "http://<NAV_Web_Server_DNS>"
                $webServerAppIdUri = Get-AadAppIdUriFromNavWebServerInstanceUri -NavWebServerInstanceAddress $replyAddressList[0]
                Write-Verbose "The Application ID URI for your Microsoft Dynamics NAV Web Server instance is: $webServerAppIdUri"
                Set-NavWebServerInstanceForSingleSignOn -NavWebServerInstanceName $NavWebServerInstanceName -AadTenantDomain $aadTenantDomain -NavWebServerAppIdUri $webServerAppIdUri -CertificateDnsIdentity $navServerCertificateDnsName -ErrorAction Stop
     

                # Updating the addresses on server principal names on AAD
                Write-Verbose "`n5. Updating the Web Client Application Service Principal in the AAD tenant"
                Set-AadServicePrincipalForSingleSignOn -AppIdUri $webServerAppIdUri -AppReplyAddresses $replyAddressList -ServicePrincipalDisplayName "Microsoft.Dynamics.Nav.WebClient" -ErrorAction Stop
            }

            if (!$SkipWinClientConfiguration)
            {
                Write-Verbose "`n6. Updating the Windows Client Application Service Principal in the AAD tenant and returning the ACSUri value"
                $winClientAcsUri = Get-Office365AuthAcsUriForWinClient               
                # Write the AcsUri to the default windows client configuration file.
                Set-NavWinClientForSingleSignOn $winClientAcsUri
            }

            Write-Verbose "The configuration of Single Sign-on for Microsoft Dynamics NAV with Office 365 has successfully completed."
            Write-Verbose "In order to configure additional or user specific Windows Client for Office 365 authentication, copy the link returned by this cmdlet to the ACSUri configuration setting value."
            return $winClientAcsUri
        }
        catch 
        {
            Write-Verbose "Aborting. An error occured while processing the script."
            Write-Verbose "(Error Message: $_)"
            if ($backupDirectory)
			{
				Write-verbose "Restoring config files from backup under path $backupDirectory"
				# Restore backup of configuration 
				Restore-NavConfiguration -BackupDirectory $backupDirectory

                # Changing the certificate thumbprint is needed in order to redo the HTTP URLACL port reservations
                Set-NAVServerConfiguration -KeyName ServicesCertificateThumbprint -KeyValue $currentNavServerCertificateThumbprint -ServerInstance $NavServerInstance
                
                if ($isServerRestartAttempted)
                {
                    Write-Verbose "Restarting the NAV Server to complete the restore operation"
                    Set-NavServerInstance -ServerInstance $NavServerInstance -Restart -ErrorAction Stop
                }
			}

            if ($NavUser -and $NavServerInstance)
            {
                Write-Verbose "Reverting the NAV User Authentication Email"
			    Set-NAVServerUser -UserName $NavUser -ServerInstance $NavServerInstance -Tenant $NavTenant -AuthenticationEmail ""
            }

            throw
        }
    }
}

function ImportPrerequisites
{
    Import-Module MSOnline -ErrorVariable msOnlineInstallationError -ErrorAction SilentlyContinue
    if ($msOnlineInstallationError)
    {              
        # The error here needs to be a terminating error and at the same time be relevant and informative. That is why we are going to throw an exception.
        $errorMessage = "The prerequisites for validating the Office 365 tenant configuration are not installed on this computer." + `
			"`n`tMicrosoft Online Services Sign-In Assistant for IT Professionals can be downloaded and installed from" + `
			"`n`thttp://go.microsoft.com/fwlink/?LinkID=330113" + `
			"`n`tWindows Azure Active Directory Module for Windows PowerShell can be downloaded and installed from" + `
			"`n`thttp://go.microsoft.com/fwlink/?LinkID=330114"
        throw New-Object -TypeName System.Management.Automation.ItemNotFoundException -ArgumentList $errorMessage
    }

    Import-NAVManagementModule -ErrorAction Stop
    Import-Module WebAdministration -ErrorAction Stop
}

function Validate-NavWebServerInstance([string] $WebServerInstance)
{
    if (!$WebServerInstance)
    {
        $instance = Get-NAVWebServerInstance

        if ($instance.Count -and $instance.Count -gt 1)
        {
            return $null
        }
    }
    else
    {
        $instance = Get-NAVWebServerInstance -WebServerInstance $WebServerInstance
    }

    return $instance
}

function Get-AadAppIdUriFromNavWebServerInstanceUri([string] $NavWebServerInstanceAddress)
{
    # We are returning a scheme- and port- "insensitive" URI, such as http://<host>/<instance>/WebClient in order to make sure 
    # we are consistent no matter what the IIS bindings for the web site are.
    $navWebUri = New-Object -TypeName System.Uri -ArgumentList $NavWebServerInstanceAddress
    return "http://$($navWebUri.DnsSafeHost)$($navWebUri.AbsolutePath)"
}

function Get-AadReplyAddressesFromNavWebServerInstanceAddresses([string] $UserSpecifiedNavAddress, [string] $NavWebServerInstanceAddresses)
{
    if (!$UserSpecifiedNavAddress)
    {
        $replyAddressList = $NavWebServerInstanceAddresses.Split(',')
    }
    else 
    {
        $replyAddressList = @($UserSpecifiedNavAddress)
    }
    return $replyAddressList
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

Export-ModuleMember Set-NavSingleSignOnWithOffice365
# SIG # Begin signature block
# MIIa6AYJKoZIhvcNAQcCoIIa2TCCGtUCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUlMcOBmYE8cKh+AikbVAFSDpc
# NL6gghWCMIIEwzCCA6ugAwIBAgITMwAAAIliDZ6V02FrqAAAAAAAiTANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTUxMDA3MTgxNDAx
# WhcNMTcwMTA3MTgxNDAxWjCBszELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjENMAsGA1UECxMETU9QUjEnMCUGA1UECxMebkNpcGhlciBEU0UgRVNO
# Ojk4RkQtQzYxRS1FNjQxMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
# ZXJ2aWNlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiqp7T2zEl7js
# zoDvTfJqFbOWhzTKu+q/nUx7DdDt/kVvE8KWox66th8n+O6yqPx8hZ8oGbW8591g
# wDRk1XRsOmPXIm0zQN2qTYXPQJL8uwroK/2Rdj5TtsS1SJOLVmyVhLOVfIMtB99T
# XvIzhHGBeFpk4vZoCjBdW2E8+FsxX8SpeZ0H39yocJv584VTCqTy7wAKZlCRAflX
# qVi9MIq9AF9i2JtPgvSdmr+RjSTjoBi7Zbj825pcGtQeSA4t7akW2ZakGqPHQ7OM
# dKfX3wUgQgBb/UP+582bo7GIPMBXg0eN+GaezzjJeb3c4dGBfGdULyX1IdPbsKzz
# w3VlOODKpwIDAQABo4IBCTCCAQUwHQYDVR0OBBYEFOEoLyVNLefnHPQVNMj6gcN7
# 9bVDMB8GA1UdIwQYMBaAFCM0+NlSRnAK7UD7dvuzK7DDNbMPMFQGA1UdHwRNMEsw
# SaBHoEWGQ2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3Rz
# L01pY3Jvc29mdFRpbWVTdGFtcFBDQS5jcmwwWAYIKwYBBQUHAQEETDBKMEgGCCsG
# AQUFBzAChjxodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jv
# c29mdFRpbWVTdGFtcFBDQS5jcnQwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZI
# hvcNAQEFBQADggEBAEEtDA0RS25aDgdeTf+2Kiy3NxEJyGvynoi0SjwHjTMA0uuy
# 7R5bTBSNJH1WWdPGMkLtlP4UYNcFA3L6uBnbuSufF7g6UdvcShB66IHl1pa0VIUQ
# eithmSVYPzZNbaUmDONRH9AAvmgbMmChVkN+MYx/NITUlzWIrz3LDv/REx5jM47h
# q01rGm7S6iE2nH3nbq6Mp0ItWEOarkK7UAKLmYYCl6Vgz+IY/eF11Kw+BxZiQght
# B0p6IEjcgRZ1ONKyHGBpLVzp/hQUe1hvQFXq20uhe/tTFgra9gYakdypSzr1m7RW
# V7mCFDaVo6Oz+wjwULngfucZC9KdwhBzjEIqxOIwggTsMIID1KADAgECAhMzAAAB
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFAtt
# UAUQdS3WFxBazpu3OGLEOzTZMIGIBgorBgEEAYI3AgEMMXoweKBagFgATQBpAGMA
# cgBvAHMAbwBmAHQAIABEAHkAbgBhAG0AaQBjAHMAIABOAEEAVgAgAEMAbwBkAGUA
# cwBpAGcAbgAgAFMAdQBiAG0AaQBzAHMAcwBpAG8AbgAuoRqAGGh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbTANBgkqhkiG9w0BAQEFAASCAQBZhkzKcRa30cOjNEAYiBFb
# uMOpQQtDeboRHGS/q9vVmX4j7aKorzGvvsgmj/y1RjT559vI0DPJYD6NBxalvHLd
# tHAhIZYf3GyxqeERc7A8sE0d+dhNtxUUwiaqnTn+HC6Y77PjZo5Z04YakKGsTEP2
# YwQue2trfhZYP3nnXqpmNmHChEEc4fqge6GQKNubXymW6cmjbP4HH0JM2JJKMWwB
# DoMdhsBctjEiMI3uO7pg1RMSGMeA7TJNAjHbIq27Xss2yWMqFpZsSdxJ0Lsf1CeG
# 1kVf/kkqU6rJ/qWqYj6URA6R3PQeFlXdT8hiJ2G0XnFJPSfWGMHN3GqLjsioLZEX
# oYICKDCCAiQGCSqGSIb3DQEJBjGCAhUwggIRAgEBMIGOMHcxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFBDQQITMwAAAIliDZ6V02FrqAAAAAAAiTAJBgUrDgMCGgUAoF0wGAYJ
# KoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMTUxMDIzMTQz
# NDI1WjAjBgkqhkiG9w0BCQQxFgQUAT7j1DmBfB75YN7meXDJtRyzufYwDQYJKoZI
# hvcNAQEFBQAEggEAiPi9EF1StIvqnmNWFxrFNbSnMasDyM0LPU6d8JjqE9jA99O1
# x2ydKawPuGFrLddmAsrCzneeg15k+P8R2SQAptgwYzrKkFsIDaJc4MVh2QtFnL4x
# YTM1RGLbs/ZwSzFIMmymP9Zf/Sy0HExnicjq9BS3VwpkI3y1AI+dNXSFTWlbSAWt
# mPTZR3jkVezPn2gb3cbF4dytcm0gT1LVpcf+grW8RU9nt+k7VyhriITY9kBJu7aN
# KTp5FXpeeHEuDyQDTvgGUFdpiRZvz0pFJmJ8blcFFzF1/XgRkOA17Mo3TWWCC2m+
# 90h9ee7jwcGHh8mvufmw0iOGTLfh0vMyloHF0A==
# SIG # End signature block
