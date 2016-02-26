# Delete files from result that do not exist in Target
Clear-Host
$CompareObject = "TAB*.TXT"
$ComparingStr = "???[0-9][0-9][0-9].TXT"
$ComparingStr = "*.TXT"
$ComparingStr = "???[0-9][0-9][0-9][0-9][0-9].TXT"
#$ComparingStr = "TAB[0-9].TXT"
#$ComparingStr = "TAB[1..9999].TXT"
$ComparingStr = "TAB[0-9]..[49999].TXT"
$ComparingStr = '[A-Z][A-Z][A-Z](\d+)\.TXT'
$range = 1..9999
#get-childitem From*.rar | 
#where {$range -contains ($_.name -replace 'From(\d+)\.rar','$1')} 
$CompOriginal = Get-ChildItem -Recurse -path "C:\Temp\PSCompare\Original\" | where-object {$_.Name -like $CompareObject -and $range -contains ($_.name -replace $ComparingStr,'$1')}
$CompTarget = Get-ChildItem -Recurse -path "C:\Temp\PSCompare\Target\" | where {$range -contains ($_.name -replace $ComparingStr,'$1')} 
#$results = @(Compare-Object  -casesensitive -ReferenceObject $CompOriginal -DifferenceObject $CompTarget)
$ResultPath = "C:\Temp\PSCompare\Result\"

# Define the name property to compare by.
$results = @(Compare-Object  -casesensitive -ReferenceObject $CompOriginal -DifferenceObject $CompTarget -property name -passThru)
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
                #remove-item -path $RemovePath -force
        }else {
            $MessageStr = "The file $RemovePath, with the SideIndicator " + $result.SideIndicator + " does not exists."
        }                                          
    #}
    Write-Host $MessageStr + "  -  " + $i
    #Write-Progress -activity $MessageStr -status "Percent added: " -PercentComplete (($i / $results.Length)  * 100)

    $a = (Get-Host).PrivateData
                    
}