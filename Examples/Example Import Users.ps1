#Suggestion: Run each line below one by one and then put them together as needed.
#Install Remote Server Administration Tools (RSAT) first as described above, then import module
Import-Module ActiveDirectory

#Import NAV admin module for the version of Dynamics NAV you are using 
Import-Module 'C:\Program Files\Microsoft Dynamics NAV\71\Service\NavAdminTool.ps1' 

#Specify your Dynamics NAV Service name 
$NavServerName = "NAV71SIData" 
$UsersFileName = "c:\temp\userlist.csv"
#AD filter for use in the next line. If you are not on a large domain, then run the next line (get-aduser) without this filter, or if you use the filter then adjust it to your scenario and domain.
#$Mysearchbase = "DC=<Domain>[,DC=<Corp Domain>,...]" 
$Mysearchbase = "DC=SI-DATA,DC=no" 
#Next we will get AD users. If you want to import only users from a Windows group or a subdomain, you can filter the result set on sub-domain/group/...  Furthermore, we have chosen to retrieve only user name and alias in the example below, but choose any properties that fit your purpose. You can see the entire cmdlet output by running get-help <cmdletname>.Furthermore, we want to save this output into a list that we later can retrieve and modify if needed. The list format and default delimiter might vary depending on regional settings, a semicolon is defined here as a delimiter.
#get-aduser -filter 'samaccountname -like "*jal*"' -searchbase $Mysearchbase | Select-Object -Property Name,SAmaccountname | export-csv "c:\temp\userlist.csv" -notypeinformation  -Delimiter ';' -force  
get-aduser -filter * -searchbase $Mysearchbase | Select-Object -Property SAmaccountname,Name,Enabled | export-csv $UsersFileName -notypeinformation -Encoding Unicode -Delimiter ';' -force  

#Get-ADUser -filter -filter 'Enabled -eq "False"' -searchbase $Mysearchbase 
#Assign the list to a variable 
$myuserlist = Import-csv $UsersFileName -Encoding Unicode -Delimiter ';' -Header username,fullname,roleset 
#Show the list 
$myuserlist 
$UsersFileName2Import = "c:\temp\userlist2Import.csv"
$myuserlist | Select-Object -Property {'SI-Data\'+$($_.username)},fullname,roleset | export-csv $UsersFileName2Import -notypeinformation -Encoding Unicode -Delimiter ';' -force  

#Another way of assigning the output to a variable is using outvariable. Next we want to  then pipe everything to New-NAVServerUser cmdlet to create new users in NAV. In the above example we have only read SamAccountName and User Name from  AD, so to add users as Windows users to NAV, following our Contoso scenario, we need to add the domain name too : DOMAIN\samaccountname. 
#import-csv C:\temp\userlist.csv -Delimiter ';' -OutVariable myuserlist | foreach {New-NAVServerUser -serverinstance $NavServerName -WindowsAccount "SI-Data\$($_.samaccountname)"} 
#import-csv C:\temp\userlist.csv -Delimiter ';' | foreach {"SI-Data\$($_.samaccountname)"} 


#You can combine the above two actions (Reading AD users and then importing them into NAV) into one cmdlet, without saving the output as in the example above.
#We're using a loop here and not the pipeline, as New-NAVServerUser doesn't seem to take the pipeline input 
#get-aduser -filter 'samaccountname -like "*bill*"' -searchbase $Mysearchbase  | foreach { New-NAVServerUser -serverinstance $NavServerName -WindowsAccount "<DOMAIN>$($_.samaccountname)"} 


<#Consider now the following scenario. User wants to get AD users using the export script above, but wants to add roles to this user list, before importing them into NAV. So he will break the above process into 2 steps again - in step 1 he will save AD users into a list, then assuming a modified list with added roles - he will import the list of users and their roles into NAV in step 2.
Step one is then unchanged from the example above (using csv list). Next we will assume that the list is now modified to add roles to users.
Example below shows step 2, where this list is imported to create users and assign permissions in NAV. Userlist2.csv file refered to in the script below is the name of the csv file containing users and permissions. Example below shows format of this file (csv, semicolon delimited) with Contoso users as examples:

 
EUROPE\mrhill;BASIC,RAPIDSTART 
EUROPE\mssaddow;BASIC,COST,CASHFLOW 
EUROPE\joeroberts;SUPER 

If a user or a role defined in this list already exists in NAV, the cmdlet is expected to continue since the ErrorAction parameter is set to Continue (which is also the default value of this parameter). However it is singled out here to direct the attention to error handling opportunities that best fit the user's scenario. Review the possible values of this parameter and how to use them using get-help cmdlet. The following blog is worth checking:
http://blogs.msdn.com/b/powershell/archive/2006/11/03/erroraction-and-errorvariable.aspx
#>

$NavServerName ="nav71sidata"

$list = Import-csv -Path $UsersFileName2Import -Encoding Unicode -Delimiter ';' -Header username,fullname,roleset
foreach ($user in $list) 
{
    $navuser= Get-NAVServerUser -ServerInstance $NavServerName
    #Write-Host $navuser.UserName  $user.username
    if(!($navuser.UserName -contains $user.username))
    { 
        New-NAVServerUser -ServerInstance $NavServerName -WindowsAccount $user.username -FullName $user.fullname -ErrorAction Continue
    }
    else
    {
        Set-NAVServerUser -ServerInstance $NavServerName -WindowsAccount $user.username -FullName $user.fullname -ErrorAction Continue
    }
    #In the csv file used in this example, the list of roles is divided by a comma 
    $roleset=$user.roleset.Split(',')
    foreach ($role in $roleset)
    {
        $navrole=Get-NAVServerUserPermissionSet -ServerInstance $NavServerName -WindowsAccount $user.username
        if(!($navrole.PermissionSetID -contains $role))
        {
            New-NAVServerUserPermissionSet -ServerInstance $NavServerName -WindowsAccount $user.username -PermissionSetId $role -ErrorAction Continue
        }
    }
}

 
