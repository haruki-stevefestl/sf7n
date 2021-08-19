#Requires -Version 3

function Write-Log ($Log) {
    Write-Output ("[$(Get-Date -Format HH:mm:ss.ff)]  $Log") | Out-Host
}

function New-Dialog ($Message = '', $Option = 'OK', $Icon = 'Information') {
    return [Windows.MessageBox]::Show($Message, 'Rows', $Option, $Icon)
}

# Error handling
trap {
    New-Dialog "Error: $_`n`nClick OK to exit" 'OK' 'Error'
    if ($rows) {$rows.Rows.Close()} # IF to prevent error before GUI shows
    exit
}

# Defaults 
Write-Log 'Rows 1.7'
Write-Log 'Set  defaults'
$PSDefaultParameterValues = @{'*:Encoding' = 'UTF8'}
$script:baseDir = $PSScriptRoot
Set-Location $baseDir
Get-ChildItem *.ps1 -Recurse | Unblock-File
Add-Type -AssemblyName PresentationFramework

# XAML & GUI
Import-Module .\Functions\XAML.ps1 -Force
$script:rows = New-GUI .\GUI.xaml

# Modules
Write-Log 'Load modules'
Get-ChildItem *.ps1 -Recurse -Exclude Rows.ps1 | Import-Module -Force

# Display GUI
# Execution goes to Handlers\Lifecycle.ps1
Write-Log '-------------------------'
$rows.Splashscreen.Visibility = 'Visible'
[Void] $rows.Rows.ShowDialog()
