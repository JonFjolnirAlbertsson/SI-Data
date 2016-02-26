$profile
Test-Path $profile

$Profile.AllUsersAllHosts
$Profile.AllUsersCurrentHost
$Profile.CurrentUserAllHosts
$Profile.CurrentUserCurrentHost

New-Item -path $profile -type file –force
#(notice using –force to overwrite existing profile).

#The above will simply create a blank profile file (script). One can modify the script directly from the file explorer, and or by using

Notepad $profile
