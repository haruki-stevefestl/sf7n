function Initialize-Columns {
    Write-Log 'Init.  Rows'
    $wpf.TabControl.SelectedIndex = 0

    # Import CSV
    Import-CustomCSV $context.csvLocation
    $wpf.CSVGrid.ItemsSource = $null
    $wpf.CSVGrid.Columns.Clear()
    
    # Generate datagrid columns
    Write-Log 'Add    Datagrid Columns'
    $Format = '.\Configurations\Formatting.csv'
    if (Test-Path $Format) {$Format = Import-CSV $Format}

    $csvHeader.ForEach({
        $Column = [Windows.Controls.DataGridTextColumn]::New()
        $Column.Binding = [Windows.Data.Binding]::New($_)
        $Column.Header  = $_
        $Column.CellStyle = [Windows.Style]::New()

        # Apply conditional formatting
        $i = 0
        while ($Format.$_[$i] -notmatch '^\s*$') {
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

        $wpf.CSVGrid.Columns.Add($Column)
    })
}
