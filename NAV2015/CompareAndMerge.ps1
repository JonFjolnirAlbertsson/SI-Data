# Comparing and merging

#OSO
$CompanyFolderName = "OSO"
$CompanyOriginalFileName = "2009SP1NO_6_0_30609_AllObjects.txt"
$CompanyModifiedFileName = "2009SP1NO_6_0_36259_OSO_AllObjects.txt"
$CompanyTargetFileName = "2015_CU1_NO_AllObjects.txt"
<#
#SI-Data
$CompanyFolderName = "SI-Data"
#$CompanyFolderName = "SI-Data\NAV 2009 R2"
$CompanyOriginalFileName = "37_B_NO_AllObjects.txt"
$CompanyModifiedFileName = "SI-Data All Objects.txt"
$CompanyTargetFileName = "2013_R2_CU11_NO_AllObjects.txt"
#$CompanyTargetFileName = "2009R2NO_6_00_32012_AllObjects.txt"
#>
<#
#Øveraasen
$CompanyFolderName = "Øveraasen"
$CompanyOriginalFileName = "2009SP1NO_6_0_30609_AllObjects.txt"
$CompanyModifiedFileName = "PS59933_NO Electronic Invoices.txt"
$CompanyTargetFileName = "Øveraasen All objects.txt"
#>

# Set the right folder path based on company folder and files name
$RootFolderPath = "C:\NavUpgrade\"
$SourceOriginal = $RootFolderPath + $CompanyFolderName + "\" + $CompanyOriginalFileName
$SourceModified = $RootFolderPath + $CompanyFolderName + "\" + $CompanyModifiedFileName
$SourceTarget = $RootFolderPath + $CompanyFolderName + "\" + $CompanyTargetFileName

$DestinationOriginal = $RootFolderPath + $CompanyFolderName + "\Original\"
$DestinationModified = $RootFolderPath + $CompanyFolderName + "\Modified\"
$DestinationTarget = $RootFolderPath + $CompanyFolderName + "\Target\"

$Delta = $RootFolderPath + $CompanyFolderName + "\Delta\"
$Result = $RootFolderPath + $CompanyFolderName + "\Result\"
#$Merged = $RootFolderPath + $CompanyFolderName + "\Merged\Ready2Import\"
$Merged = $RootFolderPath + $CompanyFolderName + "\Merged\"

# Set file name to merge or files (*.TXT)
#$CompareObject = "TAB1500000*.TXT"
#$UpdateObject = "TAB18.DELTA"
$CompareObject = "PAG*.TXT"

#Set Source, modified, target and result values
$OriginalCompareObject = $DestinationOriginal + $CompareObject
$ModifiedCompareObject = $DestinationModified + $CompareObject
$TargetCompareObject = $DestinationTarget + $CompareObject
$DeltaUpdateObject = $Delta + $UpdateObject
$JoinSource = $Merged + $CompareObject
$JoinDestination = $Merged + "all-merged-objects.txt"

#Uprade process action
#$UpgradeAction = "Split"
$UpgradeAction = "Merge"
#$UpgradeAction = "Join"


$Version = '8.0*'
if(([string]::Equals($Version, "7.1")) -or ($Version -eq "71")-or ($Version -eq "7.1*"))
{
    Import-Module "C:\Users\jal\Documents\NAV\Script\StartingISENAV71.ps1"  
}
if(([string]::Equals($Version, "8.0")) -or ($Version -eq "80")-or ($Version -like '8.0*'))
{
    Import-Module "C:\Users\jal\Documents\NAV\Script\StartingISENAV80.ps1" 
}    

# Split text files with many objects
If($UpgradeAction -eq "Split")
{
    Split-NAVApplicationObjectFile  -Source $SourceOriginal -Destination $DestinationOriginal -PreserveFormatting -Force
    Split-NAVApplicationObjectFile  -Source $SourceModified -Destination $DestinationModified -PreserveFormatting -Force
    Split-NAVApplicationObjectFile  -Source $SourceTarget -Destination $DestinationTarget -PreserveFormatting -Force
    
    echo "The source file $SourceOriginal has been split to the destination $DestinationOriginal"
    echo "The source file $SourceModified has been split to the destination $DestinationModified"
    echo "The source file $SourceTarget has been split to the destination $DestinationModified"
}
ElseIf($UpgradeAction -eq "Merge")
{
# This merge command has been run.
# If the MergedTool has also been runned and updated the merge. The new files are in the "Merged" folder. 
    #Merge-NAVApplicationObject -Original $OriginalCompareObject -Modified $ModifiedCompareObject -Target $TargetCompareObject -Result $Result -Force -Verbose -ErrorAction Inquire
    Merge-NAVApplicationObject -Modified $ModifiedCompareObject -Original $OriginalCompareObject -Result $Result -Target $TargetCompareObject -DateTimeProperty FromTarget -DocumentationConflict TargetFirst -Force -ModifiedProperty FromModified -VersionListProperty FromTarget
    
    echo "The filter used to merge files was $CompareObject"
    echo "Below you can see were the source files come from.."
    echo $OriginalCompareObject
    echo $ModifiedCompareObject
    echo $TargetCompareObject
    echo "The merged files are found in the folder $Result."

    echo "Remember.."
    echo "After the script has run the result files should be compared." 
    echo "The result files should be compared to the Modified file and the target file."

}
ElseIf($UpgradeAction -eq "Join")
{
    Join-NAVApplicationObjectFile -Source $JoinSource -Destination $JoinDestination

    echo "The filter used to join files was $CompareObject"
    echo "The join files come from the $JoinSource"
    echo "The join files are in the file $JoinDestination"
}
echo "Execution finished."