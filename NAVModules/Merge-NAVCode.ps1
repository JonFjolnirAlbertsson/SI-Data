<#
.Synopsis
   Split Original, Modified and Target object file. Creates Folder structure under the working folder
.DESCRIPTION
   Uses standard NAV upgrade objects functions
.NOTES
   
.PREREQUISITES
   
#>
function Merge-NAVCode
{
    [CmdletBinding()]
    param(
        [string] $WorkingFolderPath, 
        [string] $OriginalFileName,
        [string] $ModifiedFileName,
        [string] $TargetFileName,
        [UpgradeAction] $UpgradeAction = [UpgradeAction]::Split,
        [string] $CompareObject = "*.TXT",
        [Switch] $OpenConflictFilesInKdiff,
        [Switch] $RemoveModifyFilesNotInTarget,
        [Switch] $RemoveOriginalFilesNotInTarget
        )
    PROCESS
    {
        try
        { 
            #Programs to use
            $NotepadPlus = Join-Path 'C:\Program Files (x86)\Notepad++' 'notepad++.exe'
            $Kdiff = Join-Path 'C:\Program Files\KDiff3' 'kdiff3.exe'

            # Set the right folder path based on company folder and files name
            $SourceOriginal = $OriginalFileName
            $SourceModified = $ModifiedFileName
            $SourceTarget = $TargetFileName

            $DestinationOriginal = $WorkingFolderPath  + "\Original\"
            $DestinationModified =  $WorkingFolderPath  + "\Modified\"
            $DestinationTarget =  $WorkingFolderPath  + "\Target\"

            $Delta =  $WorkingFolderPath  + "\Delta\"
            $Result =  $WorkingFolderPath + "\Result\"
            $Merged =  $WorkingFolderPath  + "\Merged\"

            # Check if folders exists. If not create them.
            if(!(Test-Path -Path $DestinationOriginal )){
                New-Item -ItemType directory -Path $DestinationOriginal
            }
            if(!(Test-Path -Path $DestinationModified )){
                New-Item -ItemType directory -Path $DestinationModified
            }
            if(!(Test-Path -Path $DestinationTarget )){
                New-Item -ItemType directory -Path $DestinationTarget
            }
            if(!(Test-Path -Path $Delta )){
                New-Item -ItemType directory -Path $Delta
            }
            if(!(Test-Path -Path $Result )){
                New-Item -ItemType directory -Path $Result
            }
            if(!(Test-Path -Path $Merged )){
                New-Item -ItemType directory -Path $Merged
            }

            #Set Source, modified, target and result values
            $OriginalCompareObject = $DestinationOriginal + $CompareObject
            $ModifiedCompareObject = $DestinationModified + $CompareObject
            $TargetCompareObject = $DestinationTarget + $CompareObject
            $DeltaUpdateObject = $Delta + $UpdateObject
            $JoinPath = $Merged + "ToBeJoined\"
            $JoinSource = $JoinPath + $CompareObject
            $JoinDestination = $RootFolderPath + "all-merged-objects.txt"

            if(!(Test-Path -Path $JoinPath )){
                New-Item -ItemType directory -Path $JoinPath
            }   

            $CODFolder = $Result + "COD\"
            $TABFolder = $Result + "TAB\"
            $PAGFolder = $Result + "PAG\"
            $REPFolder = $Result + "REP\"

            # Split text files with many objects
            If($UpgradeAction -eq "Split")
            {
                write-host "Removing items from the folder $DestinationOriginal*.*" -foregroundcolor "white"
                Remove-Item -Path "$DestinationOriginal*.*" 
                write-host "Removing items from the folder $DestinationModified*.*" -foregroundcolor "white"
                Remove-Item -Path "$DestinationModified*.*"
                write-host "Removing items from the folder $DestinationTarget*.*" -foregroundcolor "white"
                Remove-Item -Path "$DestinationTarget*.*"

                Split-NAVApplicationObjectFile  -Source $SourceOriginal -Destination $DestinationOriginal -PreserveFormatting -Force
                Split-NAVApplicationObjectFile  -Source $SourceModified -Destination $DestinationModified -PreserveFormatting -Force
                Split-NAVApplicationObjectFile  -Source $SourceTarget -Destination $DestinationTarget -PreserveFormatting -Force
    
                write-host "The source file $SourceOriginal has been split to the destination $DestinationOriginal" -foregroundcolor "white" 
                write-host "The source file $SourceModified has been split to the destination $DestinationModified" -foregroundcolor "white"
                write-host "The source file $SourceTarget has been split to the destination $DestinationModified" -foregroundcolor "white"
            }
            ElseIf($UpgradeAction -eq "Merge")
            {
                write-host "Empty the folder for result files" -foregroundcolor "white" 
                Remove-Item -Path "$Result*" -recurse

                if ($OpenConflictFilesInKdiff)
                {
                    $ResultFiles = Merge-NAVApplicationObject -Modified $ModifiedCompareObject -Original $OriginalCompareObject -Result $Result -Target $TargetCompareObject -DateTimeProperty FromTarget -ModifiedProperty FromModified -VersionListProperty FromTarget -Force 
				    Write-Host "`nOpen NOTEPAD for each CONFLICT file" -foreground Green
				    # Open NOTEPAD for each CONFLICT file
                    #Write-Host $ResultFiles.Count  
                    #if ($ResultFiles.Count  > 2)
                    #{
                    #   write-host "There are to many conflicts files (" + $ResultFiles.Count + ") to open in Kdiff" -foregroundcolor "white"  
                    #}
                    #else
                    #{ 
				        $ResultFiles | 
					        Where-Object MergeResult -eq 'Conflict' | 
					        #foreach { NOTEPAD $_.Conflict }
                            foreach {& $NotepadPlus $_.Conflict}

				        Write-Host "`nOpen three-way merge-tool KDIFF3 for each object with conflict(s)" -foreground Green
				        Write-Host "  Note: The example, KDIFF3, is a free merge tool available here: http://kdiff3.sourceforge.net/" -foreground Green
				        # Open three-way merge-tool KDIFF3 for each object with conflict(s)
				        $ResultFiles | 
					        Where-Object MergeResult -eq 'Conflict' | 
					        #foreach { & "C:\Program Files\KDiff3\kdiff3" $_.Original $_.Modified $_.Target -o $_.Result }
                            foreach {& $Kdiff $_.Original $_.Modified $_.Target -o  (join-path $Merged (Get-Item $_.Original.FileName).Name) }
                    #}
                }else
                {
                    Merge-NAVApplicationObject -Modified $ModifiedCompareObject -Original $OriginalCompareObject -Result $Result -Target $TargetCompareObject -DateTimeProperty FromTarget -ModifiedProperty FromModified -VersionListProperty FromTarget -Force
                }
                write-host "Creating the folder $CODFolder or deleting all files in the folde. " -foregroundcolor "white" 
                New-Item -Path $CODFolder -ItemType directory -Force | out-null
                Remove-Item -Path "$CODFolder*.*"
                write-host "Creating the folder $TABFolder or deleting all files in the folde. " -foregroundcolor "white" 
                New-Item -Path $TABFolder -ItemType directory -Force | out-null
                Remove-Item -Path "$TABFolder*.*"
                write-host "Creating the folder $PAGFolder or deleting all files in the folde. " -foregroundcolor "white" 
                New-Item -Path $PAGFolder -ItemType directory -Force | out-null
                Remove-Item -Path "$PAGFolder*.*"   
                write-host "Creating the folder $REPFolder or deleting all files in the folde. " -foregroundcolor "white" 
                New-Item -Path $REPFolder -ItemType directory -Force | out-null
                Remove-Item -Path "$REPFolder*.*"

                #get-childitem  -path $Result  | where-object {$_.Name -like "COD*.*"} | Out-Default
                get-childitem  -path $Result  | where-object {$_.Name -like "COD*.*"} | Move-Item -Destination $CODFolder -Force | out-null
                get-childitem  -path $Result  | where-object {$_.Name -like "TAB*.*"} | Move-Item -Destination $TABFolder -Force | out-null
                get-childitem  -path $Result  | where-object {$_.Name -like "PAG*.*"} | Move-Item -Destination $PAGFolder -Force | out-null
                get-childitem  -path $Result  | where-object {$_.Name -like "REP*.*"} | Move-Item -Destination $REPFolder -Force | out-null
    
                write-host "The filter used to merge files was $CompareObject"  -foregroundcolor "white" 
                write-host "Below you can see were the source files come from ..."  -foregroundcolor "white" 
                write-host $OriginalCompareObject  -foregroundcolor "white" 
                write-host $ModifiedCompareObject  -foregroundcolor "white" 
                write-host $TargetCompareObject  -foregroundcolor "white" 
                write-host "The merged files are found in the folder $Result, and the related subfolders (COD,TAB,PAG and REP)." -foregroundcolor "white" 

                write-host "Remember!" 
                write-host "After the script has run the result files should be compared." 
                write-host "The result files should be compared to the Modified file and the target file."
                
				Write-Host "`nCompare ORIGINAL and MODIFIED and merge onto TARGET, then put the merged files in RESULT" -foreground Green
				# Compare ORIGINAL and MODIFIED and merge onto TARGET, then put the merged files in RESULT            

            }
            ElseIf($UpgradeAction -eq "Join")
            {
                
                #Move and copy item to the join folder
                write-host "Moving files from the folder $CODFolder to the folder $JoinPath" -foregroundcolor "white"
                get-childitem  -path $CODFolder  | where-object {$_.Name -like "COD*.TXT"} | Move-Item -Destination $JoinPath -Force | out-null
                write-host "Moving files from the folder $TABFolder to the folder $JoinPath" -foregroundcolor "white"
                get-childitem  -path $TABFolder  | where-object {$_.Name -like "TAB*.TXT"} | Move-Item -Destination $JoinPath -Force | out-null
                write-host "Moving files from the folder $PAGFolder to the folder $JoinPath" -foregroundcolor "white"
                get-childitem  -path $PAGFolder  | where-object {$_.Name -like "PAG*.TXT"} | Move-Item -Destination $JoinPath -Force | out-null
                write-host "Moving files from the folder $REPFolder to the folder $JoinPath" -foregroundcolor "white"
                get-childitem  -path $REPFolder  | where-object {$_.Name -like "REP*.TXT"} | Move-Item -Destination $JoinPath -Force | out-null
                write-host "Moving files from the folder $Result to the folder $JoinPath" -foregroundcolor "white"
                get-childitem  -path $Result  | where-object {$_.Name -like "*.TXT"} | Move-Item -Destination $JoinPath -Force | out-null
                

                if ($RemoveOriginalFilesNotInTarget)
                {
                    write-host "Delete standard object files from previous version that that do not exists in Target version." -foregroundcolor "white"
                    write-host "Starting comparing files from  the original folder $DestinationOriginal with the files in the target folder $DestinationTarget" -foregroundcolor "white"
                    write-host "The files will be removed from the folder $JoinPath" -foregroundcolor "white"
                    write-host "This process can take some minutes ..." -foregroundcolor "white"
                    $CompOriginal = Get-ChildItem -Recurse -path $DestinationOriginal | where-object {$_.Name -like $CompareObject}
                    $CompTarget = Get-ChildItem -Recurse -path $DestinationTarget | where-object {$_.Name -like $CompareObject}
                    $results = @(Compare-Object  -casesensitive -ReferenceObject $CompOriginal -DifferenceObject $CompTarget)
                    [String] $MessageStr = ""
                    [String] $RemovePath = ""
                    foreach($result in $results)
                    {
                        $i++
                        #$MessageStr = "Processing file " + $result.InputObject + "  " + $result.SideIndicator + " from the $JoinPath folder."  
                        #if ($result.SideIndicator -eq "<=")
                        #{
                            $RemovePath = $JoinPath + $result.InputObject
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
                    $RemovePath  = $JoinPath + "TAB15000008.TXT"
                    $MessageStr = "Deleting the file $RemovePath." 
                    Write-Host $MessageStr -foregroundcolor "yellow"    
                    if((Test-Path -Path $RemovePath)){remove-item -path $RemovePath -force} else {$MessageStr = "The file $RemovePath does not exists."}
                    $RemovePath  = $JoinPath + "PAG15000008.TXT"
                    $MessageStr = "Deleting the file $RemovePath." 
                    Write-Host $MessageStr -foregroundcolor "yellow"    
                    if((Test-Path -Path $RemovePath)){remove-item -path $RemovePath -force} else {$MessageStr = "The file $RemovePath does not exists."}
                }
                if ($RemoveModifyFilesNotInTarget)
                {
                    write-host "Remove object files from previous versions that are found in the Modify folder but not in the Target folder" -foregroundcolor "white"  
                    write-host "Starting removing files from previous versions. The files in the range 1..49999 will be removed from the folder $JoinPath" -foregroundcolor "white"
                    write-host "This process can take some minutes ..." -foregroundcolor "white"  
                  
                    $ComparingStr = '[A-Z][A-Z][A-Z](\d+)\.TXT'
                    $range = 1..49999
                    $CompModified = Get-ChildItem -Recurse -path $DestinationModified | where-object {$_.Name -like $CompareObject -and $range -contains ($_.name -replace $ComparingStr,'$1')}
                    $CompTarget = Get-ChildItem -Recurse -path $DestinationTarget | where-object {$_.Name -like $CompareObject -and $range -contains ($_.name -replace $ComparingStr,'$1')} 
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
                }
                write-host "Copy manually merged objects to the join folder" -foregroundcolor "white"
                write-host "Copying files from the folder $Merged to the folder $JoinPath" -foregroundcolor "white"
                get-childitem  -path $Merged   | where-object {$_.Name -like "*.TXT"} | Copy-Item -Destination $JoinPath

                write-host "Joining all files in the folder $JoinSource into the file $JoinDestination" -foregroundcolor "white"
                write-host "The filter used to join files is $CompareObject" -foregroundcolor "white"
                Join-NAVApplicationObjectFile -Source $JoinSource -Destination $JoinDestination -Force          
            }
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