# Work after splashscreen shows
$rows.Rows.Add_ContentRendered({
    # Minimize console
    if ($Host.Name -eq 'ConsoleHost') {
        powershell.exe -Window Minimized '#'
    }

    # Configurations
    $script:config = New-DataContext .\Configurations\General.ini

    # Import CSV and generate columns
    $script:csv, $script:csvHeader, $script:csvAlias =
        Import-CustomCSV $config.csvLocation

    # En/disable InputAlias & OutputAlias button
        if ($csvAlias -isnot [Array]) {$config.HasAlias = 'Collapsed'}
        
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

        # Apply conditional formatting
        if ($Format -is [Array]) {
            $Column.CellStyle = [Windows.Style]::New()
            $i = 0
            while ($Format.$_[$i] -match '^\S+$') {
                $Trigger = [Windows.DataTrigger]::New()
                $Trigger.Binding = $Column.Binding
                $Trigger.Value   = $Format.$_[$i]
                $Trigger.Setters.Add([Windows.Setter]::New(
                    [Windows.Controls.DataGridCell]::BackgroundProperty,
                    [Windows.Media.BrushConverter]::New().ConvertFrom($Format.$_[$i+1])
                ))
                $Column.CellStyle.Triggers.Add($Trigger)
                $i += 2
            }
        }
        $rows.Grid.Columns.Add($Column)
    })


    Write-Log 'Load WinForms'
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing 

    # Finalize UI
    $rows.Rows.DataContext = $config
    Search-CSV '' $csv
    $rows.Splashscreen.Visibility = 'Collapsed'
    [GC]::Collect()
})

# Prompt on exit if unsaved
$rows.Rows.Add_Closing({
    if ($rows.Rows.Title -eq 'Rows  -  Unsaved changes') {
        $Dialog = New-Dialog 'Save changes before exiting?' 'YesNoCancel' 'Question'
        if ($Dialog -eq 'Cancel') {
            $_.Cancel = $true
            return
            
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
