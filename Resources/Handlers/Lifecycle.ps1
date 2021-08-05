# Work after splashscreen shows
$wpf.Rows.Add_ContentRendered({
    # Minimize console
    if ($Host.Name -eq 'ConsoleHost') {
        powershell.exe -Window minimized -Command "#"
    }

    # Import CSV and generate columns
    Import-Module .\Functions\Initialize.ps1 -Force
    Initialize-Rows

    Write-Log 'Import WinForms'
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing 

    Search-CSV $wpf.Searchbar.Text $csv
})

# Prompt on exit if unsaved
$wpf.Rows.Add_Closing({
    if ($wpf.Commit.IsEnabled) {
        $Dialog = New-Dialog 'Save changes before exiting?' 'YesNoCancel' 'Question'
        if ($Dialog -eq 'Cancel') {
            $_.Cancel = $true
        } elseif ($Dialog -eq 'Yes') {
            Export-CustomCSV $context.csvLocation
        }
    }

    # Cleanup
    Write-Log 'Cleanup'
    Remove-Variable baseDir,context,wpf,startTime,
        csvAlias,csvHeader,csv -Scope Script -Force

    Remove-Module Config,DataContext,Edit,Initialize,IO,
        Lifecycle,Search,XAML -Force
})
