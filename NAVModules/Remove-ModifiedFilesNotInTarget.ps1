function Remove-ModifiedFilesNotInTarget
{
    [CmdletBinding()]
    param(
        [string] $WorkingFolderPath, 
        [string] $ModifiedFolder,
        [string] $TargetFolder,
        [string] $CompareObject = "*.TXT"
        )
    PROCESS
    {
        try
        { 
            # Set the right folder path based on company folder and files name
            $Merged =  $WorkingFolderPath  + "\Merged\"

            #Set Source, modified, target and result values
            $JoinPath = $Merged + "ToBeJoined\"

            if(!(Test-Path -Path $JoinPath )){
                New-Item -ItemType directory -Path $JoinPath
            }   

                
            write-host "Remove object files from previous versions that are found in the Modify folder but not in the Target folder" -foregroundcolor "white"  
            write-host "Starting removing files from previous versions. The files in the range 1..49999 will be removed from the folder $JoinPath" -foregroundcolor "white"
            write-host "This process can take some minutes ..." -foregroundcolor "white"  
                  
            $ComparingStr = '[A-Z][A-Z][A-Z](\d+)\.TXT'
            $range = 1..49999
            $CompModified = Get-ChildItem -Recurse -path $ModifiedFolder | where-object {$_.Name -like $CompareObject -and $range -contains ($_.name -replace $ComparingStr,'$1')}
            $CompTarget = Get-ChildItem -Recurse -path $TargetFolder | where-object {$_.Name -like $CompareObject -and $range -contains ($_.name -replace $ComparingStr,'$1')} 
            $results = @(Compare-Object  -casesensitive -ReferenceObject $CompModified -DifferenceObject $CompTarget -property name -passThru)
            [String] $MessageStr = ""
            [String] $RemovePath = ""
            foreach($result in $results)
            {
                $i++
                #$MessageStr = "Processing file " + $result.InputObject + "  " + $result.SideIndicator + " from the $JoinPath folder."  
                #if ($result.SideIndicator -eq "<=")
                #{
                    $RemovePath = $JoinPath + $result.name
                    $MessageStr = "Deleting the file $RemovePath. The SideIndicator is " + $result.SideIndicator + "."  
                    if((Test-Path -Path $RemovePath)){
                            remove-item -path $RemovePath -force
                    }else {
                        $MessageStr = "The file $RemovePath, with the SideIndicator " + $result.SideIndicator + " does not exists."
                    }                                          
                #}
                Write-Host $MessageStr -foregroundcolor "yellow"
                #Write-Progress -activity $MessageStr -status "Percent added: " -PercentComplete (($i / $results.Length)  * 100)
                    
            }                         
            write-host "Copy manually merged objects to the join folder" -foregroundcolor "white"
            write-host "Copying files from the folder $Merged to the folder $JoinPath" -foregroundcolor "white"
            get-childitem  -path $Merged   | where-object {$_.Name -like "*.TXT"} | Copy-Item -Destination $JoinPath
   
            write-host "Execution finished."
        }
        catch [Exception]
        {
            write-host "Merged failed with the error :`n`n " + $_.Exception
        }
        finally
        {
            # Clean up copied backup file after restore completes successfully
        }
    }
}