# Enter edit mode
$rows.Grid.Add_BeginningEdit({
    $rows.Status.Text = 'Editing'
    $script:oldRow = $Args[1].Row.Item
})

# Change rows (add/remove)
$rows.Grid.Add_CellEditEnding({
    $Parameters = @{
        UndoStack = $undo
        Data      = $csv
        Operation = 'Change'
        At        = $csv.IndexOf($oldRow)
        OldRow    = $oldRow
        Count     = 1
    }

    [Collections.ArrayList] $script:undo = Add-Undo @Parameters
    $rows.Undo.IsEnabled = $true
    $rows.Commit.IsEnabled = $true
})

$rows.Undo.Add_Click({
    $script:undo, $script:csv = Invoke-Undo $undo $csv
    Update-Grid

    if (!$undo) {$rows.Undo.IsEnabled = $false}
})

# $rows.InsertLast.Add_Click({ Add-Row 'InsertLast'; Update-Grid})
# $rows.InsertAbove.Add_Click({Add-Row 'InsertAbove'; Update-Grid})
# $rows.InsertBelow.Add_Click({Add-Row 'InsertBelow'; Update-Grid})
$rows.InsertLast.Add_Click({
    $csv = Add-Row $csv 'InsertLast' 0 $config.AppendCount $csvHeader $config.AppendFormat
    Update-Grid
})

$rows.InsertAbove.Add_Click({
    $At = $csv.IndexOf($rows.Grid.SelectedItem)
    $Count = $rows.Grid.SelectedItems.Count

    if ($Count -gt 0) {
        $csv = Add-Row $csv 'InsertAbove' $At $Count $csvHeader
        Update-Grid
    }
})

$rows.InsertBelow.Add_Click({
    $At = $csv.IndexOf($rows.Grid.SelectedItem)
    $Count = $rows.Grid.SelectedItems.Count

    if ($Count -gt 0) {
        $csv = Add-Row $csv 'InsertAbove' ($At+$Count) $Count $csvHeader
        Update-Grid
    }
})

$rows.RemoveSelected.Add_Click({
    $rows.Grid.SelectedItems.ForEach({
        # Process undo
        $Parameters = @{
            UndoStack = $undo
            Data      = $csv
            Operation = 'Remove'
            OldRow    = $_
            At        = $csv.IndexOf($_)
            Count     = 1
        }
        [Collections.ArrayList] $script:undo = Add-Undo @Parameters
        $csv.Remove($_)
    })
    Update-Grid
})

# Commit CSV
$rows.Commit.Add_Click({
    Export-CustomCSV $csv $config.csvLocation
    $rows.Commit.IsEnabled = $false
})
