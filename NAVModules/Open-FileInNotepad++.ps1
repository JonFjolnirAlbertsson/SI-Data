<#
.Synopsis
   Open Target, Original,Result and Merged File in Notepad++
.DESCRIPTION
   Open Target, Original,Result and Merged File in Notepad++
.NOTES
   
.PREREQUISITES
   
#>
function Open-FileInNotepad++
{
    [CmdletBinding()]
    param(
        [string] $WorkingFolderPath, 
        [string] $ObjectName,
        [Switch] $OpenOriginal,
        [Switch] $OpenModified,
        [Switch] $OpenTarget,
        [Switch] $OpenMerged,
        [Switch] $OpenResult
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
            $Result = "$WorkingFolderPath\Result\TAB\$ObjectName.TXT"

            if($OpenOriginal) 
            {
                $FileArgs = $Original
            }
            if($OpenModified) 
            {
                if($FileArgs)
                {
                    $FileArgs = $FileArgs, $Modified
                }
                else
                {
                    $FileArgs = $Modified
                }
            }
            if($OpenTarget) 
            {
                if($FileArgs)
                {
                    $FileArgs = $FileArgs, $Target
                }
                else
                {
                    $FileArgs = $Target
                }
            }
            if($OpenMerged) 
            {
                if($FileArgs)
                {
                    $FileArgs = $FileArgs, $Merged
                }
                else
                {
                    $FileArgs = $Merged
                }
            }
            if($OpenResult) 
            {
                if($FileArgs)
                {
                    $FileArgs = $FileArgs, $Result
                }
                else
                {
                    $FileArgs = $Result
                }
            }
            &$NotepadPlus $FileArgs                     
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