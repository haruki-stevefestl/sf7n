# Work after splashscreen shows
$rows.Rows.Add_ContentRendered({
    # Minimize console
    if ($Host.Name -eq 'ConsoleHost') {
        powershell.exe -Window Minimized '#'
    }

    # Configurations & DataContext
    $script:config = New-DataContext .\Configurations\General.ini
    $rows.Rows.DataContext = $config

    # Import CSV and generate columns
    $script:csv, $script:csvHeader, $script:csvAlias =
        Import-CustomCSV $config.csvLocation
        
    # Generate datagrid columns
    Write-Log 'Add  datagrid columns'
    $rows.Grid.ItemsSource = $null
    $rows.Grid.Columns.Clear()
    
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

        $rows.Grid.Columns.Add($Column)
    })

    Write-Log 'Load WinForms'
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing 

    Search-CSV '' $csv
    $rows.TabControl.SelectedIndex = 1
    [GC]::Collect()
})

# Prompt on exit if unsaved
$rows.Rows.Add_Closing({
    if ($rows.Commit.IsEnabled) {
        $Dialog = New-Dialog 'Save changes before exiting?' 'YesNoCancel' 'Question'
        if ($Dialog -eq 'Cancel') {
            $_.Cancel = $true
        } elseif ($Dialog -eq 'Yes') {
            Export-CustomCSV $config.csvLocation
        }
    }

    # Cleanup
    Write-Log 'Cleanup'
    $script:undo = $null
    Remove-Variable baseDir,config,rows,undo,
        csvAlias,csvHeader,csv -Scope Script -Force

    Remove-Module DataContext,Edit,IO,Lifecycle,Search,XAML -Force
})
