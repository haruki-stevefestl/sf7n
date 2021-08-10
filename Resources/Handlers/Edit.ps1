# Enter edit mode
$rows.CSVGrid.Add_BeginningEdit({$rows.Status.Text = 'Editing'})

# Change rows (add/remove)
$rows.CSVGrid.Add_CellEditEnding({$rows.Commit.IsEnabled = $true})
# function Add-Row ($Data, $Action, $At, $Count, $Format, $Header) {
    # $Format and $Header only for $Action == 'InsertLast'

$rows.InsertLast.Add_Click({
    Add-Row $csv 'InsertLast' 0 $context.AppendCount $context.AppendFormat $csvHeader
})

$rows.InsertAbove.Add_Click({
    $At = $csv.IndexOf($rows.CSVGrid.SelectedItem)
    $Count = $rows.CSVGrid.SelectedItems.Count

    if ($Count -gt 0) {Add-Row $csv 'InsertAbove' $At $Count}
})

$rows.InsertBelow.Add_Click({
    $At = $csv.IndexOf($rows.CSVGrid.SelectedItem)
    $Count = $rows.CSVGrid.SelectedItems.Count

    if ($Count -gt 0) {Add-Row $csv 'InsertAbove' ($At+$Count) $Count}
})

$rows.RemoveSelected.Add_Click({
    $rows.CSVGrid.SelectedItems.ForEach{$csv.Remove($_)}
    $rows.CSVGrid.ItemsSource = $csv
    $rows.CSVGrid.Items.Refresh()
})

# Commit CSV
$rows.Commit.Add_Click({
    Export-CustomCSV $csv $context.csvLocation
    $rows.Commit.IsEnabled = $false
})
