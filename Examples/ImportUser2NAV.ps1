#Import NAV admin module for the version of Dynamics NAV you are using 
Import-Module 'C:\Program Files\Microsoft Dynamics NAV\80\Service\NavAdminTool.ps1' 

Set-Location "C:\si-data\Data\"

$NavServerName ="DynamicsNAV80"

$ImportFilePath = "UsersAndRoles.csv"
#$ImportFilePath = "UsersAndRolesDOSFormat.csv"

$list = Import-csv -Path $ImportFilePath -Delimiter ';' -Header sid,username,rolesid,company
$DomainName = "SPILKAD"

foreach ($user in $list) 
{
    #$WindowsUser = Get-WMIObject Win32_UserAccount | Where-Object {$_.FullName -eq $user.username -and $_.Domain -eq $DomainName}
    $WindowsUser = Get-WMIObject Win32_UserAccount | Where-Object {$_.SID -eq $user.sid}
    if([String]::IsNullOrEmpty($WindowsUser.SID))
    {
        $navuser = Get-NAVServerUser -ServerInstance $NavServerName |  where-Object UserName -eq $user.username
    }else
    {
        $navuser = Get-NAVServerUser -ServerInstance $NavServerName |  where-Object WindowsSecurityID -eq $WindowsUser.SID
    }
    
    if([String]::IsNullOrEmpty($navuser.UserName))
    { 
        "New user: " + $user.username
        $navuser = New-NAVServerUser -ServerInstance $NavServerName -WindowsAccount $WindowsUser.Caption -FullName $WindowsUser.FullName -ErrorAction Continue
        #$navuser = New-NAVServerUser -ServerInstance $NavServerName -WindowsAccount $user.username -ErrorAction Continue
    }
    else
    {
        "User '" + $user.username + "' is already registered in NAV"
    }

    $navroleExists = Get-NAVServerPermissionSet -ServerInstance $NavServerName | where-Object PermissionSetID -eq $user.rolesid
    if (!([String]::IsNullOrEmpty($navroleExists)))
    {
        $navrole = Get-NAVServerUserPermissionSet -ServerInstance $NavServerName -WindowsAccount $WindowsUser.Caption
        #New-NAVServerUserPermissionSet -PermissionSetId SUPER -ServerInstance DynamicsNAV80 -WindowsAccount OSOHOTWATER\kf
        #$navrole
        #$user.rolesid
        #$navrole.PermissionSetID 
        if((!($navrole.PermissionSetID -contains $user.rolesid)) -or ([String]::IsNullOrEmpty($navrole)))
        {
            #New-NAVServerUserPermissionSet -ServerInstance $NavServerName -WindowsAccount $user.username -PermissionSetId $user.rolesid -CompanyName $user.company -ErrorAction Continue
            New-NAVServerUserPermissionSet -ServerInstance $NavServerName -WindowsAccount $WindowsUser.Caption -PermissionSetId $user.rolesid -ErrorAction Continue
            "New Role for '" + $user.username + "': " + $user.rolesid + " ; " + $user.company
        }
        else
        {
            "User '" + $user.username + "' already has the role '" + $user.rolesid + "'."
        }
    }
    else
    {
        "Role ID '" + $user.rolesid + "' does not exists."
    }
}

 
