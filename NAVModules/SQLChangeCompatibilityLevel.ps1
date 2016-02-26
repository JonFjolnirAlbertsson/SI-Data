function ChangeDBCompatibilityLevel
{
    [CmdletBinding()]
    param([string] $servername = "localhost",[string] $DBName, [int] $level = 110)
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

            $DataBase = $server.Databases | where-Object  {$_.Name -eq $dbName} 
            $DataBase.CompatibilityLevel = 110 #SQL 12
            $DataBase.Alter();

            "Compatibility level changed for Database '$dbName' to level '$level'"
        }
        catch [Exception]
        {
            "Compatibility level changed for Database '$dbName' to level '$level' :`n`n " + $_.Exception
        }
        finally
        {
            # Clean up copied backup file after restore completes successfully
        }
    }
}
