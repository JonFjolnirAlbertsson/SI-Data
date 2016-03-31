function RenameLogicalFileName
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
            #$database = Get-Item("sqlserver:\sql\$servername\$instance\databases\$dbname");

            $database = $server.Databases[$dbname];
            [Microsoft.SqlServer.Management.SMO.LogFile] $lf1 = $database.LogFiles[$LoglogicalName] 

            [string] $dbCommand = ""

            foreach ($DBLF in $database.logfiles) {
              $LogFileName = $DBLF.Name
              $NewLoglogicalName = $LogFileName.Replace(".ldf","")
             
              $dbCommand = "ALTER DATABASE [$dbname] MODIFY FILE (NAME=N'$LogFileName', NEWNAME=N'$NewLoglogicalName')"
              Invoke-Sqlcmd -Query $dbCommand
 
              $DBLF | ft
              #$DBLF.Alter()
             }
 
             $PostFix = ""
             [Int] $PostFixNumber = 0; 
             $DBFG = $database.FileGroups;
                foreach ($DBF in $DBFG.Files) {
              #$DBF.set_Growth("102400"); #100mb 
              $DataFileName = $DBF.Name
              $NewDataFileLogicalName = $DataFileName.Replace(".mdf","")
              
              $dbCommand = "ALTER DATABASE [$dbname] MODIFY FILE (NAME=N'$DataFileName', NEWNAME=N'$NewDataFileLogicalName')"
              Invoke-Sqlcmd -Query $dbCommand

 
              $DBF | ft
              #$DBF.Alter()
              $PostFixNumber = $PostFixNumber + 1
              $PostFix = "_" + $PostFixNumber
             }
            #$database.Alter()
            #Write-Host "File Renamed"

            "Database Logical file names renamed successfully"
        }
        catch [Exception]
        {
            "Database Logical file names renamed :`n`n " + $_.Exception
        }
        finally
        {
            # Clean up copied backup file after restore completes successfully
        }
    }
}
#Export-ModuleMember -Function RenameLogicalFileName
