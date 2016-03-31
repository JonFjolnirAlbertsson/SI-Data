 function EnableBroker
{
    [CmdletBinding()]
    param([string] $servername = "localhost",[string] $DBName)
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
 
            $dbCommand = "ALTER DATABASE [$dbname] SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE"

            Invoke-Sqlcmd -Query $dbCommand

            #SET DISABLE_BROKER

            "Broker enabled on database $DBName"
        }
        catch [Exception]
        {
            "Broker enabled on database :`n`n " + $_.Exception
        }
        finally
        {
            # Clean up copied backup file after restore completes successfully
        }
    }
}