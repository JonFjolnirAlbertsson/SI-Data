<#
.Synopsis
   Runs Notepad++
.DESCRIPTION
   Runs Notepad++
.NOTES
   
.PREREQUISITES
   
#>
function NotepadPlus
{
    [CmdletBinding()]
    param(
        $ArgumentList
        )
    PROCESS
    {
        try
        {       
            $NotepadPlus = Join-Path 'C:\Program Files (x86)\Notepad++' 'notepad++.exe'     
            if($ArgumentList)
            {
                #& $NotepadPlus $ArgumentList
                Start-Process -FilePath $NotepadPlus -ArgumentList $KdiffFileArgs          
            }
            else
            {
                & $NotepadPlus 
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