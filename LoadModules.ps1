write-host 'Loading SI-Data modules...'

Write-Progress -Activity 'Loading NAVModules ...' -PercentComplete 50
Import-module (join-path $PSScriptRoot 'NAVModules\NAVModules.psm1') -DisableNameChecking -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
Import-module NAVModules -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

Clear-host
write-host -ForegroundColor Yellow 'Get-Command -Module ''NAVModules*'''
get-command -Module 'NAVModules*'
