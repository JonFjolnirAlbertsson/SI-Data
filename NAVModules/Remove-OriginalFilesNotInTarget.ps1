function Remove-OriginalFilesNotInTarget
{
    [CmdletBinding()]
    param(
        [string] $WorkingFolderPath, 
        [string] $OriginalFolder,
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

                
            write-host "Delete standard object files from previous version that that do not exists in Target version." -foregroundcolor "white"
            write-host "Starting comparing files from  the original folder $DestinationOriginal with the files in the target folder $TargetFolder" -foregroundcolor "white"
            write-host "The files will be removed from the folder $JoinPath" -foregroundcolor "white"
            write-host "This process can take some minutes ..." -foregroundcolor "white"
            $CompOriginal = Get-ChildItem -Recurse -path $OriginalFolder | where-object {$_.Name -like $CompareObject}
            $CompTarget = Get-ChildItem -Recurse -path $TargetFolder | where-object {$_.Name -like $CompareObject}
            $results = @(Compare-Object  -casesensitive -ReferenceObject $CompOriginal -DifferenceObject $CompTarget -property Name -passThru)
            [String] $MessageStr = ""
            [String] $RemovePath = ""
            foreach($result in $results)
            {
                $i++
                #$MessageStr = "Processing file " + $result.InputObject + "  " + $result.SideIndicator + " from the $JoinPath folder."  
                #if ($result.SideIndicator -eq "<=")
                #{
                    $RemovePath = $JoinPath + $result.Name
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
            $RemovePath  = $JoinPath + "MEN1010.TXT"  
            $MessageStr = "Deleting the file $RemovePath." 
            Write-Host $MessageStr -foregroundcolor "yellow"
            if((Test-Path -Path $RemovePath)){remove-item -path $RemovePath -force} else {$MessageStr = "The file $RemovePath does not exists."}
            $RemovePath  = $JoinPath + "MEN1030.TXT"  
            $MessageStr = "Deleting the file $RemovePath." 
            Write-Host $MessageStr -foregroundcolor "yellow"    
            if((Test-Path -Path $RemovePath)){remove-item -path $RemovePath -force} else {$MessageStr = "The file $RemovePath does not exists."}
            #$RemovePath  = $JoinPath + "TAB15000008.TXT"
            #$MessageStr = "Deleting the file $RemovePath." 
            #Write-Host $MessageStr -foregroundcolor "yellow"    
            #if((Test-Path -Path $RemovePath)){remove-item -path $RemovePath -force} else {$MessageStr = "The file $RemovePath does not exists."}
            #$RemovePath  = $JoinPath + "PAG15000008.TXT"
            #$MessageStr = "Deleting the file $RemovePath." 
            #Write-Host $MessageStr -foregroundcolor "yellow"    
            #if((Test-Path -Path $RemovePath)){remove-item -path $RemovePath -force} else {$MessageStr = "The file $RemovePath does not exists."}
   
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