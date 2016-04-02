<#
.Synopsis
   Open Target, Original,Result and Merged File in Notepad++ and/or Kdiff
.DESCRIPTION
   Open Target, Original,Result and Merged File in Notepad++ and/or Kdiff
.NOTES
   
.PREREQUISITES
   
#>
function Open-File-SID
{
    [CmdletBinding()]
    param(
        [string] $WorkingFolderPath, 
        [string] $ObjectName,
        [Switch] $OpenOriginal,
        [Switch] $OpenModified,
        [Switch] $OpenTarget,
        [Switch] $OpenMerged,
        [Switch] $OpenResult,
        [Switch] $OpenToBeJoined,
        [Switch] $OpenInNotepadPlus,
        [Switch] $OpenInKdiff,
        [Switch] $OpenMergedInKdiff
        )
    PROCESS
    {
        try
        { 
            $NotepadPlus = Join-Path 'C:\Program Files (x86)\Notepad++' 'notepad++.exe'
            $Kdiff = Join-Path 'C:\Program Files\KDiff3' 'kdiff3.exe'
            
            $Original = "$WorkingFolderPath\Original\$ObjectName.TXT"
            $Modified = "$WorkingFolderPath\Modified\$ObjectName.TXT"
            $Target = "$WorkingFolderPath\Target\$ObjectName.TXT"
            $Merged = "$WorkingFolderPath\Merged\$ObjectName.TXT"
            $ToBeJoined = "$WorkingFolderPath\Merged\ToBeJoined\$ObjectName.TXT"
            $Result = "$WorkingFolderPath\Result\TAB\$ObjectName.TXT"

            if($OpenOriginal) 
            {
                $FileArgs = $Original
                #$KdiffFileArgs = join-path $WorkingFolderPath "\Original\$ObjectName.TXT"
            }
            if($OpenModified) 
            {
                if($FileArgs)
                {
                    $FileArgs = $FileArgs, $Modified
                    #$KdiffFileArgs =  $KdiffFileArgs + ' ' + (join-path $WorkingFolderPath "\Modified\$ObjectName.TXT")
                }
                else
                {
                    $FileArgs = $Modified
                    #$KdiffFileArgs =  (join-path $WorkingFolderPath "\Modified\$ObjectName.TXT")
                }
            }
            if($OpenTarget) 
            {
                if($FileArgs)
                {
                    $FileArgs = $FileArgs, $Target
                    #$KdiffFileArgs =  $KdiffFileArgs + ' ' + (join-path $WorkingFolderPath "\Target\$ObjectName.TXT")
                }
                else
                {
                    $FileArgs = $Target
                    #$KdiffFileArgs =  (join-path $WorkingFolderPath "\Target\$ObjectName.TXT")
                }
            }
            if($OpenMerged) 
            {
                if($FileArgs)
                {
                    $FileArgs = $FileArgs, $Merged
                    #$KdiffFileArgs =  $KdiffFileArgs + ' ' + (join-path $WorkingFolderPath "\Merged\$ObjectName.TXT")
                }
                else
                {
                    $FileArgs = $Merged
                    #$KdiffFileArgs =  (join-path $WorkingFolderPath "\Merged\$ObjectName.TXT")
                }
            }
            if($OpenResult) 
            {
                if($FileArgs)
                {
                    $FileArgs = $FileArgs, $Result
                    #$KdiffFileArgs =  $KdiffFileArgs + ' ' + (join-path $WorkingFolderPath "\Result\$ObjectName.TXT")
                }
                else
                {
                    $FileArgs = $Result
                    #$KdiffFileArgs =  (join-path $WorkingFolderPath "\Result\$ObjectName.TXT")
                }
            }

            if($OpenToBeJoined) 
            {
                if($FileArgs)
                {
                    $FileArgs = $FileArgs, $ToBeJoined
                    #$KdiffFileArgs =  $KdiffFileArgs + ' ' + (join-path $WorkingFolderPath "\Result\$ObjectName.TXT")
                }
                else
                {
                    $FileArgs = $ToBeJoined
                    #$KdiffFileArgs =  (join-path $WorkingFolderPath "\Result\$ObjectName.TXT")
                }
            }

            if($OpenInNotepadPlus)
            {
                & $NotepadPlus $FileArgs                     
            }

            if($OpenInKdiff -or $OpenMergedInKdiff)
            {
                if($OpenMergedInKdiff)
                {
                    & $Kdiff $Original $Modified $Target -o $Merged                    
                }
                else
                {
                    & $Kdiff $Original $Modified $Target 
                }                                                  
            }
        }
        catch [Exception]
        {
            write-host "Open file failed with the error :`n`n " + $_.Exception
        }
        finally
        {
            # Clean up copied backup file after restore completes successfully
        }
    }
}