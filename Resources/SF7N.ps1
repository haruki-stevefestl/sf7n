#Requires -Version 3
# Base variables & functions
$script:startTime = Get-Date
$script:baseDir   = $PSScriptRoot
Add-Type -AssemblyName PresentationFramework

function Write-Log ($Log) {
    $TimeDiff = ((Get-Date)-$startTime).TotalMilliseconds
    Write-Output ("{0,-8:0}  {1}" -F $TimeDiff,$Log) | Out-Host
}

function New-Dialog ($Message = '', $Option = 'OK', $Icon = 'Information') {
    return [Windows.MessageBox]::Show($Message, 'SF7N', $Option, $Icon)
}

# Error handling
trap {
    New-Dialog "Error: $_`n`nClick OK to exit" 'OK' 'Error'
    if ($wpf) {$wpf.SF7N.Close()} # IF to prevent error before GUI shows
    exit
}

# Defaults for SF7N
Write-Log 'SF7N 1.6'
Write-Log '-------------------------'
Write-Log 'Set    Defaults Parameters'
$PSDefaultParameterValues = @{'*:Encoding' = 'UTF8'}
Unblock-File $PSScriptRoot\SF7N.ps1
Set-Location $PSScriptRoot\Functions
Unblock-File DataContext.ps1, IO.ps1, Edit.ps1, Initialize.ps1, Search.ps1, XAML.ps1
Set-Location $PSScriptRoot\Handlers
Unblock-File Edit.ps1, Lifecycle.ps1, Search.ps1
Set-Location $PSScriptRoot

# Configurations & DataContext
Import-Module .\Functions\DataContext.ps1 -Force
$script:config  = Import-Configuration .\Configurations\General.ini
$script:context = New-DataContext $config

# XAML & GUI
Import-Module .\Functions\XAML.ps1 -Force
$script:wpf = New-GUI .\GUI.xaml
$wpf.SF7N.DataContext = $context

# GUI Functions
Write-Log 'Import GUI Functions'
foreach ($Module in 'IO','Search','Edit') {
    Write-Log ('  - '+$Module)
    Import-Module .\Functions\$Module.ps1 -Force
}

# Handlers
Write-Log 'Import Handlers'
foreach ($Module in 'Search','Edit','Lifecycle') {
    Write-Log ('  - '+$Module)
    Import-Module .\Handlers\$Module.ps1 -Force
}
Remove-Variable Module

# Display GUI
# Execution goes to Handlers\Lifecycle.ps1
Write-Log '-------------------------'
[Void] $wpf.SF7N.ShowDialog()
