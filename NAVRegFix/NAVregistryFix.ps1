#NAV 2013 and NAV 2013 R2 side-by-side install registry correction
#---------Installation steps----------------
# 1. Install NAv 2013, Install NAV 2013 R2 – this is not required if it is already done
#     if there is installed NAV 2013 R2 only then this script just fix registry for 71
# 2. Apply latest hotfixes (NAV 2013 R2 required later KB 2907588 build more 35850)
# 3.run powershell as administor and execute "set-executionpolicy unrestricted"
# 4. run this script
#-------------------------------------------
Set-ExecutionPolicy RemoteSigned -Force
if ( [System.IntPtr]::Size -eq 4 ) 
   { 
     "32-bits"
     try 
       {
         
        $nav70 = Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft Dynamics NAV\70\RoleTailored Client" -ErrorAction SilentlyContinue
		$nav70exist = ($nav70.Path.Length -gt 0) 
        $nav71 = Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft Dynamics NAV\71\RoleTailored Client" -ErrorAction SilentlyContinue
		$nav71exist = ($nav71.Path.Length -gt 0)
        $nav90 = Get-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Microsoft Dynamics NAV\90\RoleTailored Client" -ErrorAction SilentlyContinue
		$nav90exist = ($nav90.Path.Length -gt 0)
        if ( $nav71exist)
          {
           

           New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
           #Remove
           Remove-Item -Path "HKCR:\TypeLib\{5020AC1E-A4F0-402B-A920-3FED4E3B05CC}" -Recurse -ErrorAction SilentlyContinue
           Remove-Item -Path "HKCR:\Wow6432Node\TypeLib\{5020AC1E-A4F0-402B-A920-3FED4E3B05CC}" -Recurse -ErrorAction SilentlyContinue
           Remove-Item -Path "HKCR:\Interface\{14519985-4959-4F7C-AC30-CBBCD9DFBC08}" -Recurse -ErrorAction SilentlyContinue
           Remove-Item -Path "HKCR:\Wow6432Node\Interface\{14519985-4959-4F7C-AC30-CBBCD9DFBC08}" -Recurse -ErrorAction SilentlyContinue
           remove-Item -Path "HKCR:\Interface\{59521B62-D441-47E6-8224-A07203686BA2}" -Recurse -ErrorAction SilentlyContinue
           Remove-Item -Path "HKCR:\Wow6432Node\Interface\{59521B62-D441-47E6-8224-A07203686BA2}" -Recurse -ErrorAction SilentlyContinue
           
           
           #Create again



           $net = Get-ChildItem C:\Windows\Microsoft.NET\ regasm.exe -Recurse | Select-Object -ExpandProperty FullName | Where-Object { $_ -like "*v4*"}
           If ($net -is [Array])
              {
                if ($nav70exist) 
				    { $exe70 = $net[0]+ ' /register ' + '"' + $nav70.Path +'Microsoft.Dynamics.Nav.Client.WinForms.dll" /tlb' }
                $exe71 = $net[0]+ ' /register ' + '"' + $nav71.Path +'Microsoft.Dynamics.Nav.Client.WinForms.dll" /tlb'
                $exe90 = $net[0]+ ' /register ' + '"' + $nav90.Path +'Microsoft.Dynamics.Nav.Client.WinForms.dll" /tlb'
              }
           else 
              {
                if ($nav70exist) 
				   { $exe70 = $net+ ' /register ' + '"' + $nav70.Path +'Microsoft.Dynamics.Nav.Client.WinForms.dll" /tlb' }
                $exe71 = $net+ ' /register ' + '"' + $nav71.Path +'Microsoft.Dynamics.Nav.Client.WinForms.dll" /tlb' 
                $exe90 = $net+ ' /register ' + '"' + $nav90.Path +'Microsoft.Dynamics.Nav.Client.WinForms.dll" /tlb' 
              }
              
           if ($nav70exist) 
		      { Invoke-Expression $exe70 }
           Invoke-Expression $exe71  
           Invoke-Expression $exe90

          }
         else
           {
           Write-warning "Didn't find 2013 R2 in registry for 32-bit systems - NAV might be installed incorrectly" "Please reinstall products"
           } 

                    
        } 
        catch 
        {
          Write-Warning "Had error in checking registry in 32 bits loop NAV might be installed incorrectly"
        }
      
     
   } 
   elseif ( ([System.IntPtr]::Size -eq 8) )
   { 
    "64-bits"
     try 
       {
        $nav70 = Get-ItemProperty -path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft Dynamics NAV\70\RoleTailored Client" -ErrorAction SilentlyContinue
		$nav70exist = ($nav70.Path.Length -gt 0) 
        $nav71 = Get-ItemProperty -path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft Dynamics NAV\71\RoleTailored Client" -ErrorAction SilentlyContinue
		$nav71exist = ($nav71.Path.Length -gt 0) 
        $nav90 = Get-ItemProperty -path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft Dynamics NAV\90\RoleTailored Client" -ErrorAction SilentlyContinue
		$nav90exist = ($nav90.Path.Length -gt 0) 
        if ($nav71exist)
		{
           # Processing registry correction on 64-bits
           New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
           #Remove
           Remove-Item -Path "HKCR:\TypeLib\{5020AC1E-A4F0-402B-A920-3FED4E3B05CC}" -Recurse -ErrorAction SilentlyContinue
           Remove-Item -Path "HKCR:\Wow6432Node\TypeLib\{5020AC1E-A4F0-402B-A920-3FED4E3B05CC}" -Recurse -ErrorAction SilentlyContinue
           Remove-Item -Path "HKCR:\Interface\{14519985-4959-4F7C-AC30-CBBCD9DFBC08}" -Recurse -ErrorAction SilentlyContinue
           Remove-Item -Path "HKCR:\Wow6432Node\Interface\{14519985-4959-4F7C-AC30-CBBCD9DFBC08}" -Recurse -ErrorAction SilentlyContinue
           remove-Item -Path "HKCR:\Interface\{59521B62-D441-47E6-8224-A07203686BA2}" -Recurse -ErrorAction SilentlyContinue
           Remove-Item -Path "HKCR:\Wow6432Node\Interface\{59521B62-D441-47E6-8224-A07203686BA2}" -Recurse -ErrorAction SilentlyContinue
           

           $net = Get-ChildItem C:\Windows\Microsoft.NET\ regasm.exe -Recurse | Select-Object -ExpandProperty FullName | Where-Object { $_ -like "*v4*"}
           If ($net -is [Array])
              {
                 if ($nav70exist) 
				    { $exe70 = $net[0]+ ' /register ' + '"' + $nav70.Path +'Microsoft.Dynamics.Nav.Client.WinForms.dll" /tlb' }
                 $exe71 = $net[0]+ ' /register ' + '"' + $nav71.Path +'Microsoft.Dynamics.Nav.Client.WinForms.dll" /tlb'
                 $exe90 = $net[0]+ ' /register ' + '"' + $nav90.Path +'Microsoft.Dynamics.Nav.Client.WinForms.dll" /tlb'
              }
           else 
              {
                if ($nav70exist) 
				   { $exe70 = $net+ ' /register ' + '"' + $nav70.Path +'Microsoft.Dynamics.Nav.Client.WinForms.dll" /tlb' }
                $exe71 = $net+ ' /register ' + '"' + $nav71.Path +'Microsoft.Dynamics.Nav.Client.WinForms.dll" /tlb' 
                $exe90 = $net+ ' /register ' + '"' + $nav90.Path +'Microsoft.Dynamics.Nav.Client.WinForms.dll" /tlb' 
              }
              
           if ($nav70exist) 
		      { Invoke-Expression $exe70 }
           Invoke-Expression $exe71  
           Invoke-Expression $exe90 
               
           } 
         else 
           {
           Write-Warning "Didn't find 2013 R2 in registry for 64-bit systems - NAV might be installed incorrectly" "Please reinstall products"
           }  
          } 
        catch 
        {
          Write-Warning "Had error in checking registry in 64 bits loop NAV might be installed incorrectly"
       
         }
     
     
   } 
 
