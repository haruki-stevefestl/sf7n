# Work after splashscreen shows
$rows.Rows.Add_ContentRendered({
    # Minimize console
    if ($Host.Name -eq 'ConsoleHost') {
        powershell.exe -Window minimized -Command "#"
    }

    # Import CSV and generate columns
    $script:csv, $script:csvHeader, $script:csvAlias =
        Import-CustomCSV $context.csvLocation
        
    # Generate datagrid columns
    Write-Log 'Add  datagrid columns'
    $rows.CSVGrid.ItemsSource = $null
    $rows.CSVGrid.Columns.Clear()
    
    $Format = '.\Configurations\Formatting.csv'
    if (Test-Path $Format) {$Format = Import-CSV $Format}

    $csvHeader.ForEach({
        $Column = [Windows.Controls.DataGridTextColumn]::New()
        $Column.Binding = [Windows.Data.Binding]::New($_)
        $Column.Header  = $_
        $Column.CellStyle = [Windows.Style]::New()

        # Apply conditional formatting
        $i = 0
        while ($Format.$_[$i] -match '^\S+$') {
            $Trigger = [Windows.DataTrigger]::New()
            $Trigger.Binding = $Column.Binding
            $Trigger.Value   = $Format.$_[$i]
            $Trigger.Setters.Add([Windows.Setter]::New(
                [Windows.Controls.DataGridCell]::BackgroundProperty,
                [Windows.Media.BrushConverter]::New().ConvertFromString($Format.$_[$i+1])
            ))
            $Column.CellStyle.Triggers.Add($Trigger)
            $i += 2
        }

        $rows.CSVGrid.Columns.Add($Column)
    })

    Write-Log 'Load WinForms'
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing 

    Search-CSV $rows.Searchbar.Text $csv
    $rows.TabControl.SelectedIndex = 1
})

# Prompt on exit if unsaved
$rows.Rows.Add_Closing({
    if ($rows.Commit.IsEnabled) {
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

    Remove-Module Config,DataContext,Edit,Column,IO,
        Lifecycle,Search,XAML -Force
})
