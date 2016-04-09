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
        [string] $WorkingFolder, 
        [string] $ObjectName,
        [Switch] $OpenOriginal,
        [Switch] $OpenModified,
        [Switch] $OpenTarget,
        [Switch] $OpenMerged,
        [Switch] $OpenResult,
        [Switch] $OpenToBeJoined,
        [Switch] $OpenInNotepadPlus,
        [Switch] $OpenInKdiff,
        [Switch] $OpenToMergeInKdiff
        )
    PROCESS
    {
        try
        {       
            [String] $Original = join-path $WorkingFolder "\Original\$ObjectName.TXT"
            [String] $Modified = join-path $WorkingFolder "\Modified\$ObjectName.TXT"
            [String] $Target = join-path $WorkingFolder "\Target\$ObjectName.TXT"
            [String] $Merged = join-path $WorkingFolder "\Merged\$ObjectName.TXT"
            [String] $ToBeJoined = join-path $WorkingFolder "\Merged\ToBeJoined\$ObjectName.TXT"
            [String] $Result = join-path $WorkingFolder "\Result\TAB\$ObjectName.TXT"

            [String] $FileArgs = "";
            [String] $KdiffFileArgs = '';

            if($OpenOriginal) 
            {
                if((Test-Path -Path $Original))
                {
                    $FileArgs = $Original
                    $KdiffFileArgs = join-path $WorkingFolder "\Original\$ObjectName.TXT"
                 }
            }
            if($OpenModified) 
            {
                if((Test-Path -Path $Modified))
                {
                    if([String]::IsNullOrEmpty($FileArgs))
                    {
                        $FileArgs = $Modified
                        $KdiffFileArgs =  (join-path $WorkingFolder "\Modified\$ObjectName.TXT")          
                    }
                    else
                    {           
                        $KdiffFileArgs =  $KdiffFileArgs + ' ' + (join-path $WorkingFolder "\Modified\$ObjectName.TXT")
                        $FileArgs = $FileArgs, $Modified
                    }
                }
            }
            if($OpenTarget) 
            {
                if((Test-Path -Path $Target))
                {
                    if([String]::IsNullOrEmpty($FileArgs))
                    {
                        $FileArgs = $Target
                        $KdiffFileArgs =  (join-path $WorkingFolder "\Target\$ObjectName.TXT")
                    }
                    else
                    {
                        $FileArgs = $FileArgs, $Target
                        $KdiffFileArgs =  $KdiffFileArgs + ' ' + (join-path $WorkingFolder "\Target\$ObjectName.TXT")
                    }
                }
            }
            if($OpenMerged) 
            {
                if((Test-Path -Path $Merged))
                {
                    if([String]::IsNullOrEmpty($FileArgs))
                    {
                        $FileArgs = $Merged
                        $KdiffFileArgs =  (join-path $WorkingFolder "\Merged\$ObjectName.TXT")
                    }
                    else
                    {
                        $FileArgs = $FileArgs, $Merged
                        # If merging we will not include this file
                        if(!$OpenToMergeInKdiff)
                        {
                            $KdiffFileArgs =  $KdiffFileArgs + ' ' + (join-path $WorkingFolder "\Merged\$ObjectName.TXT")
                        }         
                    }
                }
            }
            if($OpenResult) 
            {
                if((Test-Path -Path $Result))
                {
                    if([String]::IsNullOrEmpty($FileArgs))
                    {
                        $FileArgs = $Result
                        $KdiffFileArgs =  (join-path $WorkingFolder "\Result\$ObjectName.TXT")
                    }
                    else
                    {
                        $FileArgs = $FileArgs, $Result
                        $KdiffFileArgs =  $KdiffFileArgs + ' ' + (join-path $WorkingFolder "\Result\$ObjectName.TXT")
                    }
                }
            }

            if($OpenToBeJoined) 
            {
                if([String]::IsNullOrEmpty($FileArgs))
                {
                    $FileArgs = $ToBeJoined
                    $KdiffFileArgs =  (join-path $WorkingFolder "\Merged\ToBeJoined\$ObjectName.TXT")
                }
                else
                {
                    $FileArgs = $FileArgs, $ToBeJoined
                    $KdiffFileArgs =  $KdiffFileArgs + ' ' + (join-path $WorkingFolder "\Merged\ToBeJoined\$ObjectName.TXT")
                }
            }

            if($OpenInNotepadPlus)
            { 
                NotepadPlus -ArgumentList $FileArgs      
            }

            if($OpenInKdiff -or $OpenToMergeInKdiff)
            {
                if($OpenToMergeInKdiff)
                { 
                    $KdiffFileArgs =  $KdiffFileArgs + ' -o ' + $Merged 
                    Kdiff -ArgumentList $KdiffFileArgs                    
                }
                else
                {
                    Kdiff -ArgumentList $KdiffFileArgs 
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