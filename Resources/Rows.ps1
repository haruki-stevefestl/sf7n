#Requires -Version 3
# Base variables & functions
$script:startTime = Get-Date
Add-Type -AssemblyName PresentationFramework

function Write-Log ($Log) {
    $TimeDiff = ((Get-Date)-$startTime).TotalMilliseconds
    Write-Output ("{0,-8:0}  {1}" -F $TimeDiff,$Log) | Out-Host
}

function New-Dialog ($Message = '', $Option = 'OK', $Icon = 'Information') {
    return [Windows.MessageBox]::Show($Message, 'Rows', $Option, $Icon)
}

# Error handling
trap {
    throw $_
    New-Dialog "Error: $_`n`nClick OK to exit" 'OK' 'Error'
    if ($wpf) {$wpf.Rows.Close()} # IF to prevent error before GUI shows
    exit
}

# Defaults for Rows
Write-Log 'Rows 1.7'
Write-Log '-------------------------'
Write-Log 'Set    Defaults Parameters'
$PSDefaultParameterValues = @{'*:Encoding' = 'UTF8'}
$script:baseDir = $PSScriptRoot
Set-Location $baseDir
Get-ChildItem *.ps1 -Recurse | Unblock-File

# Configurations & DataContext
Import-Module .\Functions\DataContext.ps1 -Force
$script:context = New-DataContext .\Configurations\General.ini

# XAML & GUI
Import-Module .\Functions\XAML.ps1 -Force
$script:wpf = New-GUI .\GUI.xaml $context

# GUI Modules
Write-Log 'Import Modules'
foreach ($Module in 'Search','Edit') {
    Import-Module .\Functions\$Module.ps1 -Force
    Import-Module .\Handlers\$Module.ps1 -Force
}
Import-Module .\Functions\IO.ps1 -Force
Import-Module .\Handlers\Lifecycle.ps1 -Force
Remove-Variable Module

# Display GUI
# Execution goes to Handlers\Lifecycle.ps1
Write-Log '-------------------------'
$wpf.TabControl.SelectedIndex = 0
[Void] $wpf.Rows.ShowDialog()
