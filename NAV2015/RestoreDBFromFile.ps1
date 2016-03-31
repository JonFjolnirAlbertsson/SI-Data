function RestoreDBFromFile
{
    [CmdletBinding()]
    param([string] $servername = "localhost",[string] $dbNewname,[string] $backupFile )
    PROCESS
    {
        try
        { 
            Import-Module "SQLRenameLogicalFileName.ps1"

            # Load assemblies
            [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null
            [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
            [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
            [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null

            #SQL server object
            [Microsoft.SqlServer.Management.Smo.Server]$server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") "(local)"

            $backupDevice = New-Object ("Microsoft.SqlServer.Management.Smo.BackupDeviceItem") ($backupFile, "File")
            $smoRestore = New-Object Microsoft.SqlServer.Management.Smo.Restore

            $smoRestore.NoRecovery = $false;
            $smoRestore.ReplaceDatabase = $true;
            $smoRestore.Action = "Database"
            $smoRestore.PercentCompleteNotification = 10;
            $smoRestore.FileNumber = 0
            $smoRestore.Devices.Add($backupDevice)

            # Get the details from the backup device for the database name and output that
            $smoRestoreDetails = $smoRestore.ReadBackupHeader($server)
            "Database Name from Backup Header : " + $databaseName

            $smoRestore.Database = $dbNewname
            $logicalFileNameList = $smoRestore.ReadFileList($server)

            $PostFix = ""
            [Int] $PostFixNumber = 0; 

            foreach($row in $logicalFileNameList)
            { 
               $fileType = $row["Type"].ToUpper()
    
               if ($fileType.Equals("D")) 
               {
                  $dbLogicalName = $row["LogicalName"]
                  $smoRestoreFile = New-Object("Microsoft.SqlServer.Management.Smo.RelocateFile") 
                  $smoRestoreFile.LogicalFileName = $dbLogicalName
                  $smoRestoreFile.PhysicalFileName = $server.Information.MasterDBPath + "\" + $dbNewname+ $PostFix + "_Data.mdf"
                  #$smoRestoreFile | Format-Table -Autosize
                  "File number " + $smoRestore.RelocateFiles.Add($smoRestoreFile) + " added to Files"
                  $PostFixNumber = $PostFixNumber + 1
                  $PostFix = "_" + $PostFixNumber
               }
               elseif ($fileType.Equals("L")) 
               {
                  $logLogicalName = $row["LogicalName"]
                  $smoRestoreLog = New-Object("Microsoft.SqlServer.Management.Smo.RelocateFile")
                  $smoRestoreLog.LogicalFileName = $logLogicalName
                  $smoRestoreLog.PhysicalFileName = $server.Information.MasterDBPath + "\" + $dbNewname  + "_Log.ldf"
                  #$smoRestoreLog | Format-Table -Autosize
                  "File number " + $smoRestore.RelocateFiles.Add($smoRestoreLog) + " added to Files"
               } 
            }

            $server.KillAllProcesses($dbNewname)
            $server.ConnectionContext.StatementTimeout = 0
            $smoRestore.SqlRestore($server)
          
            RenameLogicalFileName -DBName $dbNewname
            "Database '$dbName' restored from the file '$backupFile'"
        }
        catch [Exception]
        {
            "Database '$dbName' restored from the file '$backupFile' :`n`n " + $_.Exception
        }
        finally
        {
            # Clean up copied backup file after restore completes successfully
        }
    }
}
