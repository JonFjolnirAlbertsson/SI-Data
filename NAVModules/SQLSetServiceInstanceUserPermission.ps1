function SetNAVServiceUserPermission
{
    [CmdletBinding()]
    param([string] $DatabaseServer = "localhost",[string] $DBName, [String] $ADUser = "NT-MYNDIGHET\NETTVERKSTJENESTE")
    PROCESS
    {
        try
        { 
            # Load assemblies
            [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
            [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
            [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
            [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null

            #SQL server object
            [Microsoft.SqlServer.Management.Smo.Server]$server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") "(local)"
            <#
            try
            {
                $DataBase = $server.Databases | where-Object  {$_.Name -eq 'master'}

                $dbCommand = 'USE [master]'
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
                $dbCommand = 'GO'
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
             
                $dbCommand = 'CREATE SCHEMA [$ndo$navlistener]' + " AUTHORIZATION [$ADUser]" 
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
            }
            catch
            {
                "Failed to CREATE SCHEMA [$ndo$navlistener] AUTHORIZATION [$ADUser]" 
            }
            #>
            try
            {
                $dbCommand = "USE [master]"
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
                $dbCommand = 'GO'
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name

                $dbCommand = "CREATE LOGIN [$ADUser] FROM WINDOWS" 
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
                $dbCommand = 'GO'
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
            }
            catch
            {
                "Failed to CREATE LOGIN [$ADUser] FROM WINDOWS" 
            }

            try
            {
                $dbCommand = "USE [master]"
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
                $dbCommand = 'GO'
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name

                $dbCommand = "CREATE USER [$ADUser] FOR LOGIN [$ADUser]" 
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
                $dbCommand = 'GO'
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
            }
            catch
            {
                "Failed to CREATE USER [$ADUser] FOR LOGIN [$ADUser]" 
            }

            try
            {
                $dbCommand = "USE [master]"
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
                $dbCommand = 'GO'
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name

                $dbCommand = "GRANT SELECT ON [master].[dbo].[" +'$ndo$srvproperty' + "] TO [$ADUser]" 
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
                $dbCommand = 'GO'
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name

            }
            catch
            {
                "Failed to GRANT SELECT ON [master].[dbo].[" +'$ndo$srvproperty' + "] TO [$ADUser]" 
            }
            $DataBase = $server.Databases | where-Object  {$_.Name -eq $DBName}
            try
            {
                $dbCommand = "USE [$DBName]"
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
                $dbCommand = 'GO'
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name

                $dbCommand = "CREATE USER [$ADUser] FOR LOGIN [$ADUser]" 
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
                $dbCommand = 'GO'
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name

            }
            catch
            {
                "Failed to GRANT SELECT ON [master].[dbo].[ +'$ndo$srvproperty' + ] TO [$ADUser]" 
            }

            try
            {
                $dbCommand = "USE [$DBName]"
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
                $dbCommand = 'GO'
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name

                $dbCommand = "ALTER USER [$ADUser] WITH DEFAULT_SCHEMA = " + '[$ndo$navlistener]'
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
                $dbCommand = 'GO'
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name

                $dbCommand = "GRANT SELECT ON [$DBName].dbo.[Object Tracking] TO [$ADUser]"
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
                $dbCommand = 'GO'
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name

                $dbCommand = "ALTER ROLE [db_owner] ADD MEMBER [$ADUser]"
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
                $dbCommand = 'GO'
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name

                $dbCommand = "GRANT VIEW DATABASE STATE TO [$ADUser]"
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name
                $dbCommand = 'GO'
                Invoke-Sqlcmd -Query $dbCommand -Database $DataBase.Name

                "Set Service instance user permission on Database '$DBName' for the user '$ADUser'"
            }
            catch
            {
                "Failed to to set Service instance user permission on Database '$DBName' for the user '$ADUser'"
            }

        }
        catch [Exception]
        {
            "Failed to set Service instance user permission on Database '$DBName' for the user '$ADUser' :`n`n " + $_.Exception
        }
        finally
        {
            # Clean up copied backup file after restore completes successfully
        }
    }
}

