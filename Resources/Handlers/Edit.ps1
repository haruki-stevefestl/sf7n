# Enter edit mode
$wpf.CSVGrid.Add_BeginningEdit({
    $wpf.Status.Text = 'Editing'
    if ($wpf.Mode.SelectedIndex -eq 0) {
        $wpf.Mode.SelectedIndex = 1
    }
})

# Change rows (add/remove)
$wpf.CSVGrid.Add_CellEditEnding({$wpf.Commit.IsEnabled = $true})
$wpf.InsertLast.Add_Click({ Add-Row 'InsertLast'})
$wpf.InsertAbove.Add_Click({Add-Row 'InsertAbove'})
$wpf.InsertBelow.Add_Click({Add-Row 'InsertBelow'})
$wpf.RemoveSelected.Add_Click({
    $wpf.CSVGrid.SelectedItems.ForEach{$csv.Remove($_)}
    $wpf.CSVGrid.ItemsSource = $csv
    $wpf.CSVGrid.Items.Refresh()
    $wpf.Commit.IsEnabled = [Boolean] $csv # Disable commit button if $csv is empty
})

# Commit CSV
$wpf.Commit.Add_Click({
    Export-CustomCSV $context.csvLocation
    Import-CustomCSV $context.csvLocation
    Search-CSV $wpf.Searchbar.Text $csv
})
