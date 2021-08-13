#Requires -Version 3
$startTime = Get-Date

function Write-Log ($Log) {
    $TimeDiff = ((Get-Date)-$startTime).TotalMilliseconds
    Write-Output ("{0,-8:0} {1}" -F $TimeDiff,$Log) | Out-Host
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
Write-Log 'Set  defaults parameters'
$PSDefaultParameterValues = @{'*:Encoding' = 'UTF8'}
$script:baseDir = $PSScriptRoot
Set-Location $baseDir
Get-ChildItem *.ps1 -Recurse | Unblock-File
Add-Type -AssemblyName PresentationFramework

# XAML & GUI
Import-Module .\Functions\XAML.ps1 -Force
$script:rows = New-GUI .\GUI.xaml $config

# Modules
Write-Log 'Load modules'
Get-ChildItem *.ps1 -Recurse -Exclude Rows.ps1 | Import-Module -Force

# Display GUI
# Execution goes to Handlers\Lifecycle.ps1
Write-Log '-------------------------'
[Void] $rows.Rows.ShowDialog()
