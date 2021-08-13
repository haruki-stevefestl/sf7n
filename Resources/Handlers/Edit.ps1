# Enter edit mode
$rows.Grid.Add_BeginningEdit({$rows.Status.Text = 'Editing'})

# Change rows (add/remove)
$rows.Grid.Add_CellEditEnding({$rows.Commit.IsEnabled = $true})

$rows.InsertLast.Add_Click({
    Add-Row $csv 'InsertLast' 0 $config.AppendCount $config.AppendFormat $csvHeader
})

$rows.InsertAbove.Add_Click({
    $At = $csv.IndexOf($rows.Grid.SelectedItem)
    $Count = $rows.Grid.SelectedItems.Count

    if ($Count -gt 0) {Add-Row $csv 'InsertAbove' $At $Count}
})

$rows.InsertBelow.Add_Click({
    $At = $csv.IndexOf($rows.Grid.SelectedItem)
    $Count = $rows.Grid.SelectedItems.Count

    if ($Count -gt 0) {Add-Row $csv 'InsertAbove' ($At+$Count) $Count}
})

$rows.RemoveSelected.Add_Click({
    $rows.Grid.SelectedItems.ForEach{$csv.Remove($_)}
    $rows.Grid.ItemsSource = $csv
    $rows.Grid.Items.Refresh()
})

# Commit CSV
$rows.Commit.Add_Click({
    Export-CustomCSV $csv $config.csvLocation
    $rows.Commit.IsEnabled = $false
})
