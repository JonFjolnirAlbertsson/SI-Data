function CreateNAVServerInstance
{
    [CmdletBinding()]
    param([string] $User = "", [string] $PaWord = "",
        [string] $NavServiceInstance, [string] $DBServer = "localhost", [string] $DataBase, [string] $DBInstance, 
        [Int] $FirstPortNumber = 8000)
    PROCESS
    {
        try
        { 
            
            $ManagePort = $FirstPortNumber
            $ClientPort = ($FirstPortNumber + 1)
            $ODataPort = ($FirstPortNumber + 2)
            $SOAPPort = ($FirstPortNumber + 3)

            if ($User -eq "")
            {
                New-NAVServerInstance $NavServiceInstance -DatabaseName $DataBase -DatabaseServer $DBServer -ManagementServicesPort $ManagePort -ClientServicesPort $ClientPort -ODataServicesPort $ODataPort -SOAPServicesPort $SOAPPort -Verbose
            }else
            {
                $PWord = ConvertTo-SecureString –String $PaWord –AsPlainText -Force
                $Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $User, $PWord
                Get-Credential -Credential $Credential | New-NAVServerInstance $NavServiceInstance -ServiceAccount User -DatabaseName $DataBase -DatabaseServer $DBServer -DatabaseInstance $DBInstance -ManagementServicesPort $ManagePort -ClientServicesPort $ClientPort -ODataServicesPort $ODataPort -SOAPServicesPort $SOAPPort -Verbose
            }
            

            $NAvInstance = Get-NAVServerInstance $NavServiceInstance | Set-NAVServerInstance -Start -Verbose

            "NAV Server Instance '$NavServiceInstance ' Created."
            $NAvInstance | ft -AutoSize

        }
        catch [Exception]
        {
            "NAV Server Instance '$NavServiceInstance ' Created :`n`n " + $_.Exception
        }
        finally
        {
            # Clean up copied backup file after restore completes successfully
        }
    }
}

